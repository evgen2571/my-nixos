{ config, lib, ... }:

let 
	host = config.networking.hostName;
in
{
  programs.niri.settings.input = {
    focus-follows-mouse = true;
    workspace-auto-back-and-forth = true;
    warp-mouse-to-focus = true;

    keyboard = {
      xkb = {
        layout = "us,ru";
        variant = ",phonetic";
        options = "grp:alt_shift_toggle,caps:swapescape";
      };

      repeat-delay = 250;
      repeat-rate = 35;
    };

    touchpad = lib.mkIf (host == "nixos-lp") {
      tap = true;
      natural-scroll = true;
      scroll-method = "two-finger";
      scroll-factor = 0.40;
    };

    mouse = {
      scroll-factor = 1.0;
    };
  };
}
