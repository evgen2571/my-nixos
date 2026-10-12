{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.my.user.ai.t3Code;
  unstable = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config = pkgs.config;
  };
  t3 = unstable.t3code.override {
    # Avoid a second, unwrapped Codex on T3's private PATH.
    enableCodex = false;
  };
  codexSettings = {
    enabled = true;
    binaryPath = lib.getExe config.my.user.ai.codex.package;
    homePath = "${config.home.homeDirectory}/.codex";
    # Share the existing account directly; do not create a shadow auth directory.
    shadowHomePath = "";
  };
in
{
  options.my.user.ai.t3Code.enable = lib.mkEnableOption "T3 Code workspace";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.my.user.ai.codex.enable;
        message = "T3 Code requires my.user.ai.codex.enable so its configured executable is installed.";
      }
    ];

    programs.t3code = {
      enable = true;
      # The pinned unstable package uses supported Electron 43.
      # Set this on the executable so graphical launches inherit it as well.
      package = t3.overrideAttrs (old: {
        # symlinkJoin runs buildCommand directly, without fixup hooks.
        buildCommand = old.buildCommand + ''
          wrapProgram "$out/bin/t3code-desktop" \
            --set T3CODE_DISABLE_AUTO_UPDATE true
        '';
      });
      mutableUserSettings = true;
      userSettings = {
        # Keep the legacy mirror aligned with provider instances for probes.
        providers.codex = codexSettings;
        providerInstances.codex = {
          driver = "codex";
          enabled = true;
          config = codexSettings;
        };
      };
    };
  };
}
