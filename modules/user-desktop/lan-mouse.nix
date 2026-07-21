{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.desktop.lanMouse;

  tomlFormat = pkgs.formats.toml { };

  settings = lib.recursiveUpdate {
    port = 4242;
  } cfg.settings;
in
{
  options.my.user.desktop.lanMouse = {
    enable = lib.mkEnableOption "Lan Mouse";

    settings = lib.mkOption {
      inherit (tomlFormat) type;

      default = { };

      description = ''
        Lan Mouse configuration written to
        ~/.config/lan-mouse/config.toml.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.lan-mouse
    ];

    xdg.configFile."lan-mouse/config.toml".source =
      tomlFormat.generate "lan-mouse-config.toml" settings;

    systemd.user.services.lan-mouse = {
      Unit = {
        Description = "Lan Mouse";

        After = [
          "graphical-session.target"
        ];

        PartOf = [
          "graphical-session.target"
        ];
      };

      Service = {
        Type = "simple";

        ExecStart = "${lib.getExe pkgs.lan-mouse} daemon";

        Restart = "on-failure";
        RestartSec = 2;
      };

      Install.WantedBy = [
        "graphical-session.target"
      ];
    };
  };
}
