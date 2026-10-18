# Competitive programming

Choose `cp` in sesh (`Ctrl-O` in tmux), or run `sesh connect cp`. The session opens
Neovim in `~/dev/cp` plus a terminal. It starts CompetiTest's single-problem
receiver on `127.0.0.1:27121`; only one editor can own that port.

Install [Competitive Companion](https://addons.mozilla.org/en-US/firefox/addon/competitive-companion/)
in Zen, pin its plus button, and allow the requested website/local-network access.
Port 27121 is in Companion's default list; include it if overriding ports.

| Keys | Action |
| --- | --- |
| F6 | Save, compile and run all testcases for C++ under `~/dev/cp` |
| `Space c p i` | Receive one problem |
| `Space c p c` | Receive a contest batch |
| `Space c p a` / `Space c p e` | Add / edit a testcase |

The receiver stops after an import. Arm it again before sending the next problem;
for contests, use `Space c p c` before clicking Companion on the problems page.
Check `:CompetiTest receive status` or stop with `:CompetiTest receive stop`.

## Files and testcase results

Keep your existing `~/dev/cp/cf-template.cpp` on each machine. It is personal
workspace data, copied unchanged into new solutions. Codeforces contest,
problemset and Gym URLs map to `~/dev/cp/codeforces/<contest-id>/<index>.cpp`;
other judges use sanitized names. Samples live in the contest's `tests/`
directory. Decline overwrite confirmation to preserve an existing solution.

F6 invokes `g++ -std=c++20 -O2 -Wall -Wextra`. Binaries live in Neovim's cache,
with mirrored paths to avoid contest collisions. There is no CMake generation;
F5 keeps its debugger behavior. F6 is scoped to CP C++ buffers.

The runner displays compilation status, verdicts, timings and outputs. Select a
case, then use `i`/`a`/`o`/`e` for input/expected/actual/errors, `d` for diff, and
`q` to close. Press F6 after source edits; `R`/`Ctrl-R` reruns selected/all cases
with the existing binary. Whitespace differences are ignored. Cases run
sequentially with a five-second limit. A project `.competitest.lua` can return
`{ maximum_time = 2000 }` for a two-second limit.

In the testcase editor, Ctrl-H/Ctrl-L switches between input and expected output;
Ctrl-S saves and closes. Normal-mode `q` cancels. Empty expected output produces
an input-only test marked DONE; inspect stdout yourself.

## Troubleshooting and checks

Launch Zen and CP Neovim on the same network namespace. Ordinary Kitty/sesh and
Zen use host networking; a VPN agent's child editor has a separate localhost.
Use ordinary Kitty for this workflow. Check `ss -ltn 'sport = :27121'` in the
relevant namespace or compare `/proc/<pid>/ns/net` for the browser and editor.
No firewall, forwarding or VPN changes are needed for the normal workflow.

Configuration lives in [competitest.lua](../../config/nvim/lua/plugins/competitest.lua)
and [sesh](../../config/sesh). The integration test is
[tests/neovim/competitive.py](../../tests/neovim/competitive.py): it needs the
Nix Python provider with pynvim, isolated XDG roots, installed locked plugins,
the personal template, and a free port 27121. Inspect it before running.

The real Zen extension click and browser-to-editor connection remain manual
checks. Import a sample problem, run correct and incorrect solutions, test a
contest batch, edit a testcase, and reimport while declining overwrite.
