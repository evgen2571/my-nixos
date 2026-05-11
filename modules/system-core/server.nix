{ ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Minsk";
  i18n.defaultLocale = "en_US.UTF-8";

  nix.settings = {
    max-jobs = 1;
    cores = 2;
    eval-cache = true;
    substituters = [ "https://cache.nixos.org" ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };
}
