{
  lib,
  stdenvNoCC,
  fetchurl,
  gnutar,
  gzip,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "skillshare";
  version = "0.25.8";

  # SHA-256 published in runkids/homebrew-tap's official Skillshare formula.
  # This is the upstream static (CGO_ENABLED=0) Linux x86_64 CLI release.
  src = fetchurl {
    url = "https://github.com/runkids/skillshare/releases/download/v${finalAttrs.version}/skillshare_${finalAttrs.version}_linux_amd64.tar.gz";
    sha256 = "61bfa1ec40ad9714027eab7b76d42ff35515d1ff87fd7f08d73a53507b1f30b3";
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
