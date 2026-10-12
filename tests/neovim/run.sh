#!/usr/bin/env bash
set -euo pipefail
# Use a separate XDG_CONFIG_HOME containing a copy of config/nvim to avoid live theme/state changes.
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
NVIM_RESEARCH_SMOKE="$repo_root/tests/neovim/smoke.lua" nvim --headless -c 'lua local ok, err = pcall(dofile, vim.env.NVIM_RESEARCH_SMOKE); if not ok then print(err); vim.cmd("cquit 1") end'
