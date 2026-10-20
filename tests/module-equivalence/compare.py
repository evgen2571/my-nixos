#!/usr/bin/env python3
"""Strict public evidence capture and comparison. Private input overrides are forbidden."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

HERE = Path(__file__).resolve().parent


def normalize(value, root):
    if isinstance(value, str):
        return re.sub(re.escape(root) + r'(?=/|$|[\s"\x27])', '<repository>', value)
    if isinstance(value, list):
        return [normalize(item, root) for item in value]
    if isinstance(value, dict):
        return {normalize(key, root): normalize(item, root) for key, item in value.items()}
    return value


def mapped_profiles(profiles, mapping):
    return {profile: {scope: [mapping[path] for path in paths]
                      for scope, paths in scopes.items()} for profile, scopes in profiles.items()}


def evaluate(expression):
    return json.loads(subprocess.check_output(['nix', 'eval', '--json', '--impure', '--expr', expression]))


def capture(root, output):
    root = root.resolve()
    output.mkdir(parents=True, exist_ok=True, mode=0o700)
    flake = f'builtins.getFlake {json.dumps("path:" + str(root))}'
    source = evaluate(f'({flake}).outPath')
    catalog = evaluate(f'import {HERE / "catalog.nix"} {{ root = {root}; }}')
    hosts = evaluate(f'import {HERE / "hosts.nix"} {{ flake = {flake}; }}')
    # Hash all repository source bytes and executable bits, including assets read at build time.
    files = (subprocess.check_output(['git', '-C', str(root), 'ls-files', '-z']).decode().split('\0')
             if (root / '.git').exists() else
             [str(p.relative_to(root)) for p in root.rglob('*') if p.is_file()])
    sources = {name: {'sha256': hashlib.sha256((root / name).read_bytes()).hexdigest(),
                      'executable': bool((root / name).stat().st_mode & 0o111)}
               for name in sorted(filter(None, files)) if (root / name).is_file()}
    for name, value in [('catalog', catalog), ('hosts', normalize(hosts, source)), ('sources', sources)]:
        (output / f'{name}.json').write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')
    (output / 'metadata.json').write_text(json.dumps({'sourceRoot': source,
        'revision': subprocess.check_output(['git', '-C', str(root), 'rev-parse', 'HEAD']).decode().strip()
                    if (root / '.git').exists() else 'archive (verify separately)'}, indent=2) + '\n')


def compare(baseline, candidate, mapping_path, migrations_path=None):
    before = json.loads((baseline / 'catalog.json').read_text())['profiles']
    after = json.loads((candidate / 'catalog.json').read_text())['profiles']
    migrated_explicit = []
    if mapping_path:
        inventory = json.loads(mapping_path.read_text())
        mapping = {entry['path']: entry['target'] for entry in inventory['entries']}
        if migrations_path:
            migrations = json.loads(migrations_path.read_text())
            migrated = migrations['entries']
            migrated_explicit = migrations.get('explicit', [])
            if set(migrated_explicit) - inventory.get('explicit', {}).keys():
                raise SystemExit('FAIL: unknown explicit migration entry')
            if set(migrated) - mapping.keys():
                raise SystemExit('FAIL: unknown migration entry')
            mapping = {path: target if path in migrated else path for path, target in mapping.items()}
        before = mapped_profiles(before, mapping)
        if not migrations_path:
            migrated_explicit = list(inventory.get('explicit', {}))
    if before != after:
        raise SystemExit('FAIL: ordered catalog scope/profile inventories differ')
    before_hosts = json.loads((baseline / 'hosts.json').read_text())
    after_hosts = json.loads((candidate / 'hosts.json').read_text())
    if 'home/default.nix' in migrated_explicit:
        old = '<repository>/home/default.nix'
        new = '<repository>/' + inventory['explicit']['home/default.nix']
        # Only these two fields describe the relocated module; commands and store paths stay strict.
        for host in before_hosts.values():
            if host['homeWiring']['module'] == old:
                host['homeWiring']['module'] = new
            option = host['options']['primaryUser']['home']['module']
            if option['default'] == old:
                option['default'] = new
    if before_hosts != after_hosts:
        raise SystemExit('FAIL: host evidence differs; diff hosts.json and investigate every change')
    print('PASS: ordered catalog inventories and all three host/Home Manager projections match')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    cap = commands.add_parser('capture')
    cap.add_argument('root', type=Path)
    cap.add_argument('output', type=Path)
    comp = commands.add_parser('compare')
    comp.add_argument('baseline', type=Path)
    comp.add_argument('candidate', type=Path)
    comp.add_argument('--mapping', type=Path)
    comp.add_argument('--migrations', type=Path, help='Explicit subset of inventory entries already moved')
    args = parser.parse_args()
    if args.command == 'capture':
        capture(args.root, args.output)
    else:
        if args.migrations and not args.mapping:
            parser.error('--migrations requires --mapping')
        compare(args.baseline, args.candidate, args.mapping, args.migrations)


if __name__ == '__main__':
    main()
