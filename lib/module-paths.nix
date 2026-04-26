{ root }:
{
  # System-level NixOS modules imported by hosts/*/configuration.nix.
  system = {
    common = root + "/modules/system-core/common.nix";
    user = root + "/modules/system-core/user.nix";
  };

  ai = {
    ollama = root + "/modules/system-services/ollama.nix";
  };

  systemServices = {
    vpnbookWireguardFailover = root + "/modules/system-services/vpnbook-wireguard-failover.nix";
  };

  apps = {
    aagl = root + "/modules/system-apps/aagl.nix";
    kdeConnect = root + "/modules/system-apps/kde-connect.nix";
    lutris = root + "/modules/system-apps/lutris.nix";
    obs = root + "/modules/system-apps/obs.nix";
    steam = root + "/modules/system-apps/steam.nix";
  };

  coding = {
    docker = root + "/modules/system-dev/docker";
    fish = root + "/modules/system-dev/fish.nix";
  };

  fileManagers = {
    thunar = root + "/modules/system-files/thunar.nix";
  };

  hardware = {
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

  # User-level Home Manager modules imported by home/*/home.nix.
  user = {
    ai = {
      codex = root + "/modules/user-ai/codex.nix";
      llamaCpp = root + "/modules/user-ai/llama-cpp.nix";
    };

    apps = {
      bitwarden = root + "/modules/user-apps/bitwarden.nix";
      chrome = root + "/modules/user-apps/chrome.nix";
      obsidian = root + "/modules/user-apps/obsidian.nix";
      osuLazer = root + "/modules/user-apps/osu-lazer.nix";
      prismLauncher = root + "/modules/user-apps/prism-launcher.nix";
      telegram = root + "/modules/user-apps/telegram.nix";
      vesktop = root + "/modules/user-apps/vesktop.nix";
      youtubeMusic = root + "/modules/user-apps/youtube-music.nix";
      zenBrowser = root + "/modules/user-apps/zen-browser.nix";
    };

    dev = {
      devTools = root + "/modules/user-dev/dev-tools.nix";
      fishConfig = root + "/modules/user-dev/fish/config.nix";
      git = root + "/modules/user-dev/git.nix";
      ide = root + "/modules/user-dev/ide.nix";
      kitty = root + "/modules/user-dev/kitty";
      neovim = root + "/modules/user-dev/neovim";
      starship = root + "/modules/user-dev/starship";
      tmux = root + "/modules/user-dev/tmux";
      vscode = root + "/modules/user-dev/vscode.nix";
      zed = root + "/modules/user-dev/zed.nix";
    };

    files = {
      dolphin = root + "/modules/user-files/dolphin.nix";
      yazi = root + "/modules/user-files/yazi.nix";
    };

    desktop = {
      hyprlandConfig = root + "/modules/user-desktop/hyprland/config.nix";
      niriConfig = root + "/modules/user-desktop/niri/config.nix";
      noctalia = root + "/modules/user-desktop/noctalia";
      screenRecorder = root + "/modules/user-desktop/screen-recorder.nix";
    };
  };
}
