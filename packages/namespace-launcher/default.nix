{
  lib,
  stdenv,
  targets,
  sudoPath ? "/run/wrappers/bin/sudo",
}:

stdenv.mkDerivation {
  pname = "namespace-launcher";
  version = "1";
  src = ./.;
  dontConfigure = true;

  targetsHeader = ''
    static const struct target targets[] = {
      ${lib.concatMapStringsSep "\n" (
        t:
        "{ ${
          lib.concatMapStringsSep ", " builtins.toJSON [
            t.id
            t.namespace
            t.user
            t.executable
            t.check
          ]
        }, },"
      ) targets}
      { NULL, NULL, NULL, NULL, NULL }
    };
  '';

  passAsFile = [ "targetsHeader" ];

  buildPhase = ''
    runHook preBuild
    cp "$targetsHeaderPath" targets.h
    mkdir -p "$out/bin"
    $CC -std=c11 -O2 -Wall -Wextra -Werror enter.c -o "$out/bin/namespace-enter"
    $CC -std=c11 -O2 -Wall -Wextra -Werror \
      -DENTER_PATH='"'"$out/bin/namespace-enter"'"' \
      -DSUDO_PATH=${lib.escapeShellArg (builtins.toJSON sudoPath)} \
      client.c -o "$out/bin/namespace-launch"
    runHook postBuild
  '';

  dontInstall = true;

  meta = {
    description = "Restricted namespace entry with complete privilege drop before app execution";
    platforms = lib.platforms.linux;
    mainProgram = "namespace-launch";
  };
}
