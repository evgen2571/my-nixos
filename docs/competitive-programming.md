# Competitive programming

Enter the `cp` session from the usual sesh picker (`Ctrl-O` in tmux), or run
`sesh connect cp`. It opens Neovim in `~/dev/cp` and a `term` window; other
`~/dev/*` projects retain their existing terminal and remote agent windows.
Entering the CP workspace starts CompetiTest's single-problem receiver on
`127.0.0.1:27121`. Only one Neovim instance can own that port.

Your existing `~/dev/cp/cf-template.cpp` is copied unchanged. Keep this file
available on each machine; it is personal workspace data, not managed by Nix.
Ordinary contest, problemset and Gym URLs all produce
`~/dev/cp/codeforces/<contest-id>/<problem-index>.cpp`. Other judges use sanitized
judge/contest/problem names. Imports create directories, save samples under
`<contest-directory>/tests/`, and open the source. Existing source files require
CompetiTest's overwrite confirmation; choose **No** to preserve the solution.

| Key | Action |
| --- | --- |
| F6 | Save, compile and run every testcase (C++ buffers under `~/dev/cp` only) |
| `<leader>cpi` | Arm the receiver for one problem |
| `<leader>cpc` | Arm the receiver for a full contest batch |
| `<leader>cpa` | Add a custom testcase |
| `<leader>cpe` | Pick and edit a testcase |

The leader is Space. The receiver stops after each import; use `cpi` or `cpc`
before the next send. Switching modes stops the old receiver first. Check it with
`:CompetiTest receive status`, or stop it with `:CompetiTest receive stop`.
For a full contest, use `cpc`, then click Companion on the contest's problems page.

F6 invokes `g++ -std=c++20 -O2 -Wall -Wextra` directly. GCC is already declared
in the shared Neovim/C++ Home Manager modules used by PC and laptop; `nui.nvim`
is the plugin dependency, pinned along with CompetiTest in `lazy-lock.json`.
Binaries live under `stdpath('cache')/competitest`, with mirrored source paths to
avoid collisions between contests. No CMake generation is involved. F5 remains
the debugger binding, and F6 is not installed for ordinary C++, Python or Rust.

The runner shows compile status, testcase verdicts, elapsed time, input, expected
output, actual stdout and stderr. Compilation failures open the error viewer.
Select a testcase with the cursor; `i`/`a`/`o`/`e` enlarge input/expected/actual/errors,
`d` toggles output diff, and `q` closes a viewer or the runner. After editing a
solution, press F6 again to recompile. The runner's `R`/`Ctrl-R` rerun the selected/all
cases with the existing binary. Whitespace differences are ignored. Tests run
sequentially with a five-second limit per case; timeouts and nonzero exits/signals
are reported. For another limit, use a project `.competitest.lua` returning
`{ maximum_time = 2000 }` (milliseconds).

In the testcase editor, `Ctrl-h`/`Ctrl-l` switch between input and expected output;
`Ctrl-s` saves and closes, and `q` cancels in normal mode. Leave expected output
empty for an input-only test: it reports **DONE**, with stdout available to inspect.

## Zen Browser verification

1. Deploy the configuration normally, then use `:Lazy restore` to install the
   locked plugins. Open the `cp` session and check `:CompetiTest receive status`.
2. Install the Firefox [Competitive Companion add-on](https://addons.mozilla.org/en-US/firefox/addon/competitive-companion/)
   in Zen and pin its green plus button. Accept its requested website access;
   allow localhost/local-network access if Zen prompts. Port **27121** is already
   included in Companion's default ports; if using custom-port settings, include
   it. Localhost should bypass any browser proxy.
3. Open `https://codeforces.com/problemset/problem/4/A` and click the plus button.
   Confirm Neovim opens `~/dev/cp/codeforces/4/A.cpp`, using your template, with
   samples in `~/dev/cp/codeforces/4/tests/`. Implement a solution and press F6.
   Try an incorrect solution, then fix it and press F6 again.
4. Try `cpa`/`cpe`, then reimport the same problem with `cpi` and decline the
   overwrite. Try `cpc` on a contest problems page to receive every problem.

Zen and Neovim must use the same network namespace. Your configured Zen, Kitty
and tmux run on the host; VPN-wrapped Codex and its child processes use the VPN
namespace's separate localhost. Launch CP Neovim from ordinary Kitty/sesh, not
from a VPN agent shell. If connectivity fails, compare
`readlink /proc/<zen-pid>/ns/net` and `/proc/<nvim-pid>/ns/net` and check
`ss -ltn 'sport = :27121'` from their namespace. No VPN, firewall or forwarding
changes are needed for the normal host workflow.

References: [CompetiTest configuration and commands](https://github.com/xeluxee/competitest.nvim),
[Companion ports and protocol](https://github.com/jmerle/competitive-companion),
[sesh session configuration](https://github.com/joshmedeski/sesh).

## Local integration test

With an isolated `XDG_CONFIG_HOME` containing this repository's `config/nvim`,
installed locked plugins, and isolated cache/state, run
`$NVIM_PYTHON_PROVIDER tests/neovim/competitive.py` (the provider includes pynvim).
The test redirects the CP workspace to a temporary directory, copies the actual
personal template, sends representative HTTP payloads to port 27121, and drives
F6 and the testcase editor through Neovim RPC. Close another receiver first.

Validated on 2026-10-12: isolated full-config startup/Lazy loading; actual TCP
receiver; contest/problemset/Gym paths; full contest batch; fallback names;
byte-identical templates; sample files; overwrite refusal; F6 compilation and
reruns; correct/wrong/input-only results and timings; custom add/edit UI;
compilation diagnostics; runtime errors; timeouts; F6 scoping, symlinked workspace detection, CMake bindings and unchanged F5.
A separate tmux server verified sesh's CP Neovim/terminal windows and the ordinary
project's Neovim/terminal/agent windows (with a local stub for the remote agent).
The existing Neovim smoke suite and `nix flake check --no-build` also passed.
Tests ran in the agent's network namespace. The real Zen extension click and
host-to-host browser connection remain manual checks; no NixOS activation or
full system build was performed.
