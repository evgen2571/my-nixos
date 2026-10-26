{ ... }:

{
  # Use moduleProfiles.all in flake/hosts.nix, then uncomment your choices.
  # Optional features stay disabled; modules are discovered automatically.
  my = {
    desktop = {
      # gnome.enable = true;
      # niri.enable = true; # See hosts/README.md for a minimal user config.
      # umbriel.enable = true;
      # noctaliaGreeter.enable = true; # Defaults to Umbriel when enabled, otherwise Niri.
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
        # browserVpnProxy.enable = true; # Requires an existing client VPN namespace.
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
        # sonora.enable = true;
        # telegram.enable = true;
        # voxtype.enable = true;
        # youtubeMusic.enable = true;

        zenBrowser = {
          # enable = true;
          # profilePath = "abcdefgh.Default Profile"; # Check about:profiles first.
          # vpnProxy.enable = true; # Requires system browserVpnProxy and profilePath.
          # vpnProxy.domains = [ "example.com" ]; # Includes subdomains.
        };
      };

      desktop = {
        niriConfig = {
          # enable = true; # My full config; includes personal app shortcuts/outputs.
          workspaceProfile = "default"; # Also available: pc, laptop.
        };

        # noctalia.enable = true;
        # umbrielConfig.enable = true; # Personal PC outputs, rules, and scratchpads.

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

        # ssh.enable = true; # Optional GitHub/server client aliases.
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
