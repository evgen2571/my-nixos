{ lib, modulePaths, ... }:

let
  desktop = {
    niri.enable = true;
    ly.enable = true;
  };

  system = {
    apps = {
      steam.enable = true;
    };

    dev = {
      fish.enable = true;
    };

    services = {
      ollama.enable = true;
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
    ++ when desktop.ly.enable modulePaths.wm.ly
    ++ when system.apps.steam.enable modulePaths.apps.steam
    ++ when system.dev.fish.enable modulePaths.coding.fish
    ++ when system.services.ollama.enable modulePaths.ai.ollama;

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
