{
  config,
  lib,
  inputs,
  packageSources,
  ...
}:

let
  cfg = config.my.user.apps.voxtype;
in
{
  imports = [
    inputs.voxtype.homeManagerModules.default
  ];

  options.my.user.apps.voxtype.enable = lib.mkEnableOption "Voxtype";

  config = lib.mkIf cfg.enable {
    programs.voxtype = {
      enable = true;

      package = packageSources.voxtype;

      model.name = "small";

      service.enable = true;

      settings = {
        # Niri handles the shortcut, so Voxtype needs no access to /dev/input.
        hotkey.enabled = false;

        whisper = {
          language = "auto";
          translate = false;
        };

        output = {
          mode = "type";
          fallback_to_clipboard = true;
          type_delay_ms = 0;
        };

        text = {
          spoken_punctuation = true;

          replacements = {
            "next OS" = "NixOS";
            "way land" = "Wayland";
            "vox type" = "Voxtype";
          };
        };
      };
    };
  };
}
