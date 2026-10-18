#!/usr/bin/env python3
"""Validate encrypted host data and optional local age recipient policy without decrypting."""

import re
import sys
from pathlib import Path
import yaml


def check(ciphertext, policy, host):
    document = yaml.safe_load(Path(ciphertext).read_text())
    encrypted = re.compile(
        r"ENC\[AES256_GCM,data:[^,]*,iv:[^,]+,tag:[^,]+,type:(str|int|float|bool)\]"
    )
    values = [value for key, value in document.items() if key != "sops"]
    if not values or any(
        not isinstance(value, str) or not encrypted.fullmatch(value) for value in values
    ):
        raise ValueError("host data must be encrypted SOPS scalars")
    metadata = document["sops"]
    age = metadata["age"]
    if not encrypted.fullmatch(metadata["mac"]) or not isinstance(age, list) or not age:
        raise ValueError("missing SOPS encryption metadata")
    for entry in age:
        if (
            not isinstance(entry, dict)
            or not isinstance(entry.get("recipient"), str)
            or not entry["recipient"].strip()
        ):
            raise ValueError("invalid age recipient metadata")
        wrapped = entry.get("enc")
        if (
            not isinstance(wrapped, str)
            or not wrapped.strip().startswith("-----BEGIN AGE ENCRYPTED FILE-----\n")
            or not wrapped.strip().endswith("\n-----END AGE ENCRYPTED FILE-----")
        ):
            raise ValueError("invalid encrypted age key metadata")
    if policy == "-":
        return
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
            "SOPS host source is malformed/unencrypted, or local recipient policy is invalid, unmatched or differs from ciphertext; review the selected source and policy."
        )
