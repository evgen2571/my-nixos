import importlib.util
from pathlib import Path
import unittest
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

    def test_catalog_mapping_preserves_order_and_scope(self):
        baseline = {'desktop': {'home': ['old-a', 'old-b'], 'system': []}}
        mapping = {'old-a': 'new-a', 'old-b': 'new-b'}
        self.assertEqual(compare.mapped_profiles(baseline, mapping), {
            'desktop': {'home': ['new-a', 'new-b'], 'system': []}})
        with self.assertRaises(KeyError):
            compare.mapped_profiles(baseline, {'old-a': 'new-a'})


if __name__ == '__main__':
    unittest.main()
