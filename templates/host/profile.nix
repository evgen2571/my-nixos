{ ... }:

{
  # Use moduleProfiles.all in flake/hosts.nix, then uncomment your choices.
  # Optional features stay disabled; modules are discovered automatically.
  my = {
    desktop = {
      # gnome.enable = true;
      # niri.enable = true;
      # noctaliaGreeter.enable = true; # Defaults to the Niri session.
      # opentabletdriver.enable = true;
      # xserver.enable = true;
    };

    hardware = {
      # bluetooth.enable = true;
      # bluetooth.powerOnBoot = true;
      # nvidia.enable = true; # Requires allowing NVIDIA's unfree driver.
      # screenRecorder.enable = true;
    };

    system = {
      apps = {
        # libreoffice.enable = true;
        # lutris.enable = true;
        # obs.enable = true;
        # steam.enable = true;
        # vesktop.enable = true;
        # waydroid.enable = true;
      };

      dev = {
        # docker.enable = true;
        # fish.enable = true; # Also set my.primaryUser.shell = pkgs.fish.
      };

      files = {
        # thunar.enable = true;
      };

      services = {
        # blueman.enable = true; # Also enable hardware.bluetooth above.
        # lanMouse.enable = true;
        # sunshine.enable = true;
        # syncthing.enable = true; # Choose this or server.syncthing below.
        # virtualization.enable = true; # Add the user to libvirtd.

        tailscale = {
          # enable = true;
          # openFirewall = true; # Opens only Tailscale's UDP transport port.
        };

        # Read modules/services/network-namespaces/README.md before enabling.
        networkNamespaces = {
          # enable = true;
          namespaces.vpn = {
            # enable = true;
            # bootstrapTokenFile = "/run/secrets/hide-me-bootstrap";
            # shared.role = "standalone"; # Or configure a gateway/client.
          };
        };
      };
    };

    server = {
      # base.enable = true;
      # dockerHost.enable = true; # Requires storage.enable; adds Docker access.
      # syncthing.enable = true; # Requires storage.enable and a real device.

      ssh = {
        # enable = true;
        openOnLan = false; # Set an explicit reachable SSH firewall policy.
      };

      storage = {
        # enable = true;
        # Set a stable /dev/disk/by-uuid/ or by-label/ path before using a disk.
        # device = "/dev/disk/by-uuid/REPLACE-ME";
      };
    };
  };

  my.primaryUser.home.settings = {
    # wallpapers.enable = true;

    my.user = {
      ai = {
        # codegraph.enable = true;
        # llamaCpp.enable = true;
        # opencode.enable = true;
        # skillshare.enable = true;

        codex = {
          # enable = true;
          # networkNamespace = "vpn"; # Requires the enabled system namespace.
        };

        orca = {
          # enable = true;
          # networkNamespace = "vpn"; # Adds the isolated orca-vpn launcher.
        };
      };

      apps = {
        # anki.enable = true;
        # bruno.enable = true;
        # chrome.enable = true;
        # krita.enable = true;
        # mpv.enable = true;
        # obsidian.enable = true;
        # osuLazer.enable = true;
        # prismLauncher.enable = true;
        # qimgv.enable = true;
        # telegram.enable = true;
        # voxtype.enable = true;
        # youtubeMusic.enable = true;

        zenBrowser = {
          # enable = true;
          # profilePath = "abcdefgh.Default Profile"; # Check about:profiles first.
        };
      };

      desktop = {
        niriConfig = {
          # enable = true; # Pair with my.desktop.niri above.
          workspaceProfile = "default"; # Also available: pc, laptop.
        };

        noctalia = {
          # enable = true;
          profile = "pc"; # Bar/widget layout: pc or laptop; adjust for your displays.
        };

        # screenRecorder.enable = true; # Pair with hardware.screenRecorder above.
      };

      dev = {
        # Bundles: workstation enables common tools; individual settings override it.
        # workstation.enable = true;
        # terminalWorkflow.enable = true;
        # toolchains.enable = true;

        # bb.enable = true;
        # ffmpeg.enable = true;
        # fish.enable = true;
        # git.enable = true; # Set your Git identity in configuration.nix.
        # github.enable = true;
        # kitty.enable = true;
        # kitty.fontSize = "17.0";
        # neovim.enable = true;
        # pycharm.enable = true;
        # starship.enable = true;
        # tmux.enable = true;
        # vscode.enable = true;
        # zed.enable = true;
        # zoxide.enable = true;

        # SSH aliases are always configured by the imported SSH module.
        # ssh.serverHost = "your-server";
        # ssh.serverIdentityFile = "~/.ssh/id_ed25519";

        languages = {
          # cpp.enable = true;
          # godot.enable = true;
          # java.enable = true;
          # python.enable = true;
          # rust.enable = true;
        };
      };

      files = {
        # dolphin.enable = true;
        # dolphin.places = [ ]; # null (the default) leaves bookmarks unmanaged.
        # yazi.enable = true;
      };
    };
  };
}
