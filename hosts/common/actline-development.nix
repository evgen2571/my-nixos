{ ... }:

{
  networking.extraHosts = ''
    100.112.239.4 api.actline.test auth.actline.test
  '';

  security.pki.certificateFiles = [
    ./certs/actline-dev-rootCA.pem
  ];
}
