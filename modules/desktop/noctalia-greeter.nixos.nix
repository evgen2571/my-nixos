{
  config,
  inputs,
  packageSources,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.desktop.noctaliaGreeter;
  greeterPackage = packageSources.noctalia-greeter;
  user = config.my.primaryUser.name;
  greeterUser = config.services.greetd.settings.default_session.user;
  skwdEnabled =
    config.my.primaryUser.home.enable
    && (config.home-manager.users.${user}.my.user.desktop.skwdWall.enable or false);
  wallpaperDir = "/var/lib/noctalia-greeter-wallpaper";
  wallpaperPath = "${wallpaperDir}/background.jpg";
  wallpaper = {
    path = wallpaperPath;
    fill_mode = "crop";
  };
  publisher = pkgs.writeText "skwd-greeter-wallpaper.py" (
    builtins.readFile ../../config/skwd-wall/greeter_wallpaper.py
  );
in
{
  imports = [
    inputs.noctalia-greeter.nixosModules.default
  ];

  options.my.desktop.noctaliaGreeter = {
    enable = lib.mkEnableOption "Noctalia Greeter display manager";
    output = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Connector to pin the greeter to. An empty value uses all connected outputs.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.displayManager.noctalia-greeter = {
      enable = true;
      package = greeterPackage;

      settings = {
        session.default = if config.my.desktop.umbriel.enable then "umbriel" else "niri";
        user.default = user;
        output.name = cfg.output;

        cursor = {
          theme = "Bibata-Modern-Ice";
          size = 24;
          path = "${pkgs.bibata-cursors}/share/icons";
        };

        appearance = {
          scheme = "Synced";
          hide_logo = true;
          password_style = "default";
          power_buttons_position = "bottom-right";
          scheme_selector_position = "top-right";
          wallpaper = lib.mkIf skwdEnabled wallpaper;
          wallpapers = lib.mkIf (skwdEnabled && cfg.output != "") { ${cfg.output} = wallpaper; };
        };

        clock = {
          enabled = true;
          position = "above-panel";
          time_font_size = 64;
          date_font_size = 18;
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

    # The desktop user publishes the image. The greeter group only reads it.
    systemd.tmpfiles.settings."10-noctalia-greeter-wallpaper".${wallpaperDir}.d = lib.mkIf skwdEnabled {
      inherit user;
      group = config.users.users.${greeterUser}.group;
      mode = "2750";
    };

    my.primaryUser.home.settings =
      { config, ... }:
      {
        systemd.user.services.skwd-greeter-wallpaper = lib.mkIf config.my.user.desktop.skwdWall.enable {
          Unit = {
            Description = "Publish the Skwd wallpaper for Noctalia Greeter";
            After = [ "skwd-walld.service" ];
            PartOf = [ "skwd-walld.service" ];
          };
          Service = {
            ExecStart = lib.escapeShellArgs [
              (lib.getExe pkgs.python3)
              "${publisher}"
              "${packageSources.skwd-wall}/bin/skwd-helm"
              (lib.getExe pkgs.ffmpeg)
              cfg.output
              wallpaperPath
            ];
            Restart = "always";
            RestartSec = 2;
          };
          Install.WantedBy = [ "skwd-walld.service" ];
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
