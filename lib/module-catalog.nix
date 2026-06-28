{ root }:
let
  inherit (builtins)
    attrNames
    elem
    filter
    foldl'
    head
    isAttrs
    listToAttrs
    map
    tail
    ;

  recursiveUpdate =
    lhs: rhs:
    lhs
    // listToAttrs (
      map (
        name:
        let
          lhsValue = lhs.${name} or null;
          rhsValue = rhs.${name};
        in
        {
          inherit name;
          value =
            if isAttrs lhsValue && isAttrs rhsValue then
              recursiveUpdate lhsValue rhsValue
            else
              rhsValue;
        }
      ) (attrNames rhs)
    );

  setAttrPath =
    attrPath: value:
    if attrPath == [ ] then
      value
    else
      {
        ${head attrPath} = setAttrPath (tail attrPath) value;
      };

  module =
    attrPath: path: scope: category: profiles: description:
    {
      inherit
        attrPath
        path
        scope
        category
        profiles
        description
        ;
    };

  systemModule = attrPath: relPath: category: profiles: description:
    module attrPath (root + relPath) "system" category profiles description;

  homeModule = attrPath: relPath: category: profiles: description:
    module attrPath (root + relPath) "home" category profiles description;

  entries = [
    # Host-base modules are imported directly by hosts/*/configuration.nix.
    (systemModule [ "system" "common" ] "/modules/system-core/common.nix" "core" [ ] "Shared desktop NixOS baseline.")
    (systemModule [ "system" "server" ] "/modules/system-core/server.nix" "core" [ ] "Shared server NixOS baseline.")
    (systemModule [ "system" "user" ] "/modules/system-core/user.nix" "core" [ ] "Primary-user and Home Manager wiring.")

    (systemModule [ "wm" "role" ] "/modules/desktops/role.nix" "desktop" [ "desktop" ] "Active desktop role and compositor invariants.")
    (systemModule [ "wm" "niri" ] "/modules/desktops/niri" "desktop" [ "desktop" ] "Niri compositor system integration.")
    (systemModule [ "wm" "cinnamon" ] "/modules/desktops/cinnamon" "desktop" [ "desktop" ] "Cinnamon desktop integration.")
    (systemModule [ "wm" "gnome" ] "/modules/desktops/gnome" "desktop" [ "desktop" ] "GNOME desktop integration.")
    (systemModule [ "wm" "hyprland" ] "/modules/desktops/hyprland" "desktop" [ "desktop" ] "Hyprland compositor system integration.")
    (systemModule [ "wm" "ly" ] "/modules/desktops/ly.nix" "desktop" [ "desktop" ] "Ly display manager.")
    (systemModule [ "wm" "opentabletdriver" ] "/modules/desktops/opentabletdriver.nix" "desktop" [ "desktop" ] "OpenTabletDriver desktop support.")
    (systemModule [ "wm" "xserver" ] "/modules/desktops/xserver.nix" "desktop" [ "desktop" ] "X server compatibility layer.")
    (systemModule [ "wm" "virtualization" ] "/modules/system-services/virtualization.nix" "desktop" [ "desktop" ] "Desktop virtualization services.")

    (systemModule [ "systemServices" "tailscale" ] "/modules/system-services/tailscale.nix" "service" [ "desktop" ] "Tailscale networking service.")
    (systemModule [ "systemServices" "blueman" ] "/modules/system-services/blueman.nix" "service" [ "desktop" ] "Blueman Bluetooth service UI support.")
    (systemModule [ "systemServices" "syncthing" ] "/modules/system-services/syncthing.nix" "service" [ "desktop" ] "Syncthing system service.")
    (systemModule [ "systemServices" "vpnbookWireguardFailover" ] "/modules/system-services/vpnbook-wireguard-failover.nix" "service" [ "server" ] "VPNBook WireGuard failover service.")

    (systemModule [ "hardware" "bluetooth" ] "/modules/hardware/bluetooth.nix" "hardware" [ "desktop" ] "Bluetooth hardware support.")
    (systemModule [ "hardware" "nvidia" ] "/modules/hardware/nvidia.nix" "hardware" [ "desktop" ] "NVIDIA graphics support.")
    (systemModule [ "hardware" "screenRecorder" ] "/modules/hardware/screen-recorder.nix" "hardware" [ "desktop" ] "Screen recording hardware/runtime support.")

    (systemModule [ "apps" "aagl" ] "/modules/system-apps/aagl.nix" "app" [ "desktop" ] "AAGL launcher system integration.")
    (systemModule [ "apps" "kdeConnect" ] "/modules/system-apps/kde-connect.nix" "app" [ "desktop" ] "KDE Connect system integration.")
    (systemModule [ "apps" "lutris" ] "/modules/system-apps/lutris.nix" "app" [ "desktop" ] "Lutris gaming support.")
    (systemModule [ "apps" "obs" ] "/modules/system-apps/obs.nix" "app" [ "desktop" ] "OBS Studio system integration.")
    (systemModule [ "apps" "steam" ] "/modules/system-apps/steam.nix" "app" [ "desktop" ] "Steam system integration.")
    (systemModule [ "apps" "vesktop" ] "/modules/system-apps/vesktop.nix" "app" [ "desktop" ] "Vesktop system integration.")

    (systemModule [ "coding" "docker" ] "/modules/system-dev/docker" "development" [ "desktop" ] "Docker development runtime.")
    (systemModule [ "coding" "fish" ] "/modules/system-dev/fish.nix" "development" [ "desktop" ] "Fish shell system integration.")

    (systemModule [ "fileManagers" "thunar" ] "/modules/system-files/thunar.nix" "files" [ "desktop" ] "Thunar file manager integration.")

    (systemModule [ "ai" "ollama" ] "/modules/system-services/ollama.nix" "ai" [ "desktop" ] "Ollama local model service.")

    (homeModule [ "user" "ai" "codex" ] "/modules/user-ai/codex.nix" "ai" [ "desktop" ] "Codex CLI user setup.")
    (homeModule [ "user" "ai" "llamaCpp" ] "/modules/user-ai/llama-cpp.nix" "ai" [ "desktop" ] "llama.cpp user setup.")
    (homeModule [ "user" "ai" "opencode" ] "/modules/user-ai/opencode.nix" "ai" [ "desktop" ] "OpenCode CLI user setup.")

    (homeModule [ "user" "apps" "anki" ] "/modules/user-apps/anki.nix" "app" [ "desktop" ] "Anki desktop app.")
    (homeModule [ "user" "apps" "bitwarden" ] "/modules/user-apps/bitwarden.nix" "app" [ "desktop" ] "Bitwarden desktop app.")
    (homeModule [ "user" "apps" "bruno" ] "/modules/user-apps/bruno.nix" "app" [ "desktop" ] "Bruno API client.")
    (homeModule [ "user" "apps" "chrome" ] "/modules/user-apps/chrome.nix" "app" [ "desktop" ] "Google Chrome browser.")
    (homeModule [ "user" "apps" "notion" ] "/modules/user-apps/notion.nix" "app" [ "desktop" ] "Notion desktop app.")
    (homeModule [ "user" "apps" "mpv" ] "/modules/user-apps/mpv.nix" "app" [ "desktop" ] "MPV media player.")
    (homeModule [ "user" "apps" "obsidian" ] "/modules/user-apps/obsidian.nix" "app" [ "desktop" ] "Obsidian notes app.")
    (homeModule [ "user" "apps" "osuLazer" ] "/modules/user-apps/osu-lazer.nix" "app" [ "desktop" ] "osu!lazer game client.")
    (homeModule [ "user" "apps" "prismLauncher" ] "/modules/user-apps/prism-launcher.nix" "app" [ "desktop" ] "Prism Launcher game client.")
    (homeModule [ "user" "apps" "slack" ] "/modules/user-apps/slack.nix" "app" [ "desktop" ] "Slack desktop app.")
    (homeModule [ "user" "apps" "telegram" ] "/modules/user-apps/telegram.nix" "app" [ "desktop" ] "Telegram desktop app.")
    (homeModule [ "user" "apps" "youtubeMusic" ] "/modules/user-apps/youtube-music.nix" "app" [ "desktop" ] "YouTube Music desktop app.")
    (homeModule [ "user" "apps" "zenBrowser" ] "/modules/user-apps/zen-browser.nix" "app" [ "desktop" ] "Zen Browser.")

    (homeModule [ "user" "desktop" "end4HyprlandDots" ] "/modules/user-desktop/hyprland/end4-dots.nix" "desktop" [ "desktop" ] "end-4 Hyprland dotfiles.")
    (homeModule [ "user" "desktop" "hyprlandConfig" ] "/modules/user-desktop/hyprland/config.nix" "desktop" [ "desktop" ] "Hyprland user config.")
    (homeModule [ "user" "desktop" "niriConfig" ] "/modules/user-desktop/niri/config.nix" "desktop" [ "desktop" ] "Niri user config.")
    (homeModule [ "user" "desktop" "noctalia" ] "/modules/user-desktop/noctalia" "desktop" [ "desktop" ] "Noctalia shell user setup.")
    (homeModule [ "user" "desktop" "screenRecorder" ] "/modules/user-desktop/screen-recorder.nix" "desktop" [ "desktop" ] "User screen recording tools.")

    # Developer bundles define composition; leaf modules define tool-specific seams.
    (homeModule [ "user" "dev" "workstation" ] "/modules/user-dev/bundles/workstation.nix" "development" [ "desktop" ] "Developer workstation bundle.")
    (homeModule [ "user" "dev" "toolchains" ] "/modules/user-dev/bundles/toolchains.nix" "development" [ "desktop" ] "Generic developer toolchains bundle.")
    (homeModule [ "user" "dev" "terminalWorkflow" ] "/modules/user-dev/bundles/terminal-workflow.nix" "development" [ "desktop" ] "Terminal workflow bundle.")
    (homeModule [ "user" "dev" "ffmpeg" ] "/modules/user-dev/ffmpeg.nix" "development" [ "desktop" ] "FFmpeg user tools.")
    (homeModule [ "user" "dev" "fish" ] "/modules/user-dev/fish" "development" [ "desktop" ] "Fish shell user config.")
    (homeModule [ "user" "dev" "git" ] "/modules/user-dev/git.nix" "development" [ "desktop" "server" ] "Git user config.")
    (homeModule [ "user" "dev" "github" ] "/modules/user-dev/github.nix" "development" [ "desktop" ] "GitHub CLI user config.")
    (homeModule [ "user" "dev" "ssh" ] "/modules/user-dev/ssh.nix" "development" [ "desktop" "server" ] "SSH user config.")
    (homeModule [ "user" "dev" "languages" "cpp" ] "/modules/user-dev/languages/cpp.nix" "development" [ "desktop" ] "C/C++ language tools.")
    (homeModule [ "user" "dev" "languages" "python" ] "/modules/user-dev/languages/python.nix" "development" [ "desktop" ] "Python language tools.")
    (homeModule [ "user" "dev" "languages" "rust" ] "/modules/user-dev/languages/rust.nix" "development" [ "desktop" ] "Rust language tools.")
    (homeModule [ "user" "dev" "kitty" ] "/modules/user-dev/kitty" "development" [ "desktop" ] "Kitty terminal config.")
    (homeModule [ "user" "dev" "neovim" ] "/modules/user-dev/neovim" "development" [ "desktop" ] "Neovim user config.")
    (homeModule [ "user" "dev" "starship" ] "/modules/user-dev/starship" "development" [ "desktop" ] "Starship prompt config.")
    (homeModule [ "user" "dev" "tmux" ] "/modules/user-dev/tmux" "development" [ "desktop" ] "tmux user config.")
    (homeModule [ "user" "dev" "vscode" ] "/modules/user-dev/vscode.nix" "development" [ "desktop" ] "VS Code user config.")
    (homeModule [ "user" "dev" "zed" ] "/modules/user-dev/zed.nix" "development" [ "desktop" ] "Zed editor user config.")
    (homeModule [ "user" "dev" "zoxide" ] "/modules/user-dev/zoxide.nix" "development" [ "desktop" ] "zoxide shell navigation.")

    (homeModule [ "user" "files" "dolphin" ] "/modules/user-files/dolphin.nix" "files" [ "desktop" ] "Dolphin file manager user config.")
    (homeModule [ "user" "files" "yazi" ] "/modules/user-files/yazi.nix" "files" [ "desktop" ] "Yazi terminal file manager.")
  ];

  entryForProfile = profile: scope: entry:
    entry.scope == scope && elem profile entry.profiles;

  entriesFor = profile: scope:
    filter (entryForProfile profile scope) entries;

  pathsFor = profile: scope:
    map (entry: entry.path) (entriesFor profile scope);

  profileImports = profile: {
    systemModules = pathsFor profile "system";
    homeModules = pathsFor profile "home";
  };

  paths = foldl' (
    acc: entry:
    recursiveUpdate acc (setAttrPath entry.attrPath entry.path)
  ) { } entries;
in
{
  inherit
    entries
    entriesFor
    paths
    pathsFor
    profileImports
    ;

  profiles = {
    desktop = profileImports "desktop";
    server = profileImports "server";
  };
}
