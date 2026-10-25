# Copy to hosts/<name>/ and generate hardware-configuration.nix for that machine.
{ config, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./profile.nix
    ../../modules/core/primary-user.nixos.nix
  ];

  networking.hostName = "replace-me";
  # Copy your working bootloader settings here. For a fresh UEFI installation:
  # boot.loader.systemd-boot.enable = true;
  # boot.loader.efi.canTouchEfiVariables = true;
  networking.networkmanager.enable = true;
  time.timeZone = "UTC";
  i18n.defaultLocale = "en_US.UTF-8";
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  # Existing installs: keep both state versions at their previous values.
  system.stateVersion = "26.05";

  my.primaryUser = {
    enable = true;
    name = "operator"; # Choose your own login name; HOME and HM follow it.
    # Optional Git identity (enable my.user.dev.git in profile.nix):
    # git.userName = "Example Person";
    # git.userEmail = "person@example.invalid";
    # git.signingKey = "~/.ssh/id_ed25519_signing.pub";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
    home.settings.home.stateVersion = "26.05";
    # Optional SSH PUBLIC keys; the SSH server stays off unless enabled.
    authorizedKeys = [ ];
  };

  users.mutableUsers = false;
  # A root-owned runtime file, NOT a Nix path. Create it before activation.
  users.users.${config.my.primaryUser.name}.hashedPasswordFile = "/var/lib/my-nixos/login-password";

  assertions = [
    {
      assertion = config.networking.hostName != "replace-me";
      message = "New host: set networking.hostName in configuration.nix before building.";
    }
  ];
}
