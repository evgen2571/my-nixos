{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.desktop.end4HyprlandDots;

  optionalPackage = name: lib.optional (builtins.hasAttr name pkgs) (builtins.getAttr name pkgs);
  optionalKdePackage =
    name:
    lib.optional (builtins.hasAttr "kdePackages" pkgs && builtins.hasAttr name pkgs.kdePackages) (
      builtins.getAttr name pkgs.kdePackages
    );

  runtimePackages =
    with pkgs;
    [
      bash
      coreutils
      curl
      git
      jq
      rsync
      wget
      wl-clipboard
      xdg-user-dirs
    ]
    ++ optionalPackage "bc"
    ++ optionalPackage "brightnessctl"
    ++ optionalPackage "cava"
    ++ optionalPackage "cliphist"
    ++ optionalPackage "ddcutil"
    ++ optionalPackage "easyeffects"
    ++ optionalPackage "fuzzel"
    ++ optionalPackage "hypridle"
    ++ optionalPackage "hyprlock"
    ++ optionalPackage "hyprpicker"
    ++ optionalPackage "hyprshot"
    ++ optionalPackage "imagemagick"
    ++ optionalPackage "libqalculate"
    ++ optionalPackage "matugen"
    ++ optionalPackage "playerctl"
    ++ optionalPackage "pavucontrol"
    ++ optionalPackage "pavucontrol-qt"
    ++ optionalPackage "quickshell"
    ++ optionalPackage "slurp"
    ++ optionalPackage "songrec"
    ++ optionalPackage "swappy"
    ++ optionalPackage "swaylock"
    ++ optionalPackage "tesseract"
    ++ optionalPackage "translate-shell"
    ++ optionalPackage "upower"
    ++ optionalPackage "wf-recorder"
    ++ optionalPackage "wlogout"
    ++ optionalPackage "wtype"
    ++ optionalPackage "ydotool"
    ++ optionalKdePackage "dolphin"
    ++ optionalKdePackage "kdialog"
    ++ optionalKdePackage "plasma-systemmonitor"
    ++ optionalKdePackage "polkit-kde-agent-1"
    ++ optionalKdePackage "systemsettings";
in
{
  options.my.user.desktop.end4HyprlandDots = {
    enable = lib.mkEnableOption "end-4/dots-hyprland user configuration";

    repoUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://github.com/end-4/dots-hyprland.git";
      description = "Git repository used for end-4 Hyprland dots.";
    };

    revision = lib.mkOption {
      type = lib.types.str;
      default = "47235ac4408e52d07ef2cfec8f38dbd62057717c";
      description = "Pinned end-4/dots-hyprland commit to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = runtimePackages;

    home.activation.installEnd4HyprlandDots = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      set -eu

      repo_dir="$HOME/.local/share/end4-dots-hyprland"
      marker="$HOME/.config/.end4-hyprland-managed"

      if [ ! -d "$repo_dir/.git" ]; then
        rm -rf "$repo_dir"
        ${pkgs.git}/bin/git clone --filter=blob:none "${cfg.repoUrl}" "$repo_dir"
      fi

      ${pkgs.git}/bin/git -C "$repo_dir" fetch --depth=1 origin "${cfg.revision}"
      ${pkgs.git}/bin/git -C "$repo_dir" checkout --detach "${cfg.revision}"

      install_dir() {
        src="$1"
        dst="$2"
        if [ -e "$dst" ] && [ ! -e "$marker" ]; then
          backup="$dst.before-end4.$(${pkgs.coreutils}/bin/date +%Y%m%d%H%M%S)"
          mv "$dst" "$backup"
          echo "Backed up existing $dst to $backup"
        fi
        mkdir -p "$(${pkgs.coreutils}/bin/dirname "$dst")"
        ${pkgs.rsync}/bin/rsync -a --delete "$src"/ "$dst"/
      }

      install_dir "$repo_dir/dots/.config/hypr" "$HOME/.config/hypr"
      install_dir "$repo_dir/dots/.config/quickshell/ii" "$HOME/.config/quickshell/ii"
      install_dir "$repo_dir/dots/.config/fuzzel" "$HOME/.config/fuzzel"
      install_dir "$repo_dir/dots/.config/matugen" "$HOME/.config/matugen"

      if [ -f "$repo_dir/dots-extra/via-nix/hypridle.conf" ]; then
        install -D -m 644 "$repo_dir/dots-extra/via-nix/hypridle.conf" "$HOME/.config/hypr/hypridle.conf"
      fi

      touch "$marker"
    '';
  };
}
