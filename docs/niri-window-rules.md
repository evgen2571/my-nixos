# Niri application window rules: R05 observations

Issue [#24](https://github.com/evgen2571/my-nixos/issues/24) is **partially implemented**. Dedicated owners exist under `config/niri/sub/rules/apps/`; missing auxiliary metadata remains a prerequisite for completing the behavior changes.

## Before-edit observations

Initial read-only `niri msg --json windows` / `workspaces` on the PC session, 2026-10-17, Niri 26.04, found only Zen and Orca. The user subsequently supplied the following observations before the corresponding behavior edits; read-only IPC confirmed their app IDs, workspace IDs and floating state. Private chat/page titles are omitted. Workspace names resolve from the same PC session.

| Application / window | app_id | title | Workspace | State |
| --- | --- | --- | --- | --- |
| Zen main | `zen-beta` | Issue #24 page, ending `— Zen Browser` | `browser` | non-floating, 2560×1416 |
| Telegram main | `org.telegram.desktop` | private chat title omitted | `chats` | non-floating, 2560×1416 |
| Telegram media | `org.telegram.desktop` | `Media viewer` | `chats` | non-floating, 2560×1440 |
| Steam main | `steam` | `Steam` | `gaming` | non-floating, 2560×1416 |
| Steam utilities | `steam` | `Friends List`, `Steam Settings` | `gaming` | floating, 1228×920 |
| Steam offers | `steam` | `Special Offers` | `gaming` | non-floating, 2560×1416 |
| Prism main | `org.prismlauncher.PrismLauncher` | `Prism Launcher 11.1.1` | `music` | non-floating, 2560×1416 |
| Prism instance creation | `org.prismlauncher.PrismLauncher` | `New Instance — Prism Launcher 11.1.1` | `gaming` | non-floating, 2560×1416 |
| Prism settings | `org.prismlauncher.PrismLauncher` | `Settings — Prism Launcher 11.1.1` | `gaming` | non-floating, observed directly via IPC |
| Zen PiP | `zen-beta` | `Picture-in-Picture` | `browser` | floating, observed directly via IPC |
| OBS main | `com.obsproject.Studio` | `OBS 32.1.2 - Profile: Untitled - Scenes: Untitled` | `anki` | non-floating, 2560×1416 |
| OBS settings | `com.obsproject.Studio` | `Settings` | `gaming` | non-floating, 2560×1416 |
| Vesktop main / popouts; other requested auxiliaries | unavailable | unavailable | unavailable | not observed |

IPC does not report fullscreen/maximized flags here; window dimensions alone cannot prove them. The differing parent/child workspaces demonstrate the routing problem but do not establish why the parent was moved. Listed auxiliaries are separate compositor windows; whether unobserved UIs are independent windows remains unknown. No applications were launched or manipulated by the agent. Further targeted observations have been requested; titles/localizations must not be guessed.

## Policy changes and remaining work

| Owner | Before → after | Remaining observations / verification |
| --- | --- | --- |
| `telegram.kdl` | Media viewer excluded from chats maximization/routing; centered, focused 0.80×0.80 floating viewer with initial fullscreen disabled | Check actual opening and later fullscreen requests, closing/focus return, and other auxiliaries |
| `steam.kdl` | Existing utility titles plus observed Special Offers excluded from gaming routing; floating width 0.48 → 0.58, height 0.65 retained | Settings/Friends/Offers metadata confirmed; inherited `Chat`, `Properties`, `Downloads` titles remain unverified; game properties/localized titles, media and other utilities still need observations |
| `prism.kdl` | Observed versioned New Instance and Settings dialogs excluded from gaming maximization/routing; focused 0.60×0.70 floating | Identify Edit Instance, Accounts, standalone logs/progress; distinguish panels from windows; version suffix/localization variants remain unmatched |
| `vesktop.kdl` | Existing chats maximization moved unchanged; Discord/Slack stay in simple rules | Identify independent call/video/media windows; preserve deliberate fullscreen |
| `zen.kdl` | Existing browser routing, blur and PiP exclusion moved unchanged; other browsers stay in simple rules | PiP metadata/floating confirmed; observe true independent auth/extension popups; preserve ordinary new windows |
| `obs.kdl` | Observed Settings excluded from gaming maximization/routing; focused 0.60×0.75 floating | Identify filters/properties and other secondary windows; distinguish windowed/fullscreen projectors without app-wide fullscreen suppression |

Auxiliary rules use default centering, proportional sizing and no workspace/output target. Only Telegram's media viewer overrides initial fullscreen; deliberate video/projector/game fullscreen remains unrestricted. Unknown auxiliary titles still inherit main policies until observed. The ownership split alone does **not** complete all auxiliary-window requirements.

Anki and Obsidian rules are unchanged. Prism and OBS includes retain their previous position relative to the existing Anki title-based rules, whose separate match lines also match non-Anki titles; do not reorder them casually. Other application policies, workspace topology, generated themes and app data are unchanged.

No activation or runtime testing of the edited rules was performed. Before completing #24, verify all six apps on PC/laptop, including opening children after moving the parent, focus return, resizing, multiple outputs, and deliberate fullscreen. `open-fullscreen false` controls initial opening only; later client fullscreen requests need runtime verification. Do not close the issue based on static validation.
