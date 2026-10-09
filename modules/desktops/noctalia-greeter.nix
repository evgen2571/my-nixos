{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.desktop.noctaliaGreeter;
in
{
  # The 26.05 system nixpkgs has the package, but not yet the NixOS module.
  imports = [
    (inputs.nixpkgs-unstable + "/nixos/modules/services/display-managers/noctalia-greeter.nix")
  ];

  options.my.desktop.noctaliaGreeter.enable = lib.mkEnableOption "Noctalia Greeter display manager";

  config = lib.mkIf cfg.enable {
    services.displayManager.noctalia-greeter = {
      enable = true;
      package = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.noctalia-greeter;

      cursorTheme = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Ice";
      };

      settings = {
        session.default = "niri";
        user.default = config.my.primaryUser.name;
        cursor.size = 24;

        keyboard = {
          layout = "us,ru";
          variant = ",phonetic";
          options = "grp:alt_shift_toggle";
        };
      };
    };

    # Unlock GNOME Keyring when greetd authenticates with the account password.
    security.pam.services.greetd.enableGnomeKeyring = true;
  };
}
