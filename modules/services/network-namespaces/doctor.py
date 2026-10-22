"""Local VPN diagnosis and bounded recovery. Never accepts application commands."""
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time


def command(*args, timeout=10):
    try:
        p = subprocess.run(args, capture_output=True, text=True, timeout=timeout,
                           env=dict(os.environ, LC_ALL='C'))
        return p.returncode, p.stdout
    except (OSError, subprocess.TimeoutExpired):
        return 125, ''


def read_json(path):
    try:
        return json.loads(Path(path).read_text())
    except (OSError, ValueError):
        return {}


def save(path, value, mode=0o644):
    tmp = Path(str(path) + '.new')
    tmp.touch(mode=mode)
    tmp.chmod(mode)
    tmp.write_text(json.dumps(value, sort_keys=True) + '\n')
    tmp.replace(path)


def unit(name):
    rc, out = command('systemctl', 'show', name, '-p',
                      'LoadState,ActiveState,UnitFileState,Result,ActiveEnterTimestampMonotonic,ExecMainStartTimestampMonotonic,ConditionResult,InvocationID,Job', timeout=2)
    return dict(line.split('=', 1) for line in out.splitlines() if '=' in line) if not rc else {}


def stop_intent(c, name, s):
    if name not in c['dependencies']:
        return None
    if s.get('ActiveState') not in ('inactive', 'deactivating'):
        return None
    record = read_json(Path(c['state']) / 'stops' / name)
    if record.get('boot') == Path('/proc/sys/kernel/random/boot_id').read_text().strip():
        return record.get('intent')
    if s.get('Job', '0') not in ('', '0'):
        return None
    if (s.get('Result') == 'success' and s.get('ConditionResult') != 'no'
            and int(s.get('ExecMainStartTimestampMonotonic', '0') or 0) > 0):
        return 'unknown'
    return None


def lifecycle(c, name, event):
    if name not in c['dependencies']:
        sys.exit('Unknown managed VPN unit')
    stops = Path(c['state']) / 'stops'
    stops.mkdir(parents=True, exist_ok=True, mode=0o755)
    path = stops / name
    own = unit(name)
    intent = 'running'

    if event == 'stop':
        # A stopped dependency may still be active while its stop job is queued.
        dependencies = [unit(d) for d in c['dependencies'][name]]
        old = read_json(path)

        if old.get('intent') == 'recovery' and old.get('invocation') == own.get('InvocationID'):
            intent = 'recovery'
        elif (os.environ.get('SERVICE_RESULT') != 'success'
              or own.get('ConditionResult') == 'no'
              or own.get('Result') not in ('success', None)
              or any(d.get('ActiveState') != 'active' or d.get('Job', '0') not in ('', '0') for d in dependencies)):
            intent = 'dependency'
        else:
            intent = 'manual'

    save(path, dict(intent=intent, invocation=own.get('InvocationID', ''),
                    boot=Path('/proc/sys/kernel/random/boot_id').read_text().strip()))


def credentials(c):
    # Private fingerprints survive SOPS /run re-materialization across reboot.
    # Only hold.json (0600) contains them; status/journal never does.
    result = []
    for path in (c.get('bootstrap'), c.get('token')):
        try:
            result.append(hashlib.sha256(Path(path).read_bytes()).hexdigest() if path else None)
        except OSError:
            result.append(None)
    return result


def authorization(log):
    # Whitelist classifications only; no upstream text reaches status or journal.
    if re.search(r'(?:status|response)\s*\(?\s*(401|403)\b', log, re.I):
        return 'AUTH_REJECTED'
    if re.search(r'(?:status|response)\s*\(?\s*429\b', log, re.I):
        return 'PROVIDER_RATE_LIMITED'
    if re.search(r'(?:status|response)\s*\(?\s*5[0-9][0-9]\b', log, re.I):
        return 'PROVIDER_API_UNAVAILABLE'
    return None


MESSAGES = {

    'HEALTHY': ('VPN egress and local checks succeeded.', 'No action required.'),

    'AUTH_REJECTED': ('Provider authorization rejected (HTTP 401/403); exact cause unknown.',
                      'Use the private re-auth/bootstrap procedure in modules/services/network-namespaces/README.md; then reset recovery.'),

    'DEPLOYMENT_MISMATCH': ('Required unit is absent from the active generation.',
                            'Compare /run/current-system and the expected generation; deploy only with operator approval.'),

    'DISABLED': ('A required unit is masked, disabled or deliberately stopped.',
                 'Check maintenance state and systemctl show; recovery will not unmask or fight a stop.'),

    'CONFIGURATION_ERROR': ('A required runtime secret or declared WireGuard peer is missing/incorrect.',
                            'Check declared secret paths, SOPS provisioning and public peer configuration privately.'),

    'NAMESPACE_UNAVAILABLE': ('VPN namespace is not ready; policy cannot yet be inspected.',
                              'Wait for netns-NAME.service; inspect its dependencies if this persists.'),

    'SECRETS_UNAVAILABLE': ('A runtime secret is not provisioned yet.',
                            'Check SOPS provisioning and named secret paths privately; recovery waits.'),

    'STOP_INTENT_UNKNOWN': ('An inactive service has no current lifecycle record; stop intent is unknown.',
                            'Verify maintenance intent, then explicitly start the required unit if appropriate.'),

    'HOST_OFFLINE': ('No usable host IPv4/IPv6 route and all host HTTPS checks failed.',
                     'Check host WAN, LAN/DHCP, routing and clock; recovery waits for connectivity.'),

    'HOST_CONNECTIVITY_UNVERIFIED': ('Host HTTPS checks failed despite route evidence; Internet availability is unverified.',
                                      'Inspect per-family DNS/TLS/HTTP results and WAN/LAN; recovery waits without restarting VPN.'),

    'TAILSCALE_OFFLINE': ('Tailscale is stopped, unavailable or requires authentication.',
                         'Check tailscale status on the host; authenticate privately if requested.'),

    'GATEWAY_UNREACHABLE': ('Gateway Tailscale peer did not respond; remote provider state is unknown.',
                           'Check gateway power/uplink/Tailscale from an ordinary host terminal.'),

    'TRANSPORT_MISSING': ('Local shared0 interface or failed transport needs recovery.',
                          'Inspect netns-NAME-shared.service and the runtime key path.'),

    'WG_HANDSHAKE_STALE': ('WireGuard handshake is missing/stale despite reachable prerequisites.',
                           'Check peer keys, endpoint and UDP filtering; Tailscale ping alone does not prove WireGuard.'),

    'PROVIDER_UNHEALTHY': ('Provider is missing, failed or functionally unhealthy despite its process state.',
                           'Inspect sanitized provider diagnostics and hide-me-NAME.service privately.'),

    'UNDERLAY_UNAVAILABLE': ('Gateway tap0 or underlay service is unhealthy.',
                             'Check netns-NAME-underlay.service; host networking remains separate.'),

    'DNS_UNAVAILABLE': ('Isolated DNS failed; no host resolver fallback is permitted.',
                         'Check private provider resolvers and netns-NAME-dns.service on the gateway.'),

    'FIREWALL_ERROR': ('Namespace filter, forwarding or NAT checks failed.',
                       'Operator must verify namespace nft rules and forwarding; no automatic firewall weakening.'),

    'ROUTE_ERROR': ('A required IPv4/IPv6 tunnel route is missing.',
                    'Inspect namespace routes and provider policy routing; no host-route fallback.'),

    'EGRESS_UNAVAILABLE': ('All isolated HTTPS destinations failed; exact upstream cause is unknown.',
                           'Inspect per-family probe exit codes; no restart based solely on endpoint failures.'),

    'EGRESS_DEGRADED': ('Only some destinations/address families succeeded.',
                        'Inspect probe results; a single endpoint/family failure does not trigger recovery.'),

    'PROVIDER_RATE_LIMITED': ('Provider API reported HTTP 429; reconnect attempts are paused.',
                             'Check provider retry guidance privately before resetting recovery.'),

    'PROVIDER_API_UNAVAILABLE': ('Provider API reported HTTP 5xx; bounded recovery waits for backoff.',
                                'Check provider availability; this is not evidence of invalid credentials.'),

    'STARTING': ('Startup/resume grace period is active.', 'Wait for prerequisites and the next health check.'),

    'CLOCK_ERROR': ('Clock moved backwards or a WireGuard handshake has a future timestamp.',
                    'Verify host time synchronization before attempting VPN recovery.'),

    'UNKNOWN': ('Diagnostics are unavailable or stale.', 'Check the recovery timer and run vpn-status --verbose.'),
}


def inspect(c, old, now):
    if old.get('last_success', 0) > now + 5:
        return 'CLOCK_ERROR', None, {}
    name = c['name']
    if (Path(c['state']) / 'maintenance').exists():
        return 'DISABLED', None, {'maintenance': True}
    prefix = f'netns-{name}'
    provider = f'hide-me-{name}.service'
    client = c['role'] == 'client'
    expected = [f'{prefix}.service', f'{prefix}-shared.service', 'tailscaled.service']
    if not client:
        expected += [f'{prefix}-underlay.service', provider, f'{prefix}-dns.service']
    units = {u: unit(u) for u in expected}
    details = {'units': units, 'generation': str(Path('/run/current-system').resolve())}
    for u, s in units.items():
        if s.get('LoadState') == 'not-found' or not s:
            return 'DEPLOYMENT_MISMATCH', None, details
        if s.get('LoadState') == 'masked' or s.get('UnitFileState') in ('disabled', 'masked'):
            return 'DISABLED', None, details
    hold = read_json(Path(c['state']) / 'hold.json')
    if hold and hold.get('credentials') == credentials(c):
        return hold['reason'], None, details
    released_hold = bool(hold)
    if released_hold and 'invocation' not in hold:
        # Upgrade old holds before trying a changed credential, even while offline.
        hold['invocation'] = old.get('details', {}).get('units', {}).get(provider, {}).get('InvocationID', units[provider].get('InvocationID', ''))
        save(Path(c['state']) / 'hold.json', hold, 0o600)
    details['provider_reauth_pending'] = released_hold
    for u, s in units.items():
        intent = stop_intent(c, u, s)
        if intent == 'manual' or (intent == 'unknown' and not (u == provider and released_hold)):
            return ('TAILSCALE_OFFLINE' if u == 'tailscaled.service' else
                    'DISABLED' if intent == 'manual' else 'STOP_INTENT_UNKNOWN'), None, details

    for path in [c['key']] + ([c['bootstrap']] if c.get('bootstrap') and not client else []):
        try:
            if Path(path).stat().st_size == 0:
                return 'CONFIGURATION_ERROR', None, details
        except FileNotFoundError:
            return 'SECRETS_UNAVAILABLE', None, details
        except OSError:
            return 'CONFIGURATION_ERROR', None, details

    namespace = units[f'{prefix}.service']
    if (not Path(c['namespace_path']).exists()
            or command('ip', '-n', name, 'link', 'show', 'lo')[0]
            or namespace.get('ActiveState') in ('activating', 'deactivating')):
        component = f'{prefix}.service' if namespace.get('ActiveState') in ('inactive', 'failed') else None
        return 'NAMESPACE_UNAVAILABLE', component, details

    def ip(*args):
        return command('ip', '-n', name, *args)

    def inside(*args):
        return command('ip', 'netns', 'exec', name, *args)

    # Route/interface evidence is separate from endpoint/DNS/TLS probe outcomes.
    host = {}

    for family, label, address in (('-4', 'ipv4', '1.1.1.1'), ('-6', 'ipv6', '2606:4700:4700::1111')):
        rc, route = command('ip', '-j', family, 'route', 'get', address)
        usable = None

        try:
            routes = json.loads(route) if not rc else []
            dev = routes[0].get('dev') if routes else None
            if dev:
                rc, link = command('ip', '-j', 'link', 'show', 'dev', dev)
                usable = bool(not rc and any('UP' in x.get('flags', []) for x in json.loads(link)))
            elif rc in (0, 2):
                usable = False
        except (ValueError, IndexError, TypeError):
            pass

        results = [command('curl', '--noproxy', '*', family, '-fsS', '--connect-timeout', '2',
                           '--max-time', '4', '--output', '/dev/null', u)[0] for u in c['urls']]
        host[label] = dict(route=usable, probes=results)

    details['host'] = host
    if not any(0 in h['probes'] for h in host.values()):
        return ('HOST_OFFLINE' if all(h['route'] is False for h in host.values())
                else 'HOST_CONNECTIVITY_UNVERIFIED'), None, details
    rc, tail = command('tailscale', 'status', '--json')

    try:
        backend = json.loads(tail).get('BackendState') if not rc else None
        details['tailscale'] = backend if backend in ('Running', 'Stopped', 'NeedsLogin', 'NeedsMachineAuth', 'Starting') else 'unavailable'
        running = backend == 'Running'
    except ValueError:
        running = False

    if not running:
        return 'TAILSCALE_OFFLINE', None, details
    if client and command('tailscale', 'ping', '--timeout=3s', '--c=1', c['endpoint'], timeout=5)[0]:
        return 'GATEWAY_UNREACHABLE', None, details
    rc, firewall = inside('nft', 'list', 'table', 'inet', 'agent_workspace')
    if rc or any(not re.search(r'chain\s+' + chain + r'\s*\{[^}]*policy drop;', firewall, re.S)
                 for chain in ('output', 'input', 'forward')):
        return 'FIREWALL_ERROR', None, details
    if c['role'] == 'gateway':
        rc, nat = inside('nft', 'list', 'table', 'inet', 'shared_vpn_nat')
        rc2, forwarding = inside('sysctl', '-n', 'net.ipv4.ip_forward', 'net.ipv6.conf.all.forwarding')
        if rc or 'masquerade' not in nat or rc2 or forwarding.split() != ['1', '1']:
            return 'FIREWALL_ERROR', None, details
    if namespace.get('ActiveState') != 'active':
        return 'NAMESPACE_UNAVAILABLE', f'{prefix}.service', details
    transport = f'{prefix}-shared.service'
    if ip('link', 'show', 'shared0')[0] or units[transport].get('ActiveState') not in ('active', 'activating'):
        return 'TRANSPORT_MISSING', transport, details
    _, peers = inside('wg', 'show', 'shared0', 'peers')
    if set(peers.split()) != set(c['peers']):
        return 'CONFIGURATION_ERROR', None, details
    # Health executes in systemd's isolated network AND private resolver mounts.
    command('systemctl', 'start', f'{prefix}-health.service', timeout=75)
    now = int(time.time())
    probe = read_json(Path(c['runtime']) / 'probes.json')
    details['probes'] = probe
    results = probe.get('results', [])
    fresh = 0 <= now - probe.get('checked_at', 0) <= 90
    any_success = fresh and 0 in results
    if not client:
        units[provider] = unit(provider)
    invocation = units.get(provider, {}).get('InvocationID', '')
    provider_state = units.get(provider, {}).get('ActiveState')
    # A rejected login can terminate before the next monitor tick. In that
    # case systemd retains the completed invocation even if the unit is failed
    # or inactive. Never inspect logs for a condition-skipped/unstarted unit.
    provider_started = int(units.get(provider, {}).get('ExecMainStartTimestampMonotonic', '0') or 0) > 0
    current_attempt = (not client and invocation
                       and (provider_state in ('active', 'activating')
                            or (provider_state in ('failed', 'inactive') and provider_started))
                       and (not released_hold or invocation != hold.get('invocation')))

    if current_attempt and not any_success:
        # Inactive units retain InvocationID; changed credentials must get a new attempt.
        _, log = command('journalctl', '--no-pager', '-o', 'cat', '-n', '200',
                         '-u', provider, f'_SYSTEMD_INVOCATION_ID={invocation}',
                         '--since', f'@{max(old.get("last_success", 0), now - 600)}')
        evidence = authorization(log)
        if evidence:
            details['provider_evidence_invocation'] = invocation
            return evidence, provider if evidence == 'PROVIDER_API_UNAVAILABLE' else None, details

    if not client:
        underlay = f'{prefix}-underlay.service'
        if (ip('link', 'show', 'tap0')[0] or units[underlay].get('ActiveState') not in ('active', 'activating')
                or 'via 10.0.2.2 dev tap0' not in ip('-4', 'route', 'show', 'table', 'main', 'default')[1]):
            return 'UNDERLAY_UNAVAILABLE', underlay, details
        if (ip('link', 'show', 'hm0')[0] or units[provider].get('ActiveState') not in ('active', 'activating')
                or (released_hold and invocation == hold.get('invocation'))):
            return 'PROVIDER_UNHEALTHY', provider, details

    interface = 'shared0' if client else 'hm0'
    for family, address in [('-4', '1.1.1.1'), ('-6', '2606:4700:4700::1111')]:
        rc, route = ip(family, 'route', 'get', address)
        if rc or f'dev {interface}' not in route:
            return 'ROUTE_ERROR', transport if client else provider, details
    rc, handshakes = inside('wg', 'show', interface, 'latest-handshakes')
    stamps = [int(x.split()[1]) for x in handshakes.splitlines()
              if len(x.split()) == 2 and x.split()[1].isdigit()]
    now = int(time.time())
    if any(t > now + 5 for t in stamps):
        return 'CLOCK_ERROR', None, details
    if rc or not stamps or not any(0 <= now - t < 180 and t > 0 for t in stamps):
        # A stale peer is ambiguous: wait on clients; provider recovery only on gateway.
        return 'WG_HANDSHAKE_STALE', None if client else provider, details
    try:
        resolver = (Path(c['runtime']) / 'resolv.conf').read_text()
    except OSError:
        resolver = ''
    if not re.search(r'^nameserver\s+(?!127\.0\.0\.1\b|::1\b)\S+', resolver, re.M):
        return 'DNS_UNAVAILABLE', provider if not client else None, details

    if not fresh or not any_success:
        dns_failure = fresh and results and all(r == 6 for r in results)
        # Two independent destinations, both families, repeated failures and a
        # healthy host uplink justify provider-only recovery; HTTP/TLS errors do not.
        recoverable = fresh and len(c['urls']) >= 2 and results and all(r in (6, 7, 28) for r in results)
        return ('DNS_UNAVAILABLE' if dns_failure else 'EGRESS_UNAVAILABLE'), (provider if not client and recoverable else None), details

    if c['role'] == 'gateway':
        # The relay query runs in the isolated health unit, not through
        # ip netns exec in this host-side recovery service. The latter can
        # fail for sandbox/mount reasons unrelated to live DNS connectivity.
        dns = f'{prefix}-dns.service'
        relay = probe.get('relay_dns')
        if (not isinstance(relay, dict) or not isinstance(relay.get('exit_code'), int)
                or relay['exit_code'] == 125):
            # Absent/failed diagnostic evidence must never restart a working relay.
            return 'UNKNOWN', None, details
        if (relay['exit_code'] != 0 or not relay.get('answered')
                or units[dns].get('ActiveState') not in ('active', 'activating')):
            return 'DNS_UNAVAILABLE', dns, details

    return ('HEALTHY' if all(r == 0 for r in results) else 'EGRESS_DEGRADED'), None, details


def reconcile(c):
    now = int(time.time())
    state_path = Path(c['state']) / 'status.json'
    old = read_json(state_path)
    reason, component, details = inspect(c, old, now)
    if details.get('provider_evidence_invocation'):
        current_provider = unit(f'hide-me-{c["name"]}.service')
        if current_provider.get('InvocationID') != details['provider_evidence_invocation']:
            reason, component = 'STARTING', None
            details['units'][f'hide-me-{c["name"]}.service'] = current_provider
    now = int(time.time())
    boot = Path('/proc/sys/kernel/random/boot_id').read_text().strip()
    suspend = time.clock_gettime(time.CLOCK_BOOTTIME) - time.monotonic()
    new_boot = old.get('boot') != boot
    resumed = suspend - old.get('suspend', suspend) > 5
    grace_until = old.get('grace_until', 0)
    if new_boot or resumed:
        grace_until = now + 120
    # Service startup gets its own grace even if a timer/package was just replaced.
    for s in details.get('units', {}).values():
        started = int(s.get('ActiveEnterTimestampMonotonic', '0') or 0) / 1000000
        if started and 0 <= time.monotonic() - started < 120:
            grace_until = max(grace_until, now + int(120 - (time.monotonic() - started)))
    healthy = reason in ('HEALTHY', 'EGRESS_DEGRADED')
    failures = 0 if healthy else (old.get('failures', 0) + 1 if old.get('reason') == reason else 1)
    attempts = old.get('attempts', 0)
    retry_at = old.get('retry_at', 0)
    phase = ('HEALTHY' if reason == 'HEALTHY' else 'DEGRADED') if healthy else 'WAITING'
    manual = reason in ('AUTH_REJECTED', 'PROVIDER_RATE_LIMITED', 'CONFIGURATION_ERROR',
                        'DEPLOYMENT_MISMATCH', 'FIREWALL_ERROR', 'CLOCK_ERROR', 'STOP_INTENT_UNKNOWN')

    if healthy:
        (Path(c['state']) / 'hold.json').unlink(missing_ok=True)
        # Ten healthy minutes replenish budget; a single success cannot hide flapping.
        healthy_since = old.get('healthy_since') or now
        if now - healthy_since >= 600:
            attempts, retry_at = 0, 0
    else:
        healthy_since = 0

    if manual:
        phase = 'ACTION_REQUIRED'

        if reason in ('AUTH_REJECTED', 'PROVIDER_RATE_LIMITED'):
            hold_path = Path(c['state']) / 'hold.json'
            provider = f'hide-me-{c["name"]}.service'
            rejected_invocation = details.get('provider_evidence_invocation')
            new_hold = {'reason': reason, 'credentials': credentials(c),
                        'invocation': rejected_invocation or details.get('units', {}).get(provider, {}).get('InvocationID', '')}
            # A renewed credential can fail before the monitor sees a running
            # process. Replace the old hold using fresh invocation evidence,
            # even when systemd has already marked the unit failed/inactive.
            if rejected_invocation or not hold_path.exists():
                save(hold_path, new_hold, 0o600)

            if details.get('units', {}).get(provider, {}).get('ActiveState') in ('active', 'activating', 'deactivating'):
                stops = Path(c['state']) / 'stops'
                stops.mkdir(exist_ok=True)
                save(stops / provider, dict(intent='recovery', invocation=details['units'][provider].get('InvocationID', ''), boot=boot))
                command('systemctl', 'stop', provider, timeout=40)
                save(hold_path, new_hold, 0o600)
    elif reason == 'DISABLED':
        phase = 'DISABLED'
    elif component and failures >= 3 and now >= grace_until:
        if attempts >= 3 or now < retry_at:
            phase = 'RECOVERY_COOLDOWN'
        else:
            # Recheck a concurrent deliberate stop before issuing a repair.
            current = unit(component)

            if current.get('Job', '0') not in ('', '0') or current.get('ActiveState') in ('activating', 'deactivating'):
                reason, phase, component = 'STARTING', 'STARTING', None
            elif ((Path(c['state']) / 'maintenance').exists()
                    or stop_intent(c, component, current) == 'manual'
                    or (stop_intent(c, component, current) == 'unknown' and not read_json(Path(c['state']) / 'hold.json'))):
                component = None
                reason, phase = 'DISABLED', 'DISABLED'
            else:
                attempts += 1
                retry_at = now + (120, 300, 900)[attempts - 1]
                phase = 'VERIFYING'
                # Persist budget before a blocking repair, including monitor interruption.
                save(state_path, dict(old, attempts=attempts, retry_at=retry_at, phase=phase,
                                      reason=reason, message=MESSAGES[reason][0],
                                      failures=failures, recovery_pending=True, last_component=component))
                command('systemctl', 'reset-failed', component)
                targets = [component]
                if component == f'netns-{c["name"]}-underlay.service':
                    # Restore both coupled components after repairing a broken provider underlay.
                    targets.append(f'hide-me-{c["name"]}.service')
                operation = 'start' if current.get('ActiveState') in ('inactive', 'failed') or component == f'netns-{c["name"]}.service' else 'restart'
                command('systemctl', operation, *targets, timeout=150)
            # Restart completion is NOT success. Next isolated check must verify it.
    elif not healthy and now < grace_until and not manual:
        phase = 'STARTING'

    message, action = MESSAGES[reason]
    if phase == 'RECOVERY_COOLDOWN' and attempts >= 3:
        action = f'Budget exhausted; inspect failures, then explicitly reset with sudo /etc/network-namespaces/{c["name"]}-recovery-reset.'

    record = dict(reason=reason, phase=phase, message=message, next_action=action.replace('NAME', c['name']),
                  host=c['host'], role=c['role'], checked_at=now, failures=failures,
                  operator_action_required=manual or (phase == 'RECOVERY_COOLDOWN' and attempts >= 3),
                  attempts=attempts, retry_at=retry_at, last_component=component or old.get('last_component'),
                  last_success=now if healthy else old.get('last_success', 0),
                  last_recovery=now if healthy and old.get('recovery_pending') else old.get('last_recovery', 0),
                  recovery_pending=not healthy and (phase == 'VERIFYING' or old.get('recovery_pending', False)),
                  healthy_since=healthy_since, grace_until=grace_until, boot=boot, suspend=suspend,
                  details=details)

    record['last_failure'] = old.get('last_failure') if healthy else dict(
        reason=reason, checked_at=now, probes=details.get('probes', {}),
        first_seen=(old.get('last_failure') or {}).get('first_seen', now) if old.get('reason') == reason else now)
    save(state_path, record)
    if (reason, phase) != (old.get('reason'), old.get('phase')):
        print(json.dumps(dict(VPN_REASON=reason, VPN_PHASE=phase, VPN_ATTEMPTS=attempts)))


def status(c, verbose=False, entry_failed=False):
    s = read_json(Path(c['state']) / 'status.json')
    # Unit existence is checked live, including before the first scheduled check.
    expected = [f'netns-{c["name"]}.service', f'netns-{c["name"]}-shared.service',
                f'netns-{c["name"]}-recovery.timer', 'tailscaled.service']
    if c['role'] != 'client':
        expected += [f'hide-me-{c["name"]}.service', f'netns-{c["name"]}-underlay.service', f'netns-{c["name"]}-dns.service']
    active_units = True
    known_units = True

    for u in expected:
        info = unit(u)
        active_units = active_units and (u.endswith('.timer') or info.get('ActiveState') == 'active')
        if u.endswith('.timer'):
            s['recovery_scheduler'] = info.get('ActiveState', 'unknown')
        known_units = known_units and bool(info)
        managed_stop = (u == f'hide-me-{c["name"]}.service' and s.get('details', {}).get('provider_reauth_pending'))
        intent = stop_intent(c, u, info)
        stopped = intent == 'manual'

        if info.get('LoadState') == 'not-found':
            s.update(reason='DEPLOYMENT_MISMATCH', phase='ACTION_REQUIRED',
                     message=MESSAGES['DEPLOYMENT_MISMATCH'][0], next_action=MESSAGES['DEPLOYMENT_MISMATCH'][1])
            break
        elif s.get('reason') != 'DEPLOYMENT_MISMATCH' and (info.get('LoadState') == 'masked' or (stopped and s.get('reason') not in ('AUTH_REJECTED', 'PROVIDER_RATE_LIMITED'))):
            s.update(reason='DISABLED', phase='DISABLED', message=MESSAGES['DISABLED'][0],
                     next_action=MESSAGES['DISABLED'][1])
        elif intent == 'unknown' and not managed_stop and s.get('reason') not in ('AUTH_REJECTED', 'PROVIDER_RATE_LIMITED', 'DEPLOYMENT_MISMATCH'):
            s.update(reason='STOP_INTENT_UNKNOWN', phase='ACTION_REQUIRED',
                     message=MESSAGES['STOP_INTENT_UNKNOWN'][0], next_action=MESSAGES['STOP_INTENT_UNKNOWN'][1])

    if entry_failed and s.get('reason') in ('HEALTHY', 'EGRESS_DEGRADED'):
        s.update(reason='READINESS_FAILED', phase='BLOCKED',
                 message='Fresh launch readiness failed; previous scheduled probes are insufficient.',
                 next_action='Inspect the local readiness reason above and vpn-status --verbose; wait for the next check.')
    age = int(time.time()) - s.get('checked_at', 0)
    stale = not 0 <= age <= 120
    try:
        marker_age = int(time.time()) - int((Path(c['runtime']) / 'ready').read_text().strip())
        marker_fresh = 0 <= marker_age <= 90
    except (OSError, ValueError):
        marker_fresh = False

    if entry_failed or (known_units and not active_units) or not Path(c['namespace_path']).exists():
        applications = 'BLOCKED'
    elif stale or not known_units:
        applications = 'UNKNOWN'
        s['next_action'] = MESSAGES['UNKNOWN'][1]
    elif not marker_fresh:
        applications = 'BLOCKED'
    else:
        applications = {'HEALTHY':'READY', 'EGRESS_DEGRADED':'DEGRADED'}.get(s.get('reason'), 'BLOCKED')

    if applications == 'BLOCKED' and s.get('reason') in ('HEALTHY', 'EGRESS_DEGRADED'):
        s.update(reason='READINESS_FAILED', phase='BLOCKED',
                 message='Current unit/namespace state or the IPv4 readiness marker is unavailable.',
                 next_action='Wait for the next check; inspect vpn-status --verbose and required units if persistent.')
    s['applications'] = applications
    s['routing_policy'] = 'fail-closed'
    print(f'VPN: {s.get("phase", "UNKNOWN")} ({c["host"]}, {c["role"]})' + (' [STALE / unavailable]' if stale else ''))
    layers = {'AUTH_REJECTED': 'Hide.me authorization', 'HOST_OFFLINE': 'host uplink',
              'HOST_CONNECTIVITY_UNVERIFIED': 'host connectivity', 'NAMESPACE_UNAVAILABLE': 'namespace startup',
              'TAILSCALE_OFFLINE': 'Tailscale', 'GATEWAY_UNREACHABLE': 'gateway reachability',
              'WG_HANDSHAKE_STALE': 'WireGuard handshake', 'DNS_UNAVAILABLE': 'isolated DNS',
              'DEPLOYMENT_MISMATCH': 'active system generation'}
    print(f'Layer: {layers.get(s.get("reason"), "local VPN / egress")}')
    print(f'Reason: {s.get("reason", "UNKNOWN")} — {s.get("message", MESSAGES["UNKNOWN"][0])}')
    last_success = s.get('last_success', 0)
    success_age = f'{int(time.time()) - last_success}s ago' if last_success else 'never'
    print(f'Applications: {applications}; last successful check: {success_age}; status age: {age}s')
    print('Routing policy: fail-closed')
    host = s.get('details', {}).get('host', {})
    if host:
        print('Host probes: ' + '; '.join(f'{label} ' + ('passed' if 0 in host.get(key, {}).get('probes', []) else 'unverified')
                                        for key, label in (('ipv4', 'IPv4'), ('ipv6', 'IPv6'))))
    print(f'Recovery: attempts {s.get("attempts", 0)}/3; scheduler {s.get("recovery_scheduler", "unknown")}; next retry no earlier than {s.get("retry_at", 0)}')
    print(f'Next: {s.get("next_action", MESSAGES["UNKNOWN"][1])}')
    if verbose:
        print(json.dumps(s, sort_keys=True, indent=2))


def probe(c):
    results = []
    for family in ('-4', '-6'):
        for url in c['urls']:
            rc, _ = command('curl', '--noproxy', '*', '--fail', '--silent', family,
                            '--connect-timeout', '2', '--max-time', '5', '--output', '/dev/null', url, timeout=6)
            results.append(rc)
    now = int(time.time())
    runtime = Path(c['runtime'])
    snapshot = dict(checked_at=now, results=results)

    if c['role'] == 'gateway':
        # systemd has already entered /run/netns/vpn and mounted the private
        # resolver. Record only an exit code and boolean, never response data.
        rc, answer = command('dig', '+short', '+time=2', '+tries=1',
                             '@10.77.0.1', 'api.github.com', 'A', timeout=5)
        snapshot['relay_dns'] = dict(exit_code=rc, answered=bool(answer.strip()))

    save(runtime / 'probes.json', snapshot)

    # Preserve the original IPv4 readiness contract; IPv6-only success is degradation.
    if 0 in results[:len(c['urls'])]:
        tmp = runtime / 'ready.new'
        tmp.write_text(str(now) + '\n')
        tmp.replace(runtime / 'ready')
    else:
        sys.exit(1)


def main():
    c = read_json(sys.argv[1])
    mode = sys.argv[2]
    if mode == 'status':
        status(c, '--verbose' in sys.argv[3:], '--entry-failed' in sys.argv[3:])
        return
    if mode == 'probe':
        probe(c)
        return
    if os.geteuid() != 0:
        sys.exit('Recovery commands require root; vpn-status is read-only.')
    state = Path(c['state'])

    # ExecCondition must not wait on a lock held by the restarting monitor.
    if mode == 'provider-allowed':
        hold = read_json(state / 'hold.json')
        if hold and hold.get('credentials') == credentials(c):
            sys.exit(1)
        _, route = command('ip', '-4', 'route', 'show', 'table', 'main', 'default')
        sys.exit(0 if 'via 10.0.2.2 dev tap0' in route else 1)

    state.mkdir(parents=True, exist_ok=True, mode=0o755)
    if mode in ('lifecycle-start', 'lifecycle-stop'):
        lifecycle(c, sys.argv[3], mode.split('-')[1])
        return

    # Serialize timer and manual resets.
    with (state / 'lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)

        if mode == 'reconcile':
            reconcile(c)
        elif mode == 'reset':
            (state / 'hold.json').unlink(missing_ok=True)
            old = read_json(state / 'status.json')
            old.update(attempts=0, retry_at=0, failures=0)
            save(state / 'status.json', old)
            print('Recovery budget reset. Start deliberately stopped units explicitly; isolation remains enforced.')
        else:
            sys.exit('Unknown operation')


if __name__ == '__main__':
    main()
