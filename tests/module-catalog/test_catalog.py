"""Directory fixtures exercise the catalog's ordered public profile outputs."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

CATALOG = Path(os.environ.get('MODULE_CATALOG',
    str(Path(__file__).resolve().parents[2] / 'lib/module-catalog.nix')))


class CatalogTests(unittest.TestCase):
    def evaluate(self, files, legacy=None, error=None):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in files:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text('{}')
            registrations = root / 'entries.json'
            registrations.write_text(json.dumps(legacy or []))
            expression = f'''let
              catalog = import {CATALOG} {{ root = {root};
                legacyEntries = builtins.fromJSON (builtins.readFile {registrations}); }};
              relative = p: builtins.substring {len(directory) + 1} (-1) (toString p);
            in builtins.mapAttrs (_: profile: {{
              system = map relative profile.systemModules;
              home = map relative profile.homeModules;
            }}) catalog.profiles'''
            result = subprocess.run(['nix', '--extra-experimental-features', 'nix-command', 'eval',
                                     '--store', 'dummy://', '--impure', '--json', '--expr', expression],
                                    capture_output=True, text=True)
            if error:
                self.assertNotEqual(result.returncode, 0)
                self.assertIn(error, result.stderr)
                return
            self.assertEqual(result.returncode, 0, result.stderr)
            return json.loads(result.stdout)

    def test_typed_forms_helpers_and_recursive_order(self):
        profiles = self.evaluate([
            'modules/dev/a.home.nix', 'modules/dev/b/home.nix',
            'modules/dev/b/nixos.nix', 'modules/dev/b/config.nix',
            'modules/dev/b/default.nix', 'modules/dev/b/nested/c.home.nix',
            'modules/dev/b/asset.sh', 'modules/dev/z.home.nix',
        ])
        self.assertEqual(profiles['desktop']['home'], [
            'modules/dev/a.home.nix', 'modules/dev/b/home.nix',
            'modules/dev/b/nested/c.home.nix', 'modules/dev/z.home.nix'])
        self.assertEqual(profiles['desktop']['system'], ['modules/dev/b/nixos.nix'])
        self.assertEqual(profiles['server']['home'], profiles['desktop']['home'])
        self.assertEqual(profiles['server']['system'], [])

    def registration(self, **changes):
        return dict(path='modules/system-dev/fish.nix',
                    target='modules/dev/fish/nixos.nix', scope='system',
                    profiles=['desktop'], relPath='/modules/system-dev', **changes)

    def test_legacy_and_migrated_entries_keep_frozen_order(self):
        entries = [self.registration(), dict(
            path='modules/system-dev/z.nix', target='modules/dev/a.nixos.nix',
            scope='system', profiles=['desktop'], relPath='/modules/system-dev')]
        result = self.evaluate(['modules/system-dev/fish.nix', 'modules/dev/a.nixos.nix',
                                'modules/dev/fish/home.nix'], entries)
        self.assertEqual(result['desktop']['system'], [
            'modules/system-dev/fish.nix', 'modules/dev/a.nixos.nix'])
        self.assertEqual(result['server']['system'], [])
        self.assertEqual(result['server']['home'], ['modules/dev/fish/home.nix'])
        migrated = self.evaluate(['modules/dev/fish/nixos.nix', 'modules/dev/a.nixos.nix'], entries)
        self.assertEqual(migrated['desktop']['system'], [
            'modules/dev/fish/nixos.nix', 'modules/dev/a.nixos.nix'])

    def test_legacy_default_stops_helpers_but_not_typed_siblings(self):
        entry = dict(path='modules/system-dev/old', target='modules/dev/old.nixos.nix',
                     scope='system', profiles=['desktop'], relPath='/modules/system-dev')
        result = self.evaluate(['modules/system-dev/old/default.nix',
                                'modules/system-dev/old/config.nix',
                                'modules/system-dev/old/sibling.nixos.nix'], [entry])
        self.assertEqual(result['desktop']['system'], [
            'modules/system-dev/old', 'modules/system-dev/old/sibling.nixos.nix'])

    def test_helpers_and_explicit_infrastructure_are_excluded(self):
        result = self.evaluate(['modules/core/primary-user.home.nix',
                                'modules/core/secrets.nixos.nix',
                                'modules/deployment/nixos.nix',
                                'modules/system-core/common.nix', 'modules/secrets.nix',
                                'modules/hardware/config.nix', 'modules/server/helper.nix',
                                'modules/dev/config.nix', 'modules/dev/asset.txt'])
        self.assertEqual(result, {name: {'system': [], 'home': []}
                                  for name in ['desktop', 'server']})

    def test_missing_duplicate_and_invalid_scope_diagnostics(self):
        entry = self.registration()
        self.evaluate([], [entry], error='missing expected entry: modules/system-dev/fish.nix')
        self.evaluate(['modules/system-dev/fish.nix', 'modules/dev/fish/nixos.nix'],
                      [entry], error='duplicate registration:')
        self.evaluate([], [entry, entry], error='duplicate legacy or target registration')
        invalid = entry | {'scope': 'other'}
        self.evaluate([], [invalid], error='invalid scope other')
        self.evaluate(['modules/server/wrong.home.nix'], error='wrong scope home for modules/server/wrong.home.nix')
        self.evaluate(['modules/dev/fish/home.nix'], [entry | {
            'target': 'modules/dev/fish/home.nix'}], error='typed scope/profile rules disagree')
        self.evaluate(['modules/system-dev/fish.nix'], [entry | {
            'profiles': ['server']}], error='invalid legacy scope/profile assignment')
        self.evaluate([], [entry | {'profiles': ['unknown']}], error='invalid profiles')

    def test_complete_typed_inventory_preserves_all_four_ordered_profiles(self):
        entries = json.loads((CATALOG.parent / 'module-compatibility.json').read_text())
        baseline = json.loads((CATALOG.parent.parent /
            'tests/module-equivalence/catalog-baseline.json').read_text())['profiles']
        mapping = {entry['path']: entry['target'] for entry in entries}
        result = self.evaluate([entry['target'] for entry in entries], entries)
        self.assertEqual(result, {profile: {scope: [mapping[path] for path in paths]
            for scope, paths in scopes.items()} for profile, scopes in baseline.items()})

    def test_compatibility_table_matches_approved_inventory(self):
        repository = CATALOG.parent.parent
        entries = json.loads((repository / 'docs/refactor/inventory.json').read_text())['entries']
        actual = json.loads((CATALOG.parent / 'module-compatibility.json').read_text())
        self.assertEqual(actual, [{key: entry[key] for key in
                                  ['path', 'target', 'scope', 'profiles', 'relPath']}
                                 for entry in entries])


if __name__ == '__main__':
    unittest.main()
