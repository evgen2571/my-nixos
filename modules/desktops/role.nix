{
  config,
  lib,
  ...
}:

let
  cfg = config.my.desktop;
  active = cfg.active;

  niriWorkspaceProfile =
    if config.networking.hostName == "nixos-lp" then
      "laptop"
    else if config.networking.hostName == "nixos-pc" then
      "pc"
    else
      "default";
in
{
  options.my.desktop.active = lib.mkOption {
    type = lib.types.enum [
      "none"
      "niri"
      "hyprland"
    ];
    default = "none";
    description = ''
      Active desktop stack for this host.

      The selected stack owns the matching system compositor module,
      Home Manager desktop config, shell/session pieces, and portal
      invariants so host profiles only choose the desktop role.
    '';
  };

  config = lib.mkMerge [
    {
      assertions = [
        {
          assertion =
            active != "niri"
            || (config.my.desktop.niri.enable
              && !config.my.desktop.hyprland.enable
              && !config.my.desktop.cinnamon.enable);
          message = "my.desktop.active = \"niri\" must resolve to Niri as the only enabled compositor stack.";
        }
        {
          assertion =
            active != "hyprland"
            || (config.my.desktop.hyprland.enable
              && !config.my.desktop.niri.enable
              && !config.my.desktop.cinnamon.enable);
          message = "my.desktop.active = \"hyprland\" must resolve to Hyprland as the only enabled compositor stack.";
        }
      ];
    }

    (lib.mkIf (active == "niri") {
      my.desktop = {
        niri.enable = lib.mkDefault true;
        hyprland.enable = lib.mkDefault false;
        cinnamon.enable = lib.mkDefault false;
        ly.enable = lib.mkDefault true;
      };
      my.system.dev.fish.enable = lib.mkDefault true;

      my.primaryUser.home.settings.my.user.desktop = {
        niriConfig = {
          enable = lib.mkDefault true;
          workspaceProfile = lib.mkDefault niriWorkspaceProfile;
        };
        hyprlandConfig.enable = lib.mkDefault false;
        end4HyprlandDots.enable = lib.mkDefault false;
        noctalia.enable = lib.mkDefault true;
      };
    })

    (lib.mkIf (active == "hyprland") {
      my.desktop = {
        niri.enable = lib.mkDefault false;
        hyprland.enable = lib.mkDefault true;
        cinnamon.enable = lib.mkDefault false;
        ly.enable = lib.mkDefault true;
      };
      my.system.dev.fish.enable = lib.mkDefault true;

      my.primaryUser.home.settings.my.user.desktop = {
        niriConfig.enable = lib.mkDefault false;
        hyprlandConfig.enable = lib.mkDefault true;
        end4HyprlandDots.enable = lib.mkDefault false;
        noctalia.enable = lib.mkDefault false;
      };
    })
  ];
}
