{ config, pkgs, lib, inputs,... }:

{
networking.wg-quick.interfaces.protonvpn = {
  autostart = true;
  address = [ "10.2.0.2/32" ];
  listenPort = 51820;
  privateKeyFile = "/root/secrets/protonvpn";
  dns = [ "10.2.0.1" ];
  peers = [
    {
      publicKey = "tWACDT8dLEyXVFh5xIwD7L8xuOG9bSUlQ2ZslGEAl8w=";
      allowedIPs = [ "0.0.0.0/0" "::/0" ];
      endpoint = "198.51.100.55:51820";
    }
  ];
};
}
