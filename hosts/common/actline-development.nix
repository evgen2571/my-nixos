{ ... }:

{
  networking.extraHosts = ''
    100.112.239.4 api.actline.test auth.actline.test
  '';

  security.pki.certificateFiles = [
    ../pc/certs/actline-dev-rootCA.pem
  ];
}
