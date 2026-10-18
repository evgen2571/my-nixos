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
| Vesktop startup (user-confirmed) | `vesktop` | `vesktop` | `chats` | non-floating, 300×350; present only in the first follow-up snapshot |
| Vesktop main | `vesktop` | `(83) Discord \| Friends`; channel/server title variants (names omitted) | `chats` | non-floating, 2560×1416 |
| Vesktop call popout | `vesktop` | `General` (channel title) | `chats` | non-floating, 2560×1416 |
| Telegram group chat | `org.telegram.desktop` | test group name inside directional wrappers, plus unread counter | `chats` | non-floating, 2560×1416 |
| Telegram group call | `org.telegram.desktop` | plain test group name (omitted) | `chats` | non-floating, 2560×1416; separate IDs across two openings |
| Other requested auxiliaries | unavailable | unavailable | unavailable | not observed |

Two follow-up user snapshots confirm Zen PiP at 768×424, floating and unfocused on `browser`, with the browser main window still open. Its size and bottom-right placement agree with the existing 0.30×0.30 PiP rule; these snapshots do not prove opening focus or workspace-switch behavior. Prism main is now on `chats` while Settings remains tiled at 2560×1416 on `gaming`, including a newly created Settings window ID in the second snapshot. The existing draft rule already matches this Settings title; the snapshots do not establish that the draft configuration was deployed.

In the first follow-up only one Vesktop window appears: title/app-id `vesktop`, tiled at 300×350 on `chats`; it disappears from the second listing. The user confirmed that this was a startup window, not a call/video popout. A later snapshot confirms the main client's `Discord | …` title shape and a separate channel-named call popout. The startup/static `vesktop` / `Vesktop` titles retain their original chats policy. OBS filters/properties/projectors and Prism Edit Instance/Accounts/logs are absent from these snapshots; absence alone does not establish that they are in-app panels.

The latest snapshots provide the main/call classification for both apps. Telegram's main chat title wraps the name with LRM + FSI/PDI Unicode markers; its group-call title is the plain group name. Vesktop main titles are `Discord` or `Discord | …` with an optional unread prefix; its call popout uses the plain channel name. The rules now route only matching main signatures to `chats`, floating other app windows at 0.60×0.70 without a workspace assignment. Telegram's media viewer retains its specialized 0.80×0.80 size and initial fullscreen override. Calls/popouts have no fullscreen suppression.

Source cross-checks: Telegram's [MainWindow::updateTitle](https://github.com/telegramdesktop/tdesktop/blob/b16daff6df63e8a812bc2b52a04ff243f67a7d3f/Telegram/SourceFiles/window/main_window.cpp#L887) wraps main chat/account names, while [direct calls](https://github.com/telegramdesktop/tdesktop/blob/b16daff6df63e8a812bc2b52a04ff243f67a7d3f/Telegram/SourceFiles/calls/calls_panel.cpp#L284) and [group calls](https://github.com/telegramdesktop/tdesktop/blob/b16daff6df63e8a812bc2b52a04ff243f67a7d3f/Telegram/SourceFiles/calls/group/calls_group_panel.cpp#L334) set plain peer/group titles. Vesktop's [popout creation](https://github.com/Vencord/Vesktop/blob/a02035be2083e09666ed250bd977325c35f5be95/src/main/utils/popout.ts#L35) starts with `Discord Popout` before the channel title, and its [static-title setting](https://github.com/Vencord/Vesktop/blob/a02035be2083e09666ed250bd977325c35f5be95/src/main/mainWindow.ts#L290) uses `Vesktop`. These upstream sources corroborate the observations; they do not establish runtime behavior of the edited rules.

Limits: titles are the available classification boundary, not window roles. A call/group/channel deliberately named like a main signature can collide; future client title formats may instead float a main window. Existing global title rules can also override workspace routing: titles beginning with Anki modal prefixes such as `Preferences`, `Browse` or `Sync` target `anki`, while titles containing lowercase `editor` target `code`. These interactions predate this change; Anki/global policy fixes remain outside this ticket. Initial title timing, Telegram direct-call metadata and alternative title settings remain untested; later title updates cannot repair opening-only placement rules. No literal group/server/contact names are configured. Run `python3 tests/niri/window-titles.py` for sanitized title regression cases, then `niri validate` on each complete host tree to check the patterns in Niri's regex parser. The Python test checks title classification and shared exclusions, not compositor placement/focus or fullscreen requests.

IPC does not report fullscreen/maximized flags here; window dimensions alone cannot prove them. The differing parent/child workspaces demonstrate the routing problem but do not establish why the parent was moved. Listed auxiliaries are separate compositor windows; whether unobserved UIs are independent windows remains unknown. No applications were launched or manipulated by the agent. Further targeted observations have been requested; titles/localizations must not be guessed.

## Policy changes and remaining work

| Owner | Before → after | Remaining observations / verification |
| --- | --- | --- |
| `telegram.kdl` | Only main title signatures route/maximize on chats; other windows, including the observed group call, float at 0.60×0.70; media remains 0.80×0.80 with initial fullscreen disabled | Verify direct calls, alternate title settings, actual opening/fullscreen requests, focus return and other auxiliaries |
| `steam.kdl` | Existing utility titles plus observed Special Offers excluded from gaming routing; floating width 0.48 → 0.58, height 0.65 retained | Settings/Friends/Offers metadata confirmed; inherited `Chat`, `Properties`, `Downloads` titles remain unverified; game properties/localized titles, media and other utilities still need observations |
| `prism.kdl` | Observed versioned New Instance and Settings dialogs excluded from gaming maximization/routing; focused 0.60×0.70 floating | Identify Edit Instance, Accounts, standalone logs/progress; distinguish panels from windows; version suffix/localization variants remain unmatched |
| `vesktop.kdl` | Main/startup/static title signatures retain chats maximization; observed channel-named popouts float at 0.60×0.70; Discord/Slack stay unchanged | Verify opening/resizing/focus, independent media windows, deliberate fullscreen and title variants |
| `zen.kdl` | Existing browser routing, blur and PiP exclusion moved unchanged; other browsers stay in simple rules | PiP metadata/floating confirmed; observe true independent auth/extension popups; preserve ordinary new windows |
| `obs.kdl` | Observed Settings excluded from gaming maximization/routing; focused 0.60×0.75 floating | Identify filters/properties and other secondary windows; distinguish windowed/fullscreen projectors without app-wide fullscreen suppression |

Auxiliary rules use default centering, proportional sizing and no workspace/output target. Only Telegram's media viewer overrides initial fullscreen; deliberate video/projector/game fullscreen remains unrestricted. Unclassified auxiliaries in Steam/Prism/Zen/OBS still inherit main policies until observed; Telegram/Vesktop now default to floating outside their main signatures. The ownership split alone does **not** complete all auxiliary-window requirements.

Anki and Obsidian rules are unchanged. Prism and OBS includes retain their previous position relative to the existing Anki title-based rules, whose separate match lines also match non-Anki titles; do not reorder them casually. Other application policies, workspace topology, generated themes and app data are unchanged.

No activation or runtime testing of the edited rules was performed. Before completing #24, verify all six apps on PC/laptop, including opening children after moving the parent, focus return, resizing, multiple outputs, and deliberate fullscreen. `open-fullscreen false` controls initial opening only; later client fullscreen requests need runtime verification. Do not close the issue based on static validation.
