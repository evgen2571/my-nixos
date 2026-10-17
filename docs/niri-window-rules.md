# Niri application window rules: R05 observations

Issue [#24](https://github.com/evgen2571/my-nixos/issues/24) is **partially implemented**. Dedicated owners exist under `config/niri/sub/rules/apps/`; exact auxiliary metadata remains a prerequisite for completing the behavior changes.

## Before-edit observations

Read-only `niri msg --json windows` / `workspaces` on the PC session, 2026-10-17, Niri 26.04:

| Application / window | app_id | title | Workspace | State |
| --- | --- | --- | --- | --- |
| Zen main | `zen-beta` | Issue #24 page, ending `— Zen Browser` | `browser` (DP-1) | non-floating, 2560×1416; IPC does not report fullscreen/maximized flags |
| Telegram main / media / auxiliary | unavailable | unavailable | unavailable | not open |
| Steam main / settings / properties / friends / viewers | unavailable | unavailable | unavailable | not open |
| Prism main / editor / settings / accounts / logs / progress | unavailable | unavailable | unavailable | not open |
| Vesktop main / call popout / media | unavailable | unavailable | unavailable | not open |
| OBS main / settings / filters / properties / projectors | unavailable | unavailable | unavailable | not open |
| Zen PiP / auth / extension / utility popup | unavailable | unavailable | unavailable | not open |

No applications were launched or manipulated for this inspection. Whether auxiliary UIs are independent compositor windows is unverified. Targeted observations have been requested; titles/localizations must not be guessed.

## Policy changes and remaining work

| Owner | Before → after | Remaining observations / verification |
| --- | --- | --- |
| `telegram.kdl` | Existing chats maximization moved unchanged | Identify main versus media viewer and other auxiliaries; verify initial/later fullscreen requests before implementing the 0.80×0.80 viewer policy |
| `steam.kdl` | Existing utility titles excluded from main gaming routing; floating width 0.48 → 0.58, height 0.65 retained | Existing `Steam Settings`, `Friends List`, `Chat`, `Properties`, `Downloads` titles are inherited, **not runtime-verified**; properties/localized titles, media and other utilities still need observations |
| `prism.kdl` | Launcher maximization/gaming routing moved unchanged; games retain independent global rules | Identify Edit Instance, Settings, Accounts, standalone logs/progress; distinguish panels from windows |
| `vesktop.kdl` | Existing chats maximization moved unchanged; Discord/Slack stay in simple rules | Identify independent call/video/media windows; preserve deliberate fullscreen |
| `zen.kdl` | Existing browser routing, blur and PiP exclusion moved unchanged; other browsers stay in simple rules | Observe PiP and true independent auth/extension popups; preserve ordinary new windows |
| `obs.kdl` | Existing gaming maximization moved unchanged | Identify main and true secondary windows; distinguish windowed/fullscreen projectors without app-wide fullscreen suppression |

Steam utility rules use default centering, proportional sizing, no workspace/output target and no fullscreen override. They do not float all `steamwebhelper` windows. Unknown Steam utility titles still inherit the main policy until observed. Other apps' broad policies remain deliberately unchanged pending metadata; the ownership split alone does **not** complete their auxiliary-window requirements.

Anki, Obsidian, other application policies, workspace topology, generated themes and app data are unchanged. No activation or runtime behavior testing was performed. Before completing #24, verify all six apps on PC/laptop, including opening children after moving the parent, focus return, resizing, multiple outputs, and deliberate fullscreen. Do not close the issue based on static validation.
