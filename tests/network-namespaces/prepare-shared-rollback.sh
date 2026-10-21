#!/usr/bin/env bash
# Compatibility entry point; keep the reviewed migration bundle together.
set -euo pipefail
exec bash "$(dirname -- "${BASH_SOURCE[0]}")/../../modules/services/network-namespaces/migration/prepare-rollback.sh" "$@"
