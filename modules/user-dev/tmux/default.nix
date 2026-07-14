{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.my.user.dev.tmux;

  devSession = pkgs.writeShellApplication {
    name = "tmux-dev-session";
    runtimeInputs = with pkgs; [
      coreutils
      fd
      fzf
      neovim
      openssh
      tmux
    ];
    text = ''
      set -euo pipefail

      project_root="${cfg.devSession.projectRoot}"
      remote_host="${cfg.devSession.remoteHost}"
      remote_project_root="${cfg.devSession.remoteProjectRoot}"
      remote_command="${cfg.devSession.remoteCommand}"

      project_dir="''${1:-}"
      if [[ -z "$project_dir" ]]; then
        project_dir="$({ fd --type d --max-depth 1 --hidden --exclude .git . "$project_root" || true; } | fzf --prompt='Project > ' --height=100% --reverse)"
      fi

      [[ -n "$project_dir" ]] || exit 0
      [[ -d "$project_dir" ]] || { printf 'Project directory does not exist: %s\\n' "$project_dir" >&2; exit 1; }

      project_name="$(basename "$project_dir")"
      session_name="''${project_name//[^a-zA-Z0-9_.-]/-}"
      remote_target="$remote_project_root/$project_name"

      switch_or_attach() {
        if [[ -n "''${TMUX:-}" ]]; then
          tmux switch-client -t "$session_name"
        else
          tmux attach-session -t "$session_name"
        fi
      }

      if tmux has-session -t "$session_name" 2>/dev/null; then
        switch_or_attach
        exit 0
      fi

      # Window 1: editor. When nvim exits, leave a shell in the window.
      tmux new-session -d \
        -s "$session_name" \
        -n editor \
        -c "$project_dir" \
        "nvim; exec \"''${SHELL:-bash}\""

      # Window 2: clean project terminal.
      tmux new-window \
        -t "$session_name" \
        -n shell \
        -c "$project_dir"

      # Window 3: remote agent terminal in the matching project directory.
      tmux new-window \
        -t "$session_name" \
        -n agent \
        -c "$project_dir" \
        "ssh -t \"$remote_host\" \"cd $remote_target && exec $remote_command\""

      tmux select-window -t "$session_name:editor"
      switch_or_attach
    '';
  };
in
{
  options.my.user.dev.tmux = {
    enable = lib.mkEnableOption "tmux";

    devSession = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable the project session launcher with editor, shell, and remote agent windows.";
      };
      projectRoot = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/dev";
        description = "Directory containing project directories shown by the project picker.";
      };
      remoteHost = lib.mkOption {
        type = lib.types.str;
        default = "agent";
        description = "SSH host used by the agent window.";
      };
      remoteProjectRoot = lib.mkOption {
        type = lib.types.str;
        default = "${config.home.homeDirectory}/dev";
        description = "Project root on the SSH host. Use an absolute path when the SSH host has a different home directory.";
      };
      remoteCommand = lib.mkOption {
        type = lib.types.str;
        default = "hermes";
        description = "Interactive command started in the remote agent window.";
      };
    };
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

        # Project session launcher / tms session controls
        ${lib.optionalString cfg.devSession.enable ''
          bind -n C-o display-popup -E "${devSession}/bin/tmux-dev-session"
        ''}
        bind C-j display-popup -E "${pkgs.tmux-sessionizer}/bin/tms switch"
        bind C-w display-popup -E "${pkgs.tmux-sessionizer}/bin/tms windows"
        bind C-r command-prompt -p "Rename active session to: " "run-shell '${pkgs.tmux-sessionizer}/bin/tms rename %%1'"

        # Utilities
        bind E show-environment -g
        bind G new-window -n "lazygit" ${pkgs.lazygit}/bin/lazygit

        # Easy pane splitting
        bind-key \\ split-window -h
        bind-key - split-window -v
      '';
    };

    home.packages =
      with pkgs;
      [
        tmux
      ]
      ++ lib.optional cfg.devSession.enable devSession;
  });
}
