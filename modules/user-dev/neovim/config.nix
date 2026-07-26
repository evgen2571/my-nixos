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
    # Home Manager's xdg.configFile always creates store links, including when
    # recursive is enabled. Install a real writable copy during activation.
    home.activation.installNeovimConfig = config.lib.dag.entryAfter [ "writeBoundary" ] ''
      set -eu

      source_dir="${nvimConfig}"
      target_dir="$HOME/.config/nvim"
      mkdir -p "$target_dir"

      # Remove the read-only links created by the previous configuration.
      find "$target_dir" -type l -lname '/nix/store/*' -delete
      ${pkgs.rsync}/bin/rsync -a --delete "$source_dir"/ "$target_dir"/
    '';
  };
}
