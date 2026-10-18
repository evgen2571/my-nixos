#!/usr/bin/env python3
"""Check local age recipient policy against ciphertext metadata, without decrypting."""

import re
import sys
from pathlib import Path
import yaml


def check(ciphertext, policy, host):
    document = yaml.safe_load(Path(ciphertext).read_text())
    rules = yaml.safe_load(Path(policy).read_text())["creation_rules"]
    rule = next(
        r
        for r in rules
        if re.search(r.get("path_regex", ".*"), f"secrets/hosts/{host}.yaml")
    )
    recipients = set()
    if "age" in rule:
        recipients.update(v.strip() for v in rule["age"].split(",") if v.strip())
    for group in rule.get("key_groups", []):
        recipients.update(group.get("age", []))
    actual = {entry["recipient"] for entry in document["sops"]["age"]}
    if not recipients or actual != recipients:
        raise ValueError("recipient mismatch")


if __name__ == "__main__":
    try:
        check(*sys.argv[1:])
    except (
        ValueError,
        KeyError,
        TypeError,
        AttributeError,
        StopIteration,
        OSError,
        yaml.YAMLError,
        re.error,
    ):
        sys.exit(
            "Local SOPS recipient policy is invalid, unmatched or differs from selected ciphertext; review .sops.yaml and rekey intentionally."
        )
