"""Exercise the installed doctor's command boundary with simulated OS commands."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time
import unittest

SCRIPT = Path(__file__).resolve().parents[2] / 'modules/system-services/network-namespaces/doctor.py'


class DoctorTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.runtime = self.root / 'runtime'
        self.runtime.mkdir()
        self.state = self.root / 'state'
        self.state.mkdir()
        self.key = self.root / 'key'
        self.key.write_text('fixture-private-value-never-report')
        self.seed = self.root / 'seed'
        self.seed.write_text('fixture-bootstrap-never-report')
        self.config = dict(name='vpn', role='gateway', host='test-server',
                           runtime=str(self.runtime), state=str(self.state), namespace_path=str(self.root/'netns'),
                           key=str(self.key), bootstrap=str(self.seed),
                           token=str(self.key), endpoint='192.0.2.11',
                           peers=['expected-peer'], urls=['https://one.test/', 'https://two.test/'])
        (self.root/'netns').touch()
        self.config['dependencies'] = {'netns-vpn.service': [], 'netns-vpn-shared.service': ['netns-vpn.service'],
                                       'hide-me-vpn.service': ['netns-vpn.service'],
                                       'netns-vpn-underlay.service': ['netns-vpn.service'],
                                       'netns-vpn-dns.service': ['netns-vpn.service', 'netns-vpn-shared.service']}
        self.scenario = dict(reason='healthy', log='', active='active', probes=[0, 0, 0, 0])
        stub = self.root / 'stub'
        stub.write_text('''#!PYTHON_EXECUTABLE
import json, os, sys, time
from pathlib import Path
root = Path(os.environ['VPN_TEST_ROOT'])
s = json.loads((root/'scenario').read_text())
cmd = Path(sys.argv[0]).name
args = sys.argv[1:]
with (root/'calls').open('a') as f: f.write(json.dumps([cmd]+args)+'\\n')
reason = s.get('reason')
if cmd == 'systemctl':
    if args[0] == 'show':
        unit = args[1]
        load = 'not-found' if reason == 'missing-unit' else 'masked' if reason == 'masked' else 'loaded'
        active = s.get('active', 'active')
        if reason == 'crashed' and unit == 'hide-me-vpn.service': active = 'failed'
        if unit == 'hide-me-vpn.service' and (root/'provider-stopped').exists(): active = 'inactive'
        props = s.get('units', {}).get(unit, {})
        active = props.get('active', active)
        load = props.get('load', load)
        condition = props.get('condition', 'yes')
        started = props.get('started', '1')
        invocation = (root/'invocation').read_text() if (root/'invocation').exists() and unit == 'hide-me-vpn.service' else props.get('invocation', 'test-invocation')
        job = props.get('job', '0')
        print(f'LoadState={load}\\nActiveState={active}\\nUnitFileState=enabled\\nResult=success\\nActiveEnterTimestampMonotonic=1\\nExecMainStartTimestampMonotonic={started}\\nConditionResult={condition}\\nInvocationID={invocation}\\nJob={job}')
    elif args[0] == 'stop' and 'hide-me-vpn.service' in args:
        (root/'provider-stopped').touch()
    elif args[0] in ('restart', 'start') and 'hide-me-vpn.service' in args:
        if s.get('interrupt_repair'):
            import signal
            os.kill(os.getppid(), signal.SIGKILL)
        (root/'provider-stopped').unlink(missing_ok=True)
        (root/'invocation').write_text('new-invocation')
    elif args[:2] == ['start', 'netns-vpn-health.service']:
        if s.get('restart_during_probe'): (root/'invocation').write_text('new-invocation')
        (root/'runtime'/'probes.json').write_text(json.dumps({'checked_at':int(time.time()), 'results':s['probes']}))
        if 0 in s['probes'][:2]:
            (root/'runtime'/'ready').write_text(str(int(time.time())))
    sys.exit(0)
if cmd == 'tailscale':
    if args[0] == 'status': print(json.dumps({'BackendState':'NeedsLogin' if reason == 'tailscale' else 'Running'}))
    sys.exit(1 if reason == 'peer' and args[0] == 'ping' else 0)
if cmd == 'journalctl':
    scope = next((x.split('=',1)[1] for x in args if x.startswith('_SYSTEMD_INVOCATION_ID=')), '')
    print(s.get('logs', {}).get(scope, s.get('log','') if scope == 'test-invocation' else ''))
    sys.exit(0)
if cmd == 'curl':
    if '--silent' in args:
        index = (2 if '-6' in args else 0) + (1 if args[-1] == 'https://two.test/' else 0)
        sys.exit(s['probes'][index])
    family = 'ipv6' if '-6' in args else 'ipv4'
    sys.exit(s.get('host_probes', {}).get(family, 7 if reason == 'offline' else 0))
if cmd == 'ip':
    if '-j' in args:
        family = 'ipv6' if '-6' in args else 'ipv4'
        if 'route' in args:
            print(json.dumps([{'dev':'eth0'}] if s.get('host_routes', {}).get(family, True) else []))
        else: print(json.dumps([{'flags':['UP'], 'operstate':'UP'}]))
        sys.exit(0)
    if 'dig' in args: print('192.0.2.1'); sys.exit(1 if reason == 'dns-relay' else 0)
    if 'nft' in args:
        print('chain output { policy drop; } chain input { policy drop; } chain forward { policy drop; } oifname "shared0" accept; oifname "hm0" accept; iifname "shared0" oifname "hm0" accept; masquerade')
        sys.exit(1 if reason == 'firewall' else 0)
    if 'wg' in args:
        if args[-1] == 'peers': print('wrong-peer' if reason == 'wrong-peer' else 'expected-peer')
        else: print('expected-peer\\t'+str(0 if reason == 'handshake' else int(time.time())))
    if 'route' in args: print('default via 10.0.2.2 dev tap0' if 'main' in args else 'default dev '+('shared0' if s.get('client') else 'hm0'))
    if 'link' in args and reason == 'underlay' and 'tap0' in args: sys.exit(1)
    if 'link' in args and reason == 'missing-link' and 'hm0' in args: sys.exit(1)
    if 'link' in args and reason == 'missing-shared' and 'shared0' in args: sys.exit(1)
    if 'sysctl' in args: print('1\\n1')
    sys.exit(0)
sys.exit(0)
'''.replace('PYTHON_EXECUTABLE', sys.executable))
        stub.chmod(0o755)
        for name in ['systemctl', 'tailscale', 'journalctl', 'curl', 'ip']:
            (self.root / name).symlink_to(stub)
        self.env = dict(os.environ, PATH=str(self.root) + ':' + os.environ['PATH'], VPN_TEST_ROOT=str(self.root))
        (self.runtime / 'resolv.conf').write_text('nameserver 10.0.0.1\n')

    def run_doctor(self, mode='reconcile', expected=0, args=()):
        (self.root / 'config').write_text(json.dumps(self.config))
        (self.root / 'scenario').write_text(json.dumps(self.scenario))
        result = subprocess.run([sys.executable, '-c', 'import os,runpy,sys; os.geteuid=lambda:0; sys.argv=sys.argv[1:]; runpy.run_path(sys.argv[0],run_name="__main__")', str(SCRIPT), str(self.root/'config'), mode, *args],
                                env=self.env, text=True, capture_output=True)
        self.assertEqual(result.returncode, expected, result.stderr)
        self.assertNotIn('fixture-', result.stdout + result.stderr)
        if mode == 'reconcile':
            return json.loads((self.state / 'status.json').read_text())
        return result.stdout

    def repairs(self):
        if not (self.root/'calls').exists(): return []
        return [x for x in map(json.loads, (self.root/'calls').read_text().splitlines())
                if x[0] == 'systemctl' and (x[1] in ('restart', 'stop') or (x[1] == 'start' and x[2] != 'netns-vpn-health.service'))]

    def test_active_provider_http_401_requires_action_without_expiry_claim(self):
        self.scenario.update(probes=[6, 6, 6, 6], log='Rest: [ERR] Bad HTTP response ( 401 )\nSECRET bearer fixture-private-value-never-report')
        for _ in range(4): status = self.run_doctor()
        self.assertEqual(status['reason'], 'AUTH_REJECTED')
        self.assertEqual((self.state/'hold.json').stat().st_mode & 0o777, 0o600)
        self.assertEqual(status['phase'], 'ACTION_REQUIRED')
        self.assertIn('exact cause unknown', status['message'])
        self.assertNotIn('expired', status['message'])
        self.assertEqual(self.repairs(), [['systemctl', 'stop', 'hide-me-vpn.service']])
        self.assertIn('AUTH_REJECTED', self.run_doctor('status'))

    def prime(self):
        self.run_doctor()
        status = json.loads((self.state/'status.json').read_text())
        status['grace_until'] = 0
        (self.state/'status.json').write_text(json.dumps(status))

    def test_single_endpoint_and_ipv6_failure_never_restart(self):
        self.scenario['probes'] = [0, 7, 7, 7]
        self.assertEqual(self.run_doctor()['reason'], 'EGRESS_DEGRADED')
        self.assertEqual(self.repairs(), [])

    def test_missing_deployment_and_intentional_stop_are_not_repaired(self):
        for reason, active, expected in [('missing-unit', 'active', 'DEPLOYMENT_MISMATCH'),
                                         ('masked', 'active', 'DISABLED'),
                                         ('healthy', 'inactive', 'STOP_INTENT_UNKNOWN')]:
            with self.subTest(reason=reason):
                self.scenario.update(reason=reason, active=active)
                self.assertEqual(self.run_doctor()['reason'], expected)
        self.assertEqual(self.repairs(), [])

    def test_prerequisite_outages_wait_and_resume_without_restarts(self):
        self.config['role'] = 'client'
        self.scenario['client'] = True
        for reason, expected in [('offline', 'HOST_CONNECTIVITY_UNVERIFIED'), ('tailscale', 'TAILSCALE_OFFLINE'),
                                  ('peer', 'GATEWAY_UNREACHABLE')]:
            self.scenario['reason'] = reason
            for _ in range(3):
                self.assertEqual(self.run_doctor()['reason'], expected)
        self.scenario['reason'] = 'healthy'
        self.assertEqual(self.run_doctor()['reason'], 'HEALTHY')
        self.assertEqual(self.repairs(), [])

    def test_stuck_provider_debounce_backoff_budget_and_verified_recovery(self):
        self.prime()
        self.scenario.update(reason='missing-link', probes=[7, 7, 7, 7])
        self.assertEqual(self.run_doctor()['attempts'], 0)
        self.assertEqual(self.run_doctor()['attempts'], 0)
        status = self.run_doctor()
        self.assertEqual(status['phase'], 'VERIFYING')
        self.assertEqual(status['attempts'], 1)
        self.assertEqual(self.run_doctor()['phase'], 'RECOVERY_COOLDOWN')
        self.assertEqual(len(self.repairs()), 1)
        for attempt in (2, 3):
            status['retry_at'] = 0
            (self.state/'status.json').write_text(json.dumps(status))
            status = self.run_doctor()
            self.assertEqual(status['attempts'], attempt)
        status['retry_at'] = 0
        (self.state/'status.json').write_text(json.dumps(status))
        self.assertEqual(self.run_doctor()['phase'], 'RECOVERY_COOLDOWN')
        self.assertEqual(len(self.repairs()), 3)
        self.scenario.update(reason='healthy', probes=[0, 0, 0, 0])
        self.assertEqual(self.run_doctor()['reason'], 'HEALTHY')
        self.assertEqual(self.run_doctor()['attempts'], 3)
        self.run_doctor('reset')
        self.assertEqual(self.run_doctor()['attempts'], 0)

    def test_api_evidence_is_not_invented_or_leaked(self):
        for code, expected in [('403', 'AUTH_REJECTED'), ('429', 'PROVIDER_RATE_LIMITED'),
                                ('503', 'PROVIDER_API_UNAVAILABLE'), ('timeout', 'EGRESS_UNAVAILABLE')]:
            with self.subTest(code=code):
                (self.state/'hold.json').unlink(missing_ok=True)
                (self.root/'provider-stopped').unlink(missing_ok=True)
                self.scenario.update(probes=[7, 7, 7, 7], log='REST failed: bad HTTP status '+code)
                self.assertEqual(self.run_doctor()['reason'], expected)
        self.assertNotIn('AUTH_REJECTED', self.run_doctor('status'))

    def test_secret_missing_wrong_peer_and_filter_error_require_action(self):
        self.key.unlink()
        self.assertEqual(self.run_doctor()['reason'], 'SECRETS_UNAVAILABLE')
        self.key.touch()
        self.assertEqual(self.run_doctor()['reason'], 'CONFIGURATION_ERROR')
        self.key.write_text('fixture-value')
        self.scenario['reason'] = 'wrong-peer'
        self.assertEqual(self.run_doctor()['reason'], 'CONFIGURATION_ERROR')
        self.scenario['reason'] = 'firewall'
        self.assertEqual(self.run_doctor()['reason'], 'FIREWALL_ERROR')
        self.assertEqual(self.repairs(), [])

    def test_client_never_infers_provider_authorization(self):
        self.config['role'] = 'client'
        self.scenario.update(client=True, probes=[6, 6, 6, 6], log='bad HTTP status 401')
        self.assertEqual(self.run_doctor()['reason'], 'DNS_UNAVAILABLE')
        self.assertEqual(self.repairs(), [])

    def test_auth_hold_survives_monitor_restarts_and_reset(self):
        self.scenario.update(probes=[6]*4, log='bad HTTP status 401')
        self.run_doctor()
        self.scenario.update(log='')
        self.assertEqual(self.run_doctor()['reason'], 'AUTH_REJECTED')
        self.run_doctor('reset')
        self.assertEqual(self.run_doctor()['reason'], 'PROVIDER_UNHEALTHY')

    def test_dns_relay_repaired_only_after_upstream_success(self):
        self.prime()
        self.scenario['reason'] = 'dns-relay'
        for _ in range(3): status = self.run_doctor()
        self.assertEqual(status['reason'], 'DNS_UNAVAILABLE')
        self.assertEqual(self.repairs(), [['systemctl', 'restart', 'netns-vpn-dns.service']])

    def test_stale_status_and_last_failure_survive_success(self):
        self.scenario['reason'] = 'offline'
        self.run_doctor()
        self.scenario['reason'] = 'healthy'
        status = self.run_doctor()
        self.assertEqual(status['last_failure']['reason'], 'HOST_CONNECTIVITY_UNVERIFIED')
        status['checked_at'] = 1
        (self.state/'status.json').write_text(json.dumps(status))
        self.assertIn('STALE', self.run_doctor('status'))

    def test_probe_checks_both_families_and_preserves_marker_only_until_expiry(self):
        self.scenario['probes'] = [7, 0, 7, 7]
        self.run_doctor('probe')
        ready = (self.runtime/'ready').read_text()
        self.assertEqual(json.loads((self.runtime/'probes.json').read_text())['results'], [7, 0, 7, 7])
        self.scenario['probes'] = [6]*4
        self.run_doctor('probe', expected=1)
        self.assertEqual((self.runtime/'ready').read_text(), ready)

    def test_stale_wireguard_client_waits_without_recreating_transport(self):
        self.config['role'] = 'client'
        self.scenario.update(client=True, reason='handshake', probes=[7]*4)
        for _ in range(4): status = self.run_doctor()
        self.assertEqual(status['reason'], 'WG_HANDSHAKE_STALE')
        self.assertEqual(self.repairs(), [])

    def test_startup_grace_and_late_secret(self):
        self.scenario.update(reason='missing-link', probes=[7]*4)
        for _ in range(4): status = self.run_doctor()
        self.assertEqual(status['phase'], 'STARTING')
        self.assertEqual(self.repairs(), [])
        self.seed.unlink()
        self.assertEqual(self.run_doctor()['reason'], 'SECRETS_UNAVAILABLE')
        self.seed.write_text('fixture-new-private-seed')
        self.scenario.update(reason='healthy', probes=[0]*4)
        self.assertEqual(self.run_doctor()['reason'], 'HEALTHY')

    def test_changed_bootstrap_releases_auth_hold_without_reporting_token(self):
        self.scenario.update(probes=[6]*4, log='bad HTTP status 401')
        self.run_doctor()
        self.seed.write_text('fixture-renewed-bootstrap')
        self.scenario.update(log='', probes=[0]*4)
        (self.root/'provider-stopped').unlink(missing_ok=True)
        (self.root/'invocation').write_text('new-invocation')
        self.assertEqual(self.run_doctor()['reason'], 'HEALTHY')
        self.assertFalse((self.state/'hold.json').exists())

    def test_maintenance_never_repairs(self):
        (self.state/'maintenance').touch()
        self.scenario.update(reason='missing-link', probes=[7]*4)
        for _ in range(4):
            status = self.run_doctor()
            self.assertEqual(status['reason'], 'DISABLED')
            self.assertEqual(status['phase'], 'DISABLED')
        self.assertEqual(self.repairs(), [])

    def test_http_and_tls_endpoint_failures_do_not_restart_provider(self):
        self.prime()
        for rc in (22, 35, 60):
            self.scenario['probes'] = [rc]*4
            for _ in range(4): self.assertEqual(self.run_doctor()['reason'], 'EGRESS_UNAVAILABLE')
        self.assertEqual(self.repairs(), [])

    def test_resume_reapplies_grace_and_clock_skew_requires_action(self):
        self.prime()
        status = json.loads((self.state/'status.json').read_text())
        status['suspend'] -= 100
        (self.state/'status.json').write_text(json.dumps(status))
        self.scenario.update(reason='missing-link', probes=[7]*4)
        for _ in range(4): status = self.run_doctor()
        self.assertEqual(status['phase'], 'STARTING')
        self.assertEqual(self.repairs(), [])
        status['last_success'] = int(time.time()) + 3600
        (self.state/'status.json').write_text(json.dumps(status))
        self.assertEqual(self.run_doctor()['reason'], 'CLOCK_ERROR')
        self.assertEqual(self.repairs(), [])

    def test_underlay_repair_respects_provider_dependency_stop(self):
        self.prime()
        self.scenario.update(reason='underlay', probes=[7]*4)
        for _ in range(3): status = self.run_doctor()
        self.assertEqual(status['reason'], 'UNDERLAY_UNAVAILABLE')
        self.assertEqual(self.repairs(), [['systemctl', 'restart', 'netns-vpn-underlay.service', 'hide-me-vpn.service']])

    def test_provider_gate_honors_hold_and_changed_credentials(self):
        self.scenario.update(probes=[6]*4, log='bad HTTP status 401')
        self.run_doctor()
        self.run_doctor('provider-allowed', expected=1)
        self.seed.write_text('fixture-changed-seed')
        self.run_doctor('provider-allowed')

    def test_skipped_dns_is_retried_after_late_transport(self):
        self.prime()
        self.scenario['units'] = {'netns-vpn-dns.service': {'active':'inactive', 'started':'0', 'condition':'no'}}
        for _ in range(3): status = self.run_doctor()
        self.assertEqual(status['reason'], 'DNS_UNAVAILABLE')
        self.assertEqual(self.repairs(), [['systemctl', 'start', 'netns-vpn-dns.service']])
        self.assertIn('DNS_UNAVAILABLE', self.run_doctor('status'))

    def test_changed_credentials_wait_for_wan_before_consuming_budget(self):
        self.scenario.update(probes=[6]*4, log='bad HTTP status 401')
        self.run_doctor()
        self.seed.write_text('fixture-renewed-seed')
        self.scenario.update(reason='offline', log='', units={'hide-me-vpn.service': {'active':'inactive'}})
        for _ in range(4):
            status = self.run_doctor()
            self.assertEqual(status['reason'], 'HOST_CONNECTIVITY_UNVERIFIED')
            self.assertEqual(status['attempts'], 0)
        self.assertIn('HOST_CONNECTIVITY_UNVERIFIED', self.run_doctor('status'))

    def test_missing_unit_wins_over_inactive_later_unit(self):
        self.scenario['units'] = {'netns-vpn-shared.service': {'load':'not-found'},
                                  'tailscaled.service': {'active':'inactive'}}
        self.assertIn('DEPLOYMENT_MISMATCH', self.run_doctor('status'))

    def test_interrupted_repair_keeps_budget_and_cooldown(self):
        self.prime()
        self.scenario.update(reason='missing-link', probes=[7]*4, interrupt_repair=True)
        self.run_doctor()
        self.run_doctor()
        self.assertEqual(self.run_doctor(expected=-9)['attempts'], 1)
        self.scenario['interrupt_repair'] = False
        self.assertEqual(self.run_doctor()['phase'], 'RECOVERY_COOLDOWN')
        self.assertEqual(len(self.repairs()), 1)

    def test_identical_sops_rematerialization_preserves_auth_hold(self):
        self.scenario.update(probes=[6]*4, log='bad HTTP status 401')
        self.run_doctor()
        self.seed.unlink()
        self.seed.write_text('fixture-bootstrap-never-report')
        self.run_doctor('provider-allowed', expected=1)
        self.assertEqual(self.run_doctor()['reason'], 'AUTH_REJECTED')
        self.assertEqual(len(self.repairs()), 1)

    def test_prerequisite_failures_do_not_satisfy_provider_debounce(self):
        self.prime()
        self.scenario['reason'] = 'offline'
        for _ in range(4): self.run_doctor()
        self.scenario.update(reason='missing-link', probes=[7]*4)
        self.assertEqual(self.run_doctor()['attempts'], 0)
        self.assertEqual(self.run_doctor()['attempts'], 0)
        self.assertEqual(self.run_doctor()['attempts'], 1)

    def test_fast_provider_auth_exit_still_requires_action(self):
        # The monitor may run after the provider has already exited on HTTP 401.
        for state in ('failed', 'inactive'):
            with self.subTest(provider_state=state):
                self.scenario.update(
                    probes=[6]*4,
                    log='Rest: [ERR] Bad HTTP response ( 401 )',
                    units={'hide-me-vpn.service': {'active': state}},
                )
                if state == 'inactive':
                    # ExecStopPost records that a failed process was not
                    # deliberately stopped by the operator.
                    self.env['SERVICE_RESULT'] = 'exit-code'
                    self.run_doctor('lifecycle-stop', args=('hide-me-vpn.service',))
                    self.env.pop('SERVICE_RESULT')
                status = self.run_doctor()
                self.assertEqual(status['reason'], 'AUTH_REJECTED')
                self.assertEqual(status['phase'], 'ACTION_REQUIRED')
                self.assertTrue((self.state/'hold.json').exists())
                self.assertEqual(self.repairs(), [])
                (self.state/'hold.json').unlink()
                (self.state/'status.json').unlink()
                (self.state/'stops'/'hide-me-vpn.service').unlink(missing_ok=True)

    def test_skipped_provider_does_not_replay_old_authentication_log(self):
        self.scenario.update(
            probes=[6]*4, log='bad HTTP status 401',
            units={'hide-me-vpn.service': {'active': 'inactive', 'started': '0', 'condition': 'no'}},
        )
        self.assertEqual(self.run_doctor()['reason'], 'PROVIDER_UNHEALTHY')
        self.assertFalse((self.state/'hold.json').exists())

    def test_renewal_does_not_replay_failed_old_invocation_401(self):
        self.prime()
        self.scenario.update(
            probes=[6]*4, log='bad HTTP status 401',
            units={'hide-me-vpn.service': {'active': 'failed'}},
        )
        self.assertEqual(self.run_doctor()['reason'], 'AUTH_REJECTED')
        first_hold = json.loads((self.state/'hold.json').read_text())
        self.seed.write_text('fixture-renewed-credentials')
        # The completed old invocation is still present in systemd and journal.
        for _ in range(2):
            self.assertEqual(self.run_doctor()['reason'], 'PROVIDER_UNHEALTHY')
        status = self.run_doctor()
        self.assertEqual(status['phase'], 'VERIFYING')
        self.assertEqual(self.repairs(), [['systemctl', 'start', 'hide-me-vpn.service']])
        # Only a new failed attempt may establish a new authorization hold.
        self.scenario['units'] = {'hide-me-vpn.service': {'active': 'failed'}}
        self.scenario['logs'] = {'new-invocation': 'bad HTTP status 401'}
        self.assertEqual(self.run_doctor()['reason'], 'AUTH_REJECTED')
        renewed_hold = json.loads((self.state/'hold.json').read_text())
        self.assertEqual(renewed_hold['invocation'], 'new-invocation')
        self.assertNotEqual(renewed_hold['credentials'], first_hold['credentials'])
        # An exited provider with newly rejected credentials must not be
        # permitted another unattended authentication attempt.
        self.run_doctor('provider-allowed', expected=1)
        self.assertEqual(self.run_doctor()['reason'], 'AUTH_REJECTED')

    def test_renewal_never_reuses_rejected_invocation_after_offline_wait(self):
        self.prime()
        self.scenario.update(probes=[6]*4, log='bad HTTP status 401')
        self.run_doctor()
        self.seed.write_text('fixture-new-bootstrap')
        self.scenario['reason'] = 'offline'
        self.assertIn(self.run_doctor()['reason'], ('HOST_OFFLINE', 'HOST_CONNECTIVITY_UNVERIFIED'))
        self.scenario['reason'] = 'healthy'
        for _ in range(3): status = self.run_doctor()
        self.assertEqual(status['phase'], 'VERIFYING')
        self.assertEqual(status['attempts'], 1)
        # The old 401 remains on disk, scoped to the stopped invocation.
        self.scenario['probes'] = [0]*4
        self.assertEqual(self.run_doctor()['reason'], 'HEALTHY')
        self.scenario.update(probes=[6]*4, logs={'new-invocation': 'bad HTTP status 401'})
        self.assertEqual(self.run_doctor()['reason'], 'AUTH_REJECTED')

    def test_stop_intent_uses_lifecycle_record_not_old_timestamps(self):
        self.env['SERVICE_RESULT'] = 'success'
        self.run_doctor('lifecycle-start', args=('hide-me-vpn.service',))
        # A queued namespace stop propagates, without meaning provider maintenance.
        self.scenario['units'] = {'netns-vpn.service': {'job':'71 /job/71'}}
        self.run_doctor('lifecycle-stop', args=('hide-me-vpn.service',))
        self.scenario.update(units={'hide-me-vpn.service': {'active':'inactive'}}, probes=[7]*4)
        self.assertEqual(self.run_doctor()['reason'], 'PROVIDER_UNHEALTHY')
        self.scenario['units'] = {}
        self.run_doctor('lifecycle-start', args=('hide-me-vpn.service',))
        self.run_doctor('lifecycle-stop', args=('hide-me-vpn.service',))
        self.scenario['units'] = {'hide-me-vpn.service': {'active':'inactive'}}
        self.assertEqual(self.run_doctor()['reason'], 'DISABLED')
        self.assertEqual(self.repairs(), [])

    def test_late_namespace_is_waiting_not_firewall_error(self):
        (self.root/'netns').unlink()
        self.scenario.update(reason='firewall', units={'netns-vpn.service': {'active':'activating', 'started':'0'}})
        self.assertEqual(self.run_doctor()['reason'], 'NAMESPACE_UNAVAILABLE')
        self.scenario.update(reason='healthy', units={})
        (self.root/'netns').touch()
        self.assertEqual(self.run_doctor()['reason'], 'HEALTHY')

    def test_host_route_loss_differs_from_unverified_https_and_partial_family(self):
        self.scenario.update(host_probes={'ipv4':7, 'ipv6':7}, host_routes={'ipv4':False, 'ipv6':False})
        self.assertEqual(self.run_doctor()['reason'], 'HOST_OFFLINE')
        self.scenario['host_routes'] = {'ipv4':True, 'ipv6':True}
        for rc in (7, 6, 22, 60):
            self.scenario['host_probes'] = {'ipv4':rc, 'ipv6':rc}
            self.assertEqual(self.run_doctor()['reason'], 'HOST_CONNECTIVITY_UNVERIFIED')
        self.scenario['host_probes'] = {'ipv4':0, 'ipv6':7}
        status = self.run_doctor()
        self.assertEqual(status['reason'], 'HEALTHY')
        self.assertEqual(status['details']['host']['ipv6']['probes'], [7,7])
        self.assertIn('IPv6 unverified', self.run_doctor('status'))
        self.scenario['host_probes'] = {'ipv4':0, 'ipv6':0}
        self.assertEqual(self.run_doctor()['reason'], 'HEALTHY')
        self.assertEqual(self.repairs(), [])

    def test_app_readiness_is_distinct_from_routing_policy(self):
        self.run_doctor()
        output = self.run_doctor('status')
        self.assertIn('Applications: READY', output)
        self.assertIn('Routing policy: fail-closed', output)
        self.scenario['units'] = {'netns-vpn-recovery.timer': {'active':'inactive'}}
        scheduler = self.run_doctor('status')
        self.assertIn('Applications: READY', scheduler)
        self.assertIn('scheduler inactive', scheduler)
        self.scenario['units'] = {}
        self.assertIn('Applications: BLOCKED', self.run_doctor('status', args=('--entry-failed',)))
        self.scenario['units'] = {'netns-vpn-shared.service': {'active':'failed'}}
        failed = self.run_doctor('status')
        self.assertIn('READINESS_FAILED', failed)
        self.assertIn('Applications: BLOCKED', failed)
        self.assertNotIn('No action required', failed)
        self.scenario['units'] = {}
        self.scenario['probes'] = [0,7,7,7]
        self.run_doctor()
        self.assertIn('Applications: DEGRADED', self.run_doctor('status'))
        (self.runtime/'ready').unlink()
        self.assertIn('Applications: BLOCKED', self.run_doctor('status'))
        status = json.loads((self.state/'status.json').read_text())
        status['checked_at'] = 1
        (self.state/'status.json').write_text(json.dumps(status))
        self.assertIn('Applications: UNKNOWN', self.run_doctor('status', args=('--verbose',)))

    def test_explicit_stop_during_reauthorization_remains_disabled(self):
        self.prime()
        self.scenario.update(probes=[6]*4, log='bad HTTP status 401')
        self.run_doctor()
        self.seed.write_text('fixture-new-seed')
        (self.root/'provider-stopped').unlink(missing_ok=True)
        (self.root/'invocation').write_text('new-invocation')
        self.env['SERVICE_RESULT'] = 'success'
        self.run_doctor('lifecycle-start', args=('hide-me-vpn.service',))
        self.run_doctor('lifecycle-stop', args=('hide-me-vpn.service',))
        self.scenario['units'] = {'hide-me-vpn.service': {'active':'inactive'}}
        for _ in range(4): self.assertEqual(self.run_doctor()['reason'], 'DISABLED')
        self.assertEqual(self.repairs(), [['systemctl', 'stop', 'hide-me-vpn.service']])

    def test_failed_namespace_start_uses_start_without_teardown(self):
        self.prime()
        (self.root/'netns').unlink()
        self.scenario['units'] = {'netns-vpn.service': {'active':'failed', 'started':'0'}}
        for _ in range(3): status = self.run_doctor()
        self.assertEqual(status['phase'], 'VERIFYING')
        self.assertEqual(self.repairs(), [['systemctl', 'start', 'netns-vpn.service']])
        (self.root/'netns').touch()
        self.scenario['units'] = {}
        self.assertEqual(self.run_doctor()['reason'], 'HEALTHY')

    def test_provider_restarting_during_probe_does_not_reuse_old_error(self):
        self.scenario.update(probes=[6]*4, log='bad HTTP status 401', restart_during_probe=True)
        self.assertNotEqual(self.run_doctor()['reason'], 'AUTH_REJECTED')
        self.assertFalse((self.state/'hold.json').exists())
        self.assertEqual(self.repairs(), [])

    def test_pending_service_job_is_not_a_manual_stop_or_repair_target(self):
        self.prime()
        self.scenario.update(probes=[7]*4, units={'hide-me-vpn.service': {'active':'deactivating', 'job':'9 /job/9'}})
        for _ in range(3): status = self.run_doctor()
        self.assertEqual(status['phase'], 'STARTING')
        self.assertEqual(self.repairs(), [])

    def test_existing_namespace_with_damaged_policy_is_never_reinitialized(self):
        self.prime()
        self.scenario.update(reason='firewall', units={'netns-vpn.service': {'active':'failed', 'started':'0'}})
        for _ in range(3):
            self.assertEqual(self.run_doctor()['reason'], 'FIREWALL_ERROR')
        self.assertEqual(self.repairs(), [])


if __name__ == '__main__':
    unittest.main()
