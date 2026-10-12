{ root }:
let
  inherit (builtins) listToAttrs readFile;

  mkXdgSource = target: source: {
    name = target;
    value.source = source;
  };

  mkXdgSourceSet = entries: listToAttrs (map (entry: mkXdgSource entry.target entry.source) entries);

  paths = rec {
    dev = {
      fish.configDir = root + "/config/fish";
      kitty.configFile = root + "/config/kitty/kitty.conf";
      neovim.configDir = root + "/config/nvim";
      starship.configFile = root + "/config/starship/starship.toml";
    };

    wm = {
      hyprlandConfigDir = root + "/config/hyprland";
      kdeplasmaConfigDir = root + "/config/kdeplasma";
      niriConfigDir = root + "/config/niri";
      noctaliaConfigDir = root + "/config/noctalia";
    };

    dotfileAdapters = {
      fish =
        {
          configDir ? dev.fish.configDir,
        }:
        {
          "fish/config.fish".source = configDir + "/config.fish";

          "fish/conf.d" = {
            source = configDir + "/conf.d";
            recursive = true;
          };

          "fish/functions" = {
            source = configDir + "/functions";
            recursive = true;
          };
        };

      kitty =
        {
          source ? dev.kitty.configFile,
          fontSize ? "17.0",
        }:
        {
          "kitty/kitty.conf" =
            if fontSize == "17.0" then
              { inherit source; }
            else
              {
                text = (readFile source) + ''

                  # Host adapter override
                  font_size        ${fontSize}
                '';
              };
        };

      starship =
        {
          configFile ? dev.starship.configFile,
        }:
        {
          "starship.toml".source = configFile;
        };

      niri =
        {
          configDir ? wm.niriConfigDir,
          workspaceProfile ? "default",
        }:
        let
          workspaceFiles = {
            default = "workspaces.kdl";
            pc = "workspaces-pc.kdl";
            laptop = "workspaces-laptop.kdl";
          };
          workspacesFile = workspaceFiles.${workspaceProfile};
          t3codeRuleFile = if workspaceProfile == "laptop" then "t3code-laptop.kdl" else "t3code.kdl";
        in
        mkXdgSourceSet [
          {
            target = "niri/config.kdl";
            source = configDir + "/config.kdl";
          }
          {
            target = "niri/sub/outputs.kdl";
            source = configDir + "/sub/outputs.kdl";
          }
          {
            target = "niri/sub/workspaces.kdl";
            source = configDir + "/sub/${workspacesFile}";
          }
          {
            target = "niri/sub/rules/common.kdl";
            source = configDir + "/sub/rules/common.kdl";
          }
          {
            target = "niri/sub/rules/obsidian.kdl";
            source = configDir + "/sub/rules/obsidian.kdl";
          }
          {
            target = "niri/sub/rules/apps.kdl";
            source = configDir + "/sub/rules/apps.kdl";
          }
          {
            target = "niri/sub/rules/t3code.kdl";
            source = configDir + "/sub/rules/${t3codeRuleFile}";
          }
          {
            target = "niri/scripts/focus-or-launch";
            source = configDir + "/scripts/focus-or-launch";
          }
          {
            target = "niri/sub/binds.kdl";
            source = configDir + "/sub/binds.kdl";
          }
          {
            target = "niri/sub/layout.kdl";
            source = configDir + "/sub/layout.kdl";
          }
          {
            target = "niri/sub/input.kdl";
            source = configDir + "/sub/input.kdl";
          }
          {
            target = "niri/sub/startup.kdl";
            source = configDir + "/sub/startup.kdl";
          }
        ];

      hyprland =
        {
          configDir ? wm.hyprlandConfigDir,
        }:
        mkXdgSourceSet [
          {
            target = "hypr/hyprland.conf";
            source = configDir + "/hyprland.conf";
          }
          {
            target = "hypr/sub/outputs.conf";
            source = configDir + "/sub/outputs.conf";
          }
          {
            target = "hypr/sub/workspaces.conf";
            source = configDir + "/sub/workspaces.conf";
          }
          {
            target = "hypr/sub/rules.conf";
            source = configDir + "/sub/rules.conf";
          }
          {
            target = "hypr/sub/binds.conf";
            source = configDir + "/sub/binds.conf";
          }
          {
            target = "hypr/sub/layout.conf";
            source = configDir + "/sub/layout.conf";
          }
          {
            target = "hypr/sub/input.conf";
            source = configDir + "/sub/input.conf";
          }
          {
            target = "hypr/sub/startup.conf";
            source = configDir + "/sub/startup.conf";
          }
        ];

      kdeplasma =
        {
          configDir ? wm.kdeplasmaConfigDir,
        }:
        mkXdgSourceSet [
          {
            target = "kcminputrc";
            source = configDir + "/kcminputrc";
          }
          {
            target = "kwinrc";
            source = configDir + "/kwinrc";
          }
          {
            target = "kxkbrc";
            source = configDir + "/kxkbrc";
          }
        ];
    };
  };
in
paths
