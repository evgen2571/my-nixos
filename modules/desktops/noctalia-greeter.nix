{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.desktop.noctaliaGreeter;
  greeterPackage =
    inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.noctalia-greeter;
in
{
  imports = [
    inputs.noctalia-greeter.nixosModules.default
  ];

  options.my.desktop.noctaliaGreeter.enable = lib.mkEnableOption "Noctalia Greeter display manager";

  config = lib.mkIf cfg.enable {
    services.displayManager.noctalia-greeter = {
      enable = true;
      package = greeterPackage;

      cursorTheme.package = pkgs.bibata-cursors;

      settings = {
        session.default = "niri";
        user.default = config.my.primaryUser.name;
        cursor.size = 24;
        cursor.theme = "Bibata-Modern-Ice";

        # Only pin layout. Leave wallpaper, palette, and scheme to Noctalia Sync.
        appearance = {
          # Show Noctalia's current colors after the first successful Sync Now.
          # Palette and wallpaper files are still managed by Noctalia, not Nix.
          scheme = "Synced";
          hide_logo = true;
          password_style = "default";
          power_buttons_position = "bottom-right";
          scheme_selector_position = "top-right";
        };

        clock = {
          enabled = true;
          position = "top-left";
          time_format = "{:%H:%M}";
          date_format = "%A, %d %B";
        };

        keyboard = {
          layout = "us,ru";
          variant = ",phonetic";
          options = "grp:alt_shift_toggle";
        };
      };
    };

    # Password-based greetd authentication can unlock an existing login keyring
    # only when its password matches the account password.
    security.pam.services.greetd.enableGnomeKeyring = true;

    # Allow this local desktop user to apply only the greeter's constrained
    # appearance-sync action, not arbitrary commands or legacy sync operations.
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.noctalia.greeter.sync-appearance" &&
            action.lookup("program") == "${greeterPackage}/bin/noctalia-greeter-apply-appearance" &&
            action.lookup("user") == "root" &&
            subject.local && subject.active &&
            subject.user == ${builtins.toJSON config.my.primaryUser.name}) {
          return polkit.Result.YES;
        }
      });
    '';
  };
}
