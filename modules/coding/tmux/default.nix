{
  config,
  pkgs,
  lib,
  ...
}:

{
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

      # Sessionizer
      bind -n C-o display-popup -E "${pkgs.tmux-sessionizer}/bin/tms"
      bind C-j display-popup -E "${pkgs.tmux-sessionizer}/bin/tms switch"
      bind C-w display-popup -E "${pkgs.tmux-sessionizer}/bin/tms windows"
      bind C-r command-prompt -p "Rename active session to: " "run-shell '${pkgs.tmux-sessionizer}/bin/tms rename %%1'"

      # Utilities
      bind E show-environment -g
      bind G new-window -n "lazygit" ${pkgs.lazygit}/bin/lazygit

      # Easy pane splitting
      bind \\ split-window -h
      bind - split-window -v

      # minimal-tmux-status options
      set -g @minimal-tmux-status "top"
      set -g @minimal-tmux-bg "default"
      set -g @minimal-tmux-justify absolute-centre
      set -g @minimal-tmux-fg "#ffffff"
      set -g window-status-style 'fg=#4a4a4a'
    '';

    plugins = with pkgs; [
      tmuxPlugins.minimal-tmux-status
      tmuxPlugins.vim-tmux-navigator
    ];
  };

  home.packages = with pkgs; [
    tmux
    git
    bash
    fish
    tmux-sessionizer
    lazygit
  ];
}
