{ root }:
{
  # System-level NixOS modules imported by hosts/*/configuration.nix.
  system = {
    common = root + "/modules/system-core/common.nix";
    server = root + "/modules/system-core/server.nix";
    user = root + "/modules/system-core/user.nix";
  };

  ai = {
    ollama = root + "/modules/system-services/ollama.nix";
  };

  systemServices = {
    tailscale = root + "/modules/system-services/tailscale.nix";
    blueman = root + "/modules/system-services/blueman.nix";
    syncthing = root + "/modules/system-services/syncthing.nix";
    vpnbookWireguardFailover = root + "/modules/system-services/vpnbook-wireguard-failover.nix";
  };

  apps = {
    aagl = root + "/modules/system-apps/aagl.nix";
    kdeConnect = root + "/modules/system-apps/kde-connect.nix";
    lutris = root + "/modules/system-apps/lutris.nix";
    obs = root + "/modules/system-apps/obs.nix";
    steam = root + "/modules/system-apps/steam.nix";
    vesktop = root + "/modules/system-apps/vesktop.nix";
  };

  coding = {
    docker = root + "/modules/system-dev/docker";
    fish = root + "/modules/system-dev/fish.nix";
  };

  fileManagers = {
    thunar = root + "/modules/system-files/thunar.nix";
  };

  hardware = {
    bluetooth = root + "/modules/hardware/bluetooth.nix";
    nvidia = root + "/modules/hardware/nvidia.nix";
    screenRecorder = root + "/modules/hardware/screen-recorder.nix";
  };

  wm = {
    cinnamon = root + "/modules/desktops/cinnamon";
    gnome = root + "/modules/desktops/gnome";
    hyprland = root + "/modules/desktops/hyprland";
    ly = root + "/modules/desktops/ly.nix";
    niri = root + "/modules/desktops/niri";
    opentabletdriver = root + "/modules/desktops/opentabletdriver.nix";
    virtualization = root + "/modules/system-services/virtualization.nix";
    xserver = root + "/modules/desktops/xserver.nix";
  };

  # User-level Home Manager modules imported by flake.nix through profile-imports.nix.
  user = {
    ai = {
      codex = root + "/modules/user-ai/codex.nix";
      llamaCpp = root + "/modules/user-ai/llama-cpp.nix";
      opencode = root + "/modules/user-ai/opencode.nix";
    };

    apps = {
      anki = root + "/modules/user-apps/anki.nix";
      bitwarden = root + "/modules/user-apps/bitwarden.nix";
      bruno = root + "/modules/user-apps/bruno.nix";
      chrome = root + "/modules/user-apps/chrome.nix";
      notion = root + "/modules/user-apps/notion.nix";
      mpv = root + "/modules/user-apps/mpv.nix";
      obsidian = root + "/modules/user-apps/obsidian.nix";
      osuLazer = root + "/modules/user-apps/osu-lazer.nix";
      prismLauncher = root + "/modules/user-apps/prism-launcher.nix";
      slack = root + "/modules/user-apps/slack.nix";
      telegram = root + "/modules/user-apps/telegram.nix";
      youtubeMusic = root + "/modules/user-apps/youtube-music.nix";
      zenBrowser = root + "/modules/user-apps/zen-browser.nix";
    };

    dev = {
      ffmpeg = root + "/modules/user-dev/ffmpeg.nix";
      fish = root + "/modules/user-dev/fish";
      git = root + "/modules/user-dev/git.nix";
      github = root + "/modules/user-dev/github.nix";
      ssh = root + "/modules/user-dev/ssh.nix";
      kitty = root + "/modules/user-dev/kitty";
      neovim = root + "/modules/user-dev/neovim";
      starship = root + "/modules/user-dev/starship";
      languages = {
        cpp = root + "/modules/user-dev/languages/cpp.nix";
        python = root + "/modules/user-dev/languages/python.nix";
        rust = root + "/modules/user-dev/languages/rust.nix";
      };
      terminalWorkflow = root + "/modules/user-dev/bundles/terminal-workflow.nix";
      tmux = root + "/modules/user-dev/tmux";
      toolchains = root + "/modules/user-dev/bundles/toolchains.nix";
      vscode = root + "/modules/user-dev/vscode.nix";
      workstation = root + "/modules/user-dev/bundles/workstation.nix";
      zed = root + "/modules/user-dev/zed.nix";
      zoxide = root + "/modules/user-dev/zoxide.nix";
    };

    files = {
      dolphin = root + "/modules/user-files/dolphin.nix";
      yazi = root + "/modules/user-files/yazi.nix";
    };

    desktop = {
      end4HyprlandDots = root + "/modules/user-desktop/hyprland/end4-dots.nix";
      hyprlandConfig = root + "/modules/user-desktop/hyprland/config.nix";
      niriConfig = root + "/modules/user-desktop/niri/config.nix";
      noctalia = root + "/modules/user-desktop/noctalia";
      screenRecorder = root + "/modules/user-desktop/screen-recorder.nix";
    };
  };
}
