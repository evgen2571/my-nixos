#!/usr/bin/env bash
set -euo pipefail
# Use a separate XDG_CONFIG_HOME containing a copy of config/nvim to avoid live theme/state changes.
repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)
NVIM_RESEARCH_SMOKE="$repo_root/tests/neovim/smoke.lua" nvim --headless -c 'lua vim.api.nvim_create_autocmd("VimEnter", { once = true, callback = function() vim.defer_fn(function() local ok, err = pcall(dofile, vim.env.NVIM_RESEARCH_SMOKE); if not ok then print(err); vim.cmd("cquit 1") end end, 0) end })'
