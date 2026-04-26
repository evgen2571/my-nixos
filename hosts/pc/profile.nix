{ lib, modulePaths, ... }:

let
  desktop = {
    niri.enable = true;
    cinnamon.enable = true;
    ly.enable = true;
    opentabletdriver.enable = true;
  };

  hardware = {
    nvidia.enable = true;
  };

  system = {
    apps = {
      aagl.enable = true;
      kdeConnect.enable = true;
      steam.enable = true;
    };

    dev = {
      docker.enable = true;
      fish.enable = true;
    };

    files = {
      thunar.enable = true;
    };

    services = {
      ollama.enable = true;
      virtualization.enable = true;
    };
  };

  user = {
    apps = {
      bitwarden.enable = true;
      chrome.enable = true;
      obsidian.enable = true;
      osuLazer.enable = true;
      prismLauncher.enable = true;
      telegram.enable = true;
      vesktop.enable = true;
      youtubeMusic.enable = true;
      zenBrowser.enable = true;
    };

    desktop = {
      niriConfig.enable = true;
      noctalia.enable = true;
      screenRecorder.enable = true;
    };

    dev = {
      devTools.enable = true;
      fishConfig.enable = true;
      git.enable = true;
      kitty.enable = true;
      neovim.enable = true;
      starship.enable = true;
      tmux.enable = true;
    };

    files = {
      yazi.enable = true;
    };
  };

  when = condition: path: lib.optional condition path;
in
{
  imports =
    when desktop.niri.enable modulePaths.wm.niri
    ++ when desktop.cinnamon.enable modulePaths.wm.cinnamon
    ++ when desktop.ly.enable modulePaths.wm.ly
    ++ when desktop.opentabletdriver.enable modulePaths.wm.opentabletdriver
    ++ when hardware.nvidia.enable modulePaths.hardware.nvidia
    ++ when system.apps.aagl.enable modulePaths.apps.aagl
    ++ when system.apps.kdeConnect.enable modulePaths.apps.kdeConnect
    ++ when system.apps.steam.enable modulePaths.apps.steam
    ++ when system.dev.docker.enable modulePaths.coding.docker
    ++ when system.dev.fish.enable modulePaths.coding.fish
    ++ when system.files.thunar.enable modulePaths.fileManagers.thunar
    ++ when system.services.ollama.enable modulePaths.ai.ollama
    ++ when system.services.virtualization.enable modulePaths.wm.virtualization;

  home-manager.users.evgen2571.imports =
    when user.apps.bitwarden.enable modulePaths.user.apps.bitwarden
    ++ when user.apps.chrome.enable modulePaths.user.apps.chrome
    ++ when user.apps.obsidian.enable modulePaths.user.apps.obsidian
    ++ when user.apps.osuLazer.enable modulePaths.user.apps.osuLazer
    ++ when user.apps.prismLauncher.enable modulePaths.user.apps.prismLauncher
    ++ when user.apps.telegram.enable modulePaths.user.apps.telegram
    ++ when user.apps.vesktop.enable modulePaths.user.apps.vesktop
    ++ when user.apps.youtubeMusic.enable modulePaths.user.apps.youtubeMusic
    ++ when user.apps.zenBrowser.enable modulePaths.user.apps.zenBrowser
    ++ when user.desktop.niriConfig.enable modulePaths.user.desktop.niriConfig
    ++ when user.desktop.noctalia.enable modulePaths.user.desktop.noctalia
    ++ when user.desktop.screenRecorder.enable modulePaths.user.desktop.screenRecorder
    ++ when user.dev.devTools.enable modulePaths.user.dev.devTools
    ++ when user.dev.fishConfig.enable modulePaths.user.dev.fishConfig
    ++ when user.dev.git.enable modulePaths.user.dev.git
    ++ when user.dev.kitty.enable modulePaths.user.dev.kitty
    ++ when user.dev.neovim.enable modulePaths.user.dev.neovim
    ++ when user.dev.starship.enable modulePaths.user.dev.starship
    ++ when user.dev.tmux.enable modulePaths.user.dev.tmux
    ++ when user.files.yazi.enable modulePaths.user.files.yazi;
}
