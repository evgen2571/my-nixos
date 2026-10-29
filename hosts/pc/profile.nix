{
  config,
  configPaths,
  lib,
  ...
}:

{
  services.udisks2.enable = true;

  my = {
    desktop = {
      gnome.enable = false;
      niri.enable = true;
      umbriel.enable = true;
      noctaliaGreeter.enable = true;
      opentabletdriver.enable = true;
    };

    hardware = {
      bluetooth.enable = true;
      nvidia.enable = true;
      screenRecorder.enable = true;
    };

    system = {
      apps = {
        libreoffice.enable = true;
        steam.enable = true;
        obs.enable = false;
        vesktop.enable = true;
      };

      dev = {
        docker.enable = true;
        fish.enable = true;
      };

      files.thunar.enable = false;

      services = {
        browserVpnProxy.enable = true;
        lanMouse.enable = true;
        tailscale.enable = true;
        blueman.enable = true;
        syncthing.enable = true;

        networkNamespaces = {
          enable = true;

          namespaces.vpn = {
            enable = true;

            shared = {
              role = "client";

              privateKeyFile = (
                config.sops.secrets.vpn-wireguard-private-key.path or "/run/my-nixos-unavailable/wireguard"
              );

              address = "10.77.0.2/24";
              address6 = "fd77::2/64";
            };
          };
        };

        virtualization.enable = false;
        sunshine.enable = false;
      };
    };
  };

  my.primaryUser.home.settings = {
    imports = [ ./home.nix ];
    wallpapers.enable = true;
  };

  my.primaryUser.home.settings.programs.noctalia.settings.include.files = lib.mkDefault [
    "${configPaths.wm.noctaliaConfigDir}/widgets-pc.toml"
  ];

  my.primaryUser.home.settings.my.user = {
    ai = {
      opencode.enable = true;
      skillshare.enable = true;
      codegraph.enable = true;

      antigravityCli.enable = true;
      chatgpt.enable = true;
      claudeCode.enable = true;
      codex.enable = true;
      orca.enable = true;
    };

    apps = {
      anki.enable = true;
      bruno.enable = false;
      chrome.enable = false;
      ciscoPacketTracer.enable = true;
      krita.enable = true;
      mpv.enable = true;
      obsidian.enable = true;
      osuLazer.enable = false;
      prismLauncher.enable = true;
      qimgv.enable = true;
      sonora.enable = true;
      telegram.enable = true;
      youtubeMusic.enable = false;
      voxtype.enable = false;
      zenBrowser.enable = true;
    };

    desktop = {
      niriConfig = {
        enable = true;
        workspaceProfile = "pc";
      };

      umbrielConfig.enable = true;

      noctalia.enable = true;
      skwdWall.enable = true;

      screenRecorder.enable = true;
    };

    dev = {
      ssh.enable = true;
      ffmpeg.enable = true;
      workstation.enable = true;

      languages = {
        cpp.enable = true;
        java.enable = true;
        godot.enable = false;
        python.enable = true;
        rust.enable = true;
      };
    };

    files = {
      dolphin.enable = true;
      yazi.enable = true;
    };
  };
}
