{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.my.user.ai.t3Code;

  agents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};

  # Do not bundle additional agents, especially an unwrapped Codex.
  t3code = agents.t3code.override {
    providerPackages = [ ];
  };

  # Use Numtide's prebuilt desktop package.
  # Only build a lightweight wrapper to disable automatic updates.
  package = pkgs.symlinkJoin {
    name = "t3code-desktop-managed";

    paths = [ t3code.desktop ];

    nativeBuildInputs = [ pkgs.makeWrapper ];

    postBuild = ''
      rm "$out/bin/t3code-desktop"

      makeWrapper ${t3code.desktop}/bin/t3code-desktop \
        "$out/bin/t3code-desktop" \
        --set T3CODE_DISABLE_AUTO_UPDATE true
    '';
  };

  codexSettings = {
    # Reuse the Codex CLI's existing login instead of T3's separate OAuth.
    # Home Manager's mutable settings merge gives this declarative value priority.
    setupMode = "existing";
    enabled = true;
    binaryPath = lib.getExe config.my.user.ai.codex.package;
    homePath = "${config.home.homeDirectory}/.codex";
    shadowHomePath = "";
  };
in
{
  options.my.user.ai.t3Code.enable = lib.mkEnableOption "T3 Code workspace";

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.my.user.ai.codex.enable;
        message = "T3 Code requires my.user.ai.codex.enable.";
      }
    ];

    programs.t3code = {
      enable = true;
      inherit package;

      # Preserve settings, sessions and other mutable user state.
      mutableUserSettings = true;

      userSettings = {
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
