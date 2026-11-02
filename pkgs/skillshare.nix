{
  lib,
  stdenvNoCC,
  fetchurl,
  gnutar,
  gzip,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "skillshare";
  version = "0.28.2";

  # Official Linux x86_64 release archive.
  src = fetchurl {
    url = "https://github.com/runkids/skillshare/releases/download/v${finalAttrs.version}/skillshare_${finalAttrs.version}_linux_amd64.tar.gz";
    sha256 = "f5a1695b5fdd2b2def44aa6dfb6a3df6ac8bd907770fa6090dc8a37835a7f19b";
  };

  nativeBuildInputs = [
    gnutar
    gzip
  ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    tar -xzf "$src" -C "$out/bin" skillshare
    chmod 0755 "$out/bin/skillshare"
    runHook postInstall
  '';

  meta = {
    description = "Sync skills and agent resources across AI coding tools";
    homepage = "https://github.com/runkids/skillshare";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "skillshare";
  };
})
