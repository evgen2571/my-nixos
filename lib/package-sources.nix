{ inputs, system }:

let
  # Match the upstream package set for packages that need no local configuration.
  upstream = inputs.nixpkgs-unstable.legacyPackages.${system};

  unstable = import inputs.nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;
  };

  # Keep these allowances local to Vesktop's dependencies.
  vesktopPackages = import inputs.nixpkgs-unstable {
    inherit system;

    config = {
      allowUnfree = true;

      permittedInsecurePackages = [
        "electron-39.8.10"
        "pnpm-10.29.2"
      ];
    };
  };

  # sesh needs this mockery pin with the current unstable revision.
  seshPackages = import inputs.nixpkgs-unstable {
    inherit system;
    config.allowUnfree = true;

    overlays = [
      (_: prev: {
        go-mockery = prev.go-mockery.overrideAttrs (_: rec {
          version = "3.8.1";

          src = prev.fetchFromGitHub {
            owner = "vektra";
            repo = "mockery";
            tag = "v${version}";
            hash = "sha256-HCbnifYWE/3CG85dt0FPWT9hLSQbgOXuOKTBJHO0S2U=";
          };

          vendorHash = "sha256-ksfAHdPdOd8ELS0CSBg+E7KPd5xX/uGeLPn9HiItjdI=";
        });
      })
    ];
  };

  agents = inputs.llm-agents.packages.${system};
in
{
  # Ordinary packages use stable pkgs. These are the exceptions.
  inherit (upstream) codegraph lan-mouse noctalia-greeter;
  inherit (unstable) godot_4;
  inherit (seshPackages) sesh;
  inherit (vesktopPackages) vesktop;

  inherit (agents)
    antigravity-cli
    chatgpt
    claude-code
    codex
    opencode
    orca
    ;
  bb = agents.bb-app;
  noctalia = inputs.noctalia.packages.${system}.default;
  sonora = inputs.sonora.packages.${system}.default;
  voxtype = inputs.voxtype.packages.${system}.vulkan;
}
