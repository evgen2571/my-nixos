{ pkgs, ... }:

{
  home.packages = with pkgs; [
    llama-cpp
  ];
}
