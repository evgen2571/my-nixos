{ lib, wm, ... }: {
  home.username = "evgen2571";
  home.homeDirectory = "/home/evgen2571";

  imports = [
    # wm
    (lib.getAttr wm {
      hyprland = ../../modules/wm/hyprland/config.nix;
      niri = ../../modules/wm/niri/config.nix;
    })
    ../../modules/wm/noctalia.nix
	../../modules/wm/screen-recorder.nix

    # apps
    ../../modules/apps/zen-browser.nix
    ../../modules/apps/obsidian.nix
    ../../modules/apps/vesktop.nix
    ../../modules/apps/telegram.nix
    ../../modules/apps/youtube-music.nix

    # file managers
    ../../modules/file-managers/dolphin.nix
    ../../modules/file-managers/yazi.nix

    # coding
    ../../modules/coding/ide.nix
    ../../modules/coding/dev-tools.nix
    ../../modules/coding/git.nix
    ../../modules/coding/vscode.nix
  ];

  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "25.11";
}
