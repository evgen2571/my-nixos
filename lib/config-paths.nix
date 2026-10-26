{ root, lib }:

let
  inherit (builtins) listToAttrs readFile;

  mkXdgSource = target: source: {
    name = target;
    value.source = source;
  };

  paths = rec {
    dev = {
      fish.configDir = root + "/config/fish";
      kitty.configFile = root + "/config/kitty/kitty.conf";
      neovim.configDir = root + "/config/nvim";
      starship.configFile = root + "/config/starship/starship.toml";
    };

    wm = {
      niriConfigDir = root + "/config/niri";
      umbrielConfigDir = root + "/config/umbriel";
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
        in
        # Keep leaf ownership: Noctalia generates siblings in the live Niri directory.
        builtins.removeAttrs (listToAttrs (
          map (
            source: mkXdgSource "niri/${lib.removePrefix "${toString configDir}/" (toString source)}" source
          ) (lib.filesystem.listFilesRecursive configDir)
        )) (map (file: "niri/sub/${file}") (builtins.attrValues workspaceFiles))
        // {
          "niri/sub/workspaces.kdl".source = configDir + "/sub/${workspacesFile}";
        };
    };
  };
in
paths
