{
  configPaths,
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.dev.neovim;
  nvimConfig = configPaths.dev.neovim.configDir;
in
{
  config = lib.mkIf cfg.enable {
    home.activation.installNeovimConfig = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      set -eu

      source_dir="${nvimConfig}"
      target_dir="$HOME/.config/nvim"

      # Remove an old whole-directory Home Manager symlink.
      if [ -L "$target_dir" ]; then
        rm "$target_dir"
      fi

      mkdir -p "$target_dir"

      # Preserve generated theme and legacy marks until Harpoon 2 imports each project.
      ${pkgs.rsync}/bin/rsync \
        -a \
        --delete \
        --exclude='/lua/matugen.lua' \
        --exclude='/harpoon.json' \
        --chmod=u+rwX \
        "$source_dir"/ \
        "$target_dir"/

      # Existing files that rsync did not transfer may still have old
      # read-only Nix-store permissions.
      chmod -R u+rwX "$target_dir"
    '';
  };
}
