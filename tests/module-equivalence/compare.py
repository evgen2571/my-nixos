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


def compare(baseline, candidate, mapping_path):
    before = json.loads((baseline / 'catalog.json').read_text())['profiles']
    after = json.loads((candidate / 'catalog.json').read_text())['profiles']
    if mapping_path:
        inventory = json.loads(mapping_path.read_text())
        before = mapped_profiles(before, {entry['path']: entry['target'] for entry in inventory['entries']})
    if before != after:
        raise SystemExit('FAIL: ordered catalog scope/profile inventories differ')
    if (baseline / 'hosts.json').read_bytes() != (candidate / 'hosts.json').read_bytes():
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
    args = parser.parse_args()
    if args.command == 'capture':
        capture(args.root, args.output)
    else:
        compare(args.baseline, args.candidate, args.mapping)


if __name__ == '__main__':
    main()
