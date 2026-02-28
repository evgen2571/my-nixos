{ config, lib, ... }:

let
  host = config.networking.hostName;
in
{
  programs.niri.settings.binds = 
  lib.mkMerge [

	{
    ########################
    # Overview
    ########################

    "Mod+Tab" = {
      repeat = false;
      action.toggle-overview = null;
    };

    ########################
    # Apps
    ########################

    "Mod+Return" = {
      repeat = false;
      hotkey-overlay-title = "Terminal";
      action.spawn-sh = "kitty";
    };

    "Mod+Shift+Return" = {
      repeat = false;
      hotkey-overlay-title = "Dropdown Terminal";
      action.spawn-sh = "kitty -T dropdown-term";
    };

    "Mod+F" = {
      repeat = false;
      hotkey-overlay-title = "Browser";
      action.spawn-sh = "zen-twilight";
    };

    "Mod+E" = {
      repeat = false;
      hotkey-overlay-title = "File Manager";
      action.spawn-sh = "dolphin";
    };

    "Mod+C" = {
      repeat = false;
      hotkey-overlay-title = "Editor";
      action.spawn-sh = "kitty -T editor tms";
    };

    "Mod+O" = {
      repeat = false;
      hotkey-overlay-title = "Notetaker";
      action.spawn-sh = "obsidian";
    };

    ########################
    # Noctalia
    ########################

    "Mod+Comma".action.spawn-sh =
      "noctalia-shell ipc call settings toggle";

    "Mod+Space".action.spawn-sh =
      "noctalia-shell ipc call launcher toggle";

    "Mod+V".action.spawn-sh =
      "noctalia-shell ipc call launcher clipboard";

    "Mod+Y".action.spawn-sh =
      "noctalia-shell ipc call wallpaper toggle";

    "Mod+P".action.spawn-sh =
      "noctalia-shell ipc call sessionMenu toggle";

    "Mod+Alt+L".action.spawn-sh =
      "noctalia-shell ipc call sessionMenu lockAndSuspend";

    "Ctrl+Shift+Escape".action.spawn-sh =
      "noctalia-shell ipc call systemMonitor toggle";

    ########################
    # Noctalia Plugins
    ########################

	#

    ########################
    # Volume
    ########################

    "XF86AudioRaiseVolume" = {
      allow-when-locked = true;
      action.spawn-sh =
        "noctalia-shell ipc call volume increase 3";
    };

    "XF86AudioLowerVolume" = {
      allow-when-locked = true;
      action.spawn-sh =
        "noctalia-shell ipc call volume decrease 3";
    };

    "XF86AudioMute" = {
      allow-when-locked = true;
      action.spawn-sh =
        "noctalia-shell ipc call volume mute";
    };

    "XF86AudioMicMute" = {
      allow-when-locked = true;
      action.spawn-sh =
        "noctalia-shell ipc call audio micmute";
    };

    ########################
    # Media
    ########################

    "XF86AudioPlay" = {
      allow-when-locked = true;
      action.spawn-sh =
        "noctalia-shell ipc call media playPause";
    };

    "XF86AudioPause" = {
      allow-when-locked = true;
      action.spawn-sh =
        "noctalia-shell ipc call media playPause";
    };

    "XF86AudioNext" = {
      allow-when-locked = true;
      action.spawn-sh =
        "noctalia-shell ipc call media next";
    };

    "XF86AudioPrev" = {
      allow-when-locked = true;
      action.spawn-sh =
        "noctalia-shell ipc call media previous";
    };

    ########################
    # Brightness
    ########################

    "XF86MonBrightnessUp" = {
      allow-when-locked = true;
      action.spawn-sh =
        "noctalia-shell ipc call brightness increase 5";
    };

    "XF86MonBrightnessDown" = {
      allow-when-locked = true;
      action.spawn-sh =
        "noctalia-shell ipc call brightness decrease 5";
    };

    ########################
    # Screenshot
    ########################

	"Mod+Shift+S" = {
	  repeat = false;
	  action.screenshot = null;
	};

    ########################
    # Window Management
    ########################

    "Mod+Q" = {
      repeat = false;
      action.close-window = null;
    };

    "Mod+A".action.maximize-column = null;
    "Mod+Z".action.fullscreen-window = null;
    "Mod+Alt+Space".action.toggle-window-floating = null;
    "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = null;
    "Mod+W".action.toggle-column-tabbed-display = null;

    ########################
    # Focus Navigation
    ########################

    "Mod+Left".action.focus-column-left = null;
    "Mod+Right".action.focus-column-right = null;
    "Mod+Up".action.focus-window-up = null;
    "Mod+Down".action.focus-window-down = null;

    "Mod+H".action.focus-column-left = null;
    "Mod+L".action.focus-column-right = null;
    "Mod+K".action.focus-window-up = null;
    "Mod+J".action.focus-window-down = null;

    ########################
    # Numbered Workspaces
    ########################

    "Mod+1".action.focus-workspace = 1;
    "Mod+2".action.focus-workspace = 2;
    "Mod+3".action.focus-workspace = 3;
    "Mod+4".action.focus-workspace = 4;
    "Mod+5".action.focus-workspace = 5;
    "Mod+6".action.focus-workspace = 6;
    "Mod+7".action.focus-workspace = 7;
    "Mod+8".action.focus-workspace = 8;
    "Mod+9".action.focus-workspace = 9;

    "Mod+Shift+1".action.move-column-to-workspace = 1;
    "Mod+Shift+2".action.move-column-to-workspace = 2;
    "Mod+Shift+3".action.move-column-to-workspace = 3;
    "Mod+Shift+4".action.move-column-to-workspace = 4;
    "Mod+Shift+5".action.move-column-to-workspace = 5;
    "Mod+Shift+6".action.move-column-to-workspace = 6;
    "Mod+Shift+7".action.move-column-to-workspace = 7;
    "Mod+Shift+8".action.move-column-to-workspace = 8;
    "Mod+Shift+9".action.move-column-to-workspace = 9;

	} (lib.mkIf (host == "nixos-pc") {

    ########################
    # Monitor Movement
    ########################


    "Mod+Ctrl+Left".action.focus-monitor-left = null;
    "Mod+Ctrl+Right".action.focus-monitor-right = null;

    "Mod+Ctrl+H".action.focus-monitor-left = null;
    "Mod+Ctrl+L".action.focus-monitor-right = null;

    "Mod+X".action.focus-monitor-next = null;

    "Mod+Ctrl+Shift+Left".action.move-column-to-monitor-left = null;
    "Mod+Ctrl+Shift+Right".action.move-column-to-monitor-right = null;

    "Mod+Ctrl+Shift+H".action.move-column-to-monitor-left = null;
    "Mod+Ctrl+Shift+L".action.move-column-to-monitor-right = null;

    # Focus specific monitor by name
    "Mod+F1".action.focus-monitor = "DP-1";
    "Mod+F2".action.focus-monitor = "HDMI-A-1";
	})

  ];
}
