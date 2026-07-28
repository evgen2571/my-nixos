{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.my.user.apps.voxtype;
  system = pkgs.stdenv.hostPlatform.system;
in
{
  imports = [
    inputs.voxtype.homeManagerModules.default
  ];

  options.my.user.apps.voxtype.enable = lib.mkEnableOption "Voxtype";

  config = lib.mkIf cfg.enable {
    programs.voxtype = {
      enable = true;

      # Whisper with Vulkan acceleration.
      package = inputs.voxtype.packages.${system}.vulkan;

      # Declaratively downloaded during rebuild.
      model.name = "small";

      # Start Voxtype automatically with the graphical session.
      service.enable = true;

      settings = {
        # Niri will manage the keyboard shortcut.
        # This avoids requiring access to /dev/input.
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
