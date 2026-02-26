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
      publicKey = "+bLlZyXzg3fqOcI7d41IYI4LON2+oDm3Yv6y8lNQWE4=";
      allowedIPs = [ "0.0.0.0/0" "::/0" ];
      endpoint = "169.150.218.55:51820";
    }
  ];
};
}
