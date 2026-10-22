{
  lib,
  buildGoModule,
  fetchFromGitHub,
  makeWrapper,
  cacert,
}:

# Upstream's installer changes /opt and systemd. Build only the client and
# install its pinned TLS trust resource; mutable authentication lives elsewhere.
buildGoModule {
  pname = "hide-me";
  version = "0.9.14";

  src = fetchFromGitHub {
    owner = "eventure";
    repo = "hide.client.linux";
    rev = "85463073f45872b6ab103fa7a007fd0672384d57";
    hash = "sha256-DLFfcUNnPRMxiv/OrJI0IqvdSn6CgVvdsQ5chVTZnIk=";
  };

  vendorHash = "sha256-GDpGJFSvoPWkrgjNuMCoHNzTbiZTZUBtnIssduvRI+s=";
  subPackages = [ "." ];
  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    mv "$out/bin/hide.client.linux" "$out/bin/hide.me"
    install -Dm444 CA.pem "$out/share/hide-me/CA.pem"
    wrapProgram "$out/bin/hide.me" \
      --add-flags "--ca $out/share/hide-me/CA.pem" \
      --set-default SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt"
  '';

  meta = {
    description = "Official hide.me WireGuard VPN client with dynamic credential negotiation";
    homepage = "https://github.com/eventure/hide.client.linux";
    license = lib.licenses.gpl2Only;
    platforms = lib.platforms.linux;
    mainProgram = "hide.me";
  };
}
