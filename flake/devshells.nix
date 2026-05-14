{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          deadnix
          git
          nil
          nixd
          nixfmt-rfc-style
          statix
        ];
      };
    };
}
