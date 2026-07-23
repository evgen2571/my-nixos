{
  configPaths,
  config,
  lib,
  ...
}:

let
  cfg = config.my.user.dev.neovim;
  nvimConfig = configPaths.dev.neovim.configDir;
in
{
  config = lib.mkIf cfg.enable {
    # Copy Neovim's configuration instead of linking it to the Nix store.
    # This keeps the live ~/.config/nvim tree writable while still allowing
    # Home Manager to refresh it on activation.
    xdg.configFile."nvim" = {
      source = nvimConfig;
      recursive = true;
    };
  };
}
