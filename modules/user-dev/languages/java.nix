{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.my.user.dev.languages.java;
in
{
  options.my.user.dev.languages.java.enable = lib.mkEnableOption "Java development";

  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      jdk21
      jdt-language-server

      maven
      gradle

      google-java-format
    ];

    home.sessionVariables = {
      JAVA_HOME = "${pkgs.jdk21}";
      JDTLS_HOME = "${pkgs.jdt-language-server}/share/java/jdtls";
    };
  };
}
