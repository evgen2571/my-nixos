# Neovim workflow validation

Run locally on 2026-10-12 with installed Neovim **0.12.4**. Tests used a separate
XDG configuration, data, cache and state tree, a temporary uv project, and the
actual Nix-built Python provider. Existing deployed configuration/theme and the
active tmux server were not changed. All configured plugins installed in the final test tree
matched `lazy-lock.json` after `:Lazy restore`.

| Check | Result |
| --- | --- |
| PC and laptop `system.build.toplevel.drvPath` evaluation | Passed |
| `nix flake check --no-build` | Passed, including PC, laptop and server |
| Nix Python provider build/imports | Passed: pynvim, jupyter-client, Pillow, CairoSVG |
| Headless startup and committed smoke script | Passed |
| Tree-sitter installation | All 20 configured parsers installed in the isolated tree |
| Python highlighting and textobjects | Active highlighter, parsed syntax tree, function/class queries, actual `daf` deletion passed |
| Python LSP and formatting | Pyright and Ruff attached to project; Pyright used `.venv/bin/python`; Ruff formatting ran |
| Python diagnostics | Live Ruff lint and Pyright type diagnostics checked separately from settings assertions |
| C++ and Python DAP | Real Python launch stopped on entry; C++ terminal launch stopped at a breakpoint, continued and exited |
| Neotest pytest | Discovered and passed the temporary project's `test_square` |
| GoogleTest | Adapter setup, filename recognition and LLDB registration passed; no GoogleTest binary executed |
| Molten | Project kernelspec registration, kernel startup, cell output `42`, next cell output `43` using shared state, restart and deinitialization passed |
| Jupytext (1.19.6 in temporary uv environment) | Pair/edit/sync round trip retained notebook metadata, cell tags, outputs and execution counts |
| Missing kernel | Cell execution warned without crashing |
| Missing/malformed Matugen | Fallback worked; three successive SIGUSR1 reloads recovered after a theme was created |
| Missing Ollama | Manual request to an unavailable localhost endpoint returned a connection warning; automatic inference stayed off |
| AI toggle | Enabled/disabled per buffer without making inference requests |
| Graphics fallback | Headless graphics detection returned false; text output remained usable |

A combined early debugger harness once timed out awaiting a termination event.
The final verification used separate editor instances, actual launch configurations,
and allowed DAP's stop/UI handling to complete before continuing. The LLDB terminal
reverse request also exposed a relative-executable problem: `lldb-dap` tried to
launch a nonexistent project-local helper. LLDB registrations now resolve an
absolute executable path, preserving the existing interactive-terminal workflow.
The terminal test then exposed a resize signal stop (`SIGWINCH`); C++ and CMake
pass that signal through via LLDB post-launch commands. The final C++ terminal
session stopped only at its actual breakpoint and exited after continuing.
Molten tests initially exposed lost startup output, missing runtime directories,
and remote-command lazy-loading conflicts; these were fixed and retested.

Three warm headless startup samples with restored pins measured a median of
**151 ms** for the updated config versus **262 ms** for the original config.
Both used the same installed plugin tree. These measurements are local and noisy
(other runtime checks were active); they establish no observed startup regression,
not a performance guarantee. Expensive LSP, DAP, testing and AI functionality is
absent from empty-editor startup. Tree-sitter remains eager as required upstream;
parser downloading/compiling is a first-install cost.

## Desktop checks still required

- Deploy normally; open a new shell, run `:Lazy restore`, wait for parsers,
  `:UpdateRemotePlugins`, restart the editor. Regenerate Noctalia's palette once
  before opening the editor to replace the old template's signal watcher.
- In Kitty, test a Matplotlib plot after `%matplotlib inline`, both directly and
  through tmux after reloading its config. The current tmux server had passthrough
  **off**; declarative config now sets it **on**. Pixel rendering was not tested
  through a real terminal. Try `NVIM_RESEARCH_IMAGES=0` for the text fallback.
- Check visual selection execution, output-window focus and Ctrl-Y with both Blink
  and Minuet suggestions. These interactive UI paths were configured/reviewed,
  but not driven through a desktop session.
- Debug a real CMake target and Rust runnable; associate/run your GoogleTest
  executable with `:ConfigureGtest`. Go/Delve, Java, Unity and Godot runtime sessions
  were not run. Their existing integrations remain, with Rust explicitly using LLDB.
- Launch project JupyterLab/MLflow and inspect actual DataFrames/widgets. Neither
  service was started or installed globally during testing.
- Verify Noctalia's real generated palette visually and compare laptop behavior;
  tests evaluated both hosts but ran Neovim on the current host only.

Nix evaluation checks do not replace a full NixOS build or desktop deployment;
neither was performed. Native libraries needed by scientific wheels remain a
project/dev-shell concern on NixOS; the configuration does not add a global ML stack.
