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
    def evaluate(self, files, error=None):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name in files:
                path = root / name
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text('{}')
            expression = f'''let
              catalog = import {CATALOG} {{ root = {root}; }};
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

    def test_obsolete_roots_are_not_discovered(self):
        entries = json.loads((CATALOG.parent.parent /
            'docs/refactor/inventory.json').read_text())['entries']
        files = [entry['target'] for entry in entries]
        result = self.evaluate(files + [
            'modules/desktops/old.nixos.nix',
            'modules/system-services/old.nixos.nix',
            'modules/system-apps/old.nixos.nix',
            'modules/system-dev/old.nixos.nix',
            'modules/system-files/old.nixos.nix',
            'modules/user-ai/old.home.nix', 'modules/user-apps/old.home.nix',
            'modules/user-desktop/old.home.nix', 'modules/user-dev/old.home.nix',
            'modules/user-files/old.home.nix',
        ])
        for profile in result.values():
            for paths in profile.values():
                self.assertTrue(set(paths) <= set(files), paths)

    def test_helpers_and_explicit_infrastructure_are_excluded(self):
        result = self.evaluate(['modules/core/primary-user.home.nix',
                                'modules/core/secrets.nixos.nix',
                                'modules/deployment/nixos.nix',
                                'modules/system-core/common.nix', 'modules/secrets.nix',
                                'modules/hardware/config.nix', 'modules/server/helper.nix',
                                'modules/dev/config.nix', 'modules/dev/asset.txt'])
        self.assertEqual(result, {name: {'system': [], 'home': []}
                                  for name in ['desktop', 'server']})

    def test_invalid_scope_diagnostics(self):
        for path, scope in [('modules/server/wrong.home.nix', 'home'),
                            ('modules/hardware/wrong.home.nix', 'home'),
                            ('modules/services/wrong.home.nix', 'home'),
                            ('modules/ai/wrong.nixos.nix', 'system')]:
            with self.subTest(path=path):
                self.evaluate([path], error=f'wrong scope {scope} for {path}')

    def test_existing_order_precedes_new_automatically_discovered_features(self):
        result = self.evaluate(['modules/dev/fish/nixos.nix',
                                'modules/apps/steam.nixos.nix',
                                'modules/apps/aaa.nixos.nix',
                                'modules/dev/aaa.nixos.nix',
                                'modules/dev/fish/home.nix'])
        self.assertEqual(result['desktop']['system'], [
            'modules/apps/steam.nixos.nix', 'modules/dev/fish/nixos.nix',
            'modules/apps/aaa.nixos.nix', 'modules/dev/aaa.nixos.nix'])
        self.assertEqual(result['server']['system'], [])
        self.assertEqual(result['server']['home'], ['modules/dev/fish/home.nix'])

    def test_complete_typed_inventory_preserves_all_four_ordered_profiles(self):
        repository = CATALOG.parent.parent
        entries = json.loads((repository / 'docs/refactor/inventory.json').read_text())['entries']
        baseline = json.loads((repository /
            'tests/module-equivalence/catalog-baseline.json').read_text())['profiles']
        mapping = {entry['path']: entry['target'] for entry in entries}
        result = self.evaluate([entry['target'] for entry in entries])
        self.assertEqual(result, {profile: {scope: [mapping[path] for path in paths]
            for scope, paths in scopes.items()} for profile, scopes in baseline.items()})


if __name__ == '__main__':
    unittest.main()
