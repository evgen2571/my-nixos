{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.my.user.dev.tmux;

  unstable = import inputs.nixpkgs-unstable {
    system = pkgs.stdenv.hostPlatform.system;
    config = {
      allowUnfree = true;
    };
  };

  sesh = unstable.sesh;

  seshRemoteWindow = pkgs.writeShellApplication {
    name = "sesh-remote-window";
    runtimeInputs = [ pkgs.openssh ];
    text = ''
      project_dir="$(basename -- "$PWD")"
      printf -v remote_command 'cd %q && exec hermes' "dev/$project_dir"
      exec ssh -tt agent@hermes-host "$remote_command"
    '';
  };

  seshConfig =
    builtins.replaceStrings [ "@SESH_REMOTE_WINDOW@" ] [ "${seshRemoteWindow}/bin/sesh-remote-window" ]
      (builtins.readFile ../../../config/sesh/sesh.toml);
in
{
  options.my.user.dev.tmux = {
    enable = lib.mkEnableOption "tmux";

  };

  config = lib.mkIf cfg.enable ({
    programs.tmux = {
      enable = true;

      shell = "${pkgs.fish}/bin/fish";
      terminal = "tmux-256color";
      escapeTime = 0;
      focusEvents = true;
      mouse = true;
      historyLimit = 50000;
      keyMode = "vi";
      prefix = "C-Space";
      baseIndex = 1;
      clock24 = true;

      sensibleOnTop = false;

      plugins = with pkgs; [
        {
          plugin = tmuxPlugins.minimal-tmux-status;
          extraConfig = ''
            set -g @minimal-tmux-status "top"
            set -g @minimal-tmux-bg "default"
            set -g @minimal-tmux-justify "absolute-centre"
            set -g @minimal-tmux-fg "#ffffff"
            set -g window-status-style 'fg=#4a4a4a'
          '';
        }
        tmuxPlugins.vim-tmux-navigator
      ];

      extraConfig = ''
        # Prefix
        bind C-Space send-prefix

        # True color
        set -ag terminal-overrides ",xterm-256color:RGB"
        set -ag terminal-overrides ",*:Tc"

        # Window numbering
        set -g pane-base-index 1
        set-option -g renumber-windows on

        # Reload / toggle status
        bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded!"
        bind b set-option status

        # Use tmux's default popup geometry. The popup exits after sesh
        # attaches to or creates the selected session.
        bind -n C-o display-popup -E "${sesh}/bin/sesh picker -i"
        bind C-j display-popup -E "${sesh}/bin/sesh picker -i"
        bind C-w display-popup -E "${sesh}/bin/sesh window"
        bind C-r command-prompt -p "Rename active session to: " "rename-session %%1"

        # Utilities
        bind E show-environment -g
        bind G new-window -n "lazygit" ${pkgs.lazygit}/bin/lazygit

        # Easy pane splitting
        bind-key \\ split-window -h
        bind-key - split-window -v
      '';
    };

    home.packages = with pkgs; [
      sesh
      tmux
    ];

    xdg.configFile."sesh/sesh.toml".text = seshConfig;
  });
}
