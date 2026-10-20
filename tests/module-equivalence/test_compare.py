import importlib.util
from pathlib import Path
import unittest
import tempfile
import json
import sys
sys.dont_write_bytecode = True

spec = importlib.util.spec_from_file_location('compare', Path(__file__).with_name('compare.py'))
compare = importlib.util.module_from_spec(spec)
spec.loader.exec_module(compare)


class EquivalenceTests(unittest.TestCase):
    def test_only_exact_repository_root_is_normalized(self):
        value = {'command': '/nix/store/abc-source/config/fish /nix/store/other-tool/bin/tool --flag'}
        self.assertEqual(compare.normalize(value, '/nix/store/abc-source'), {
            'command': '<repository>/config/fish /nix/store/other-tool/bin/tool --flag'})
        self.assertNotEqual(compare.normalize(value, '/nix/store/abc'), {
            'command': '<repository>-source/config/fish /nix/store/other-tool/bin/tool --flag'})

    def test_order_permissions_commands_and_disabled_options_are_significant(self):
        baseline = {'modules': ['a', 'b'], 'mode': '0400', 'command': 'tool --safe', 'disabled': False}
        for changed in [dict(baseline, modules=['b', 'a']), dict(baseline, mode='0444'),
                        dict(baseline, command='tool'), {k: v for k, v in baseline.items() if k != 'disabled'}]:
            self.assertNotEqual(compare.normalize(baseline, '/source'), compare.normalize(changed, '/source'))

    def test_comparator_rejects_changed_evidence(self):
        with tempfile.TemporaryDirectory() as temporary:
            baseline, candidate = [Path(temporary) / name for name in ['baseline', 'candidate']]
            for directory in [baseline, candidate]:
                directory.mkdir()
                (directory / 'catalog.json').write_text(json.dumps({'profiles': {
                    'desktop': {'home': ['a', 'b'], 'system': []}}}))
                (directory / 'hosts.json').write_text(json.dumps({
                    'mode': '0400', 'command': 'tool --safe', 'disabled': False}))
            compare.compare(baseline, candidate, None)
            for changed in [{'mode': '0444', 'command': 'tool --safe', 'disabled': False},
                            {'mode': '0400', 'command': 'tool', 'disabled': False},
                            {'mode': '0400', 'command': 'tool --safe'}]:
                (candidate / 'hosts.json').write_text(json.dumps(changed))
                with self.assertRaisesRegex(SystemExit, 'host evidence differs'):
                    compare.compare(baseline, candidate, None)
            (candidate / 'hosts.json').write_bytes((baseline / 'hosts.json').read_bytes())
            (candidate / 'catalog.json').write_text(json.dumps({'profiles': {
                'desktop': {'home': ['b', 'a'], 'system': []}}}))
            with self.assertRaisesRegex(SystemExit, 'ordered catalog'):
                compare.compare(baseline, candidate, None)

    def test_partial_migration_keeps_unmigrated_slots(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            baseline, candidate = root / 'baseline', root / 'candidate'
            for directory, paths in [(baseline, ['old-a', 'old-b']),
                                     (candidate, ['new-a', 'old-b'])]:
                directory.mkdir()
                (directory / 'catalog.json').write_text(json.dumps({'profiles': {
                    'desktop': {'home': paths, 'system': []}}}))
                (directory / 'hosts.json').write_text('{}')
            mapping = root / 'inventory.json'
            mapping.write_text(json.dumps({'entries': [
                {'path': 'old-a', 'target': 'new-a'},
                {'path': 'old-b', 'target': 'new-b'}]}))
            migrations = root / 'migrations.json'
            migrations.write_text(json.dumps({'entries': ['old-a']}))
            compare.compare(baseline, candidate, mapping, migrations)
            migrations.write_text(json.dumps({'entries': ['old-a'], 'explicit': ['unknown']}))
            with self.assertRaisesRegex(SystemExit, 'unknown explicit migration'):
                compare.compare(baseline, candidate, mapping, migrations)
            migrations.write_text(json.dumps({'entries': ['old-a', 'unknown']}))
            with self.assertRaisesRegex(SystemExit, 'unknown migration'):
                compare.compare(baseline, candidate, mapping, migrations)
            migrations.write_text(json.dumps({'entries': ['old-a']}))
            (candidate / 'catalog.json').write_text(json.dumps({'profiles': {
                'desktop': {'home': ['old-b', 'new-a'], 'system': []}}}))
            with self.assertRaisesRegex(SystemExit, 'ordered catalog'):
                compare.compare(baseline, candidate, mapping, migrations)

    def test_only_declared_home_module_references_are_relocated(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            baseline, candidate = root / 'baseline', root / 'candidate'
            old, new = '<repository>/home/default.nix', '<repository>/modules/core/primary-user.home.nix'
            for directory, module in [(baseline, old), (candidate, new)]:
                directory.mkdir()
                (directory / 'catalog.json').write_text(json.dumps({'profiles': {}}))
                (directory / 'hosts.json').write_text(json.dumps({'host': {
                    'homeWiring': {'module': module},
                    'options': {'primaryUser': {'home': {'module': {'default': module}}}},
                    'command': old}}))
            mapping = root / 'inventory.json'
            mapping.write_text(json.dumps({'entries': [], 'explicit': {
                'home/default.nix': 'modules/core/primary-user.home.nix'}}))
            migrations = root / 'migrations.json'
            migrations.write_text(json.dumps({'entries': [], 'explicit': ['home/default.nix']}))
            compare.compare(baseline, candidate, mapping, migrations)
            changed = json.loads((candidate / 'hosts.json').read_text())
            changed['host']['command'] = new
            (candidate / 'hosts.json').write_text(json.dumps(changed))
            with self.assertRaisesRegex(SystemExit, 'host evidence differs'):
                compare.compare(baseline, candidate, mapping, migrations)

    def test_catalog_mapping_preserves_order_and_scope(self):
        baseline = {'desktop': {'home': ['old-a', 'old-b'], 'system': []}}
        mapping = {'old-a': 'new-a', 'old-b': 'new-b'}
        self.assertEqual(compare.mapped_profiles(baseline, mapping), {
            'desktop': {'home': ['new-a', 'new-b'], 'system': []}})
        with self.assertRaises(KeyError):
            compare.mapped_profiles(baseline, {'old-a': 'new-a'})


if __name__ == '__main__':
    unittest.main()
