# Browser defaults only. Spaces, pins, and routing rules are private.
{
  userChrome = ./userChrome.css;

  settings = {
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    "browser.startup.page" = 3;
    "zen.pinned-tab-manager.restore-pinned-tabs-to-pinned-url" = false;
    "zen.pinned-tab-manager.close-shortcut-behavior" = "unload-switch";
    "zen.workspaces.continue-where-left-off" = true;
    "zen.window-sync.enabled" = true;

    "zen.view.use-single-toolbar" = false;
    "zen.view.sidebar-expanded" = true;

    "zen.widget.linux.transparency" = false;
    "browser.tabs.allow_transparent_browser" = false;
  };

  # Check zen.keyboard.shortcuts.version after Zen updates.
  keyboardShortcutsVersion = 21;

  keyboardShortcuts = [
    {
      id = "zen-compact-mode-toggle";
      key = "`";
      modifiers.control = true;
    }
  ];

  sine = {
    enable = true;
    mods = [ ];
  };

  # Don't overwrite spaces/pins created through the browser UI.
  spacesForce = false;
  pinsForce = false;
  spaceRouting = {
    force = false;
    defaultExternalRoute = "most-recent-space";
  };
}
