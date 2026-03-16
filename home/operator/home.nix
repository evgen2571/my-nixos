{ lib, wm, ... }:
{
  home.username = "operator";
  home.homeDirectory = "/home/operator";

  imports = [
    # wm
    (lib.getAttr wm {
      hyprland = ../../modules/wm/hyprland/config.nix;
      niri = ../../modules/wm/niri/config.nix;
    })
    ../../modules/wm/noctalia
    ../../modules/wm/screen-recorder.nix

    # apps
    ../../modules/apps/zen-browser.nix
    ../../modules/apps/obsidian.nix
    ../../modules/apps/vesktop.nix
    # ../../modules/apps/telegram.nix
    ../../modules/apps/youtube-music.nix
    ../../modules/apps/prism-launcher.nix

    # file managers
    ../../modules/file-managers/dolphin.nix
    ../../modules/file-managers/yazi.nix

    # coding
    ../../modules/coding/kitty
    ../../modules/coding/neovim
    ../../modules/coding/tmux
    ../../modules/coding/starship
    ../../modules/coding/fish/config.nix
    ../../modules/coding/dev-tools.nix
    ../../modules/coding/git.nix
    ../../modules/coding/vscode.nix
  ];

  home.sessionPath = [ "$HOME/.cargo/bin" ];

  home.enableNixpkgsReleaseCheck = false;
  home.stateVersion = "25.11";
}
