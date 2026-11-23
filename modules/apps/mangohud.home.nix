{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.user.apps.mangohud;

  toggleHud = pkgs.writeShellScriptBin "mangohud-toggle" ''
    ${lib.getExe pkgs.python3} - <<'PY'
    import socket

    try:
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
            sock.settimeout(1)
            sock.connect("\0mangohud")
            sock.recv(4096)
            sock.sendall(b":hud;")
    except OSError:
        pass
    PY
  '';
in
{
  options.my.user.apps.mangohud.enable = lib.mkEnableOption "MangoHud performance overlay";

  config = lib.mkIf cfg.enable {
    programs.mangohud = {
      enable = true;
      enableSessionWide = false;

      settings = {
        position = "top-left";
        no_display = true;

        fps = true;
        frame_timing = true;

        gpu_stats = true;
        gpu_temp = true;
        vram = true;

        cpu_stats = true;
        ram = true;

        wine = true;
        winesync = true;

        toggle_hud = "Shift_R+F12";
        control = "mangohud";
      };
    };

    home.packages = [ toggleHud ];
  };
}
