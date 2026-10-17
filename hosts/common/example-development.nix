{ ... }:

{
  networking.extraHosts = ''
    192.0.2.12 api.example.test auth.example.test
  '';

  security.pki.certificateFiles = [
    
  ];
}
