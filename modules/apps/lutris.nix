{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    (lutris.override {
      extraPkgs = pkgs: [
        wineWowPackages.stagingFull
        winetricks
      ];
    })
  ];
}
