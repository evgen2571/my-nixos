{ pkgs, ... }:

{
  home.packages = with pkgs; [
    gpu-screen-recorder
  ];
}
