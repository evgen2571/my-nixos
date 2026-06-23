{
  config,
  configPaths,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.my.user.desktop.noctalia;
  noctaliaPackage = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  noctaliaShellPackage = pkgs.symlinkJoin {
    name = "noctalia-shell-${noctaliaPackage.version or "unstable"}";
    paths = [ noctaliaPackage ];
    postBuild = ''
      if [ -e "$out/bin/noctalia" ] && [ ! -e "$out/bin/noctalia-shell" ]; then
        ln -s noctalia "$out/bin/noctalia-shell"
      fi
    '';
    meta = (noctaliaPackage.meta or { }) // {
      mainProgram = "noctalia-shell";
    };
  };
in
{
  imports = [
    inputs.noctalia.homeModules.default
    (lib.mkAliasOptionModule [ "programs" "noctalia-shell" ] [ "programs" "noctalia" ])
    ./config.nix
  ];

  options.my.user.desktop.noctalia.enable = lib.mkEnableOption "Noctalia shell";

  config = lib.mkIf cfg.enable {
    programs.noctalia = {
      enable = true;
      package = noctaliaShellPackage;
      systemd.enable = true;
    };
  };
}
