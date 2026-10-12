{ pkgs }:
let
  probe = pkgs.writeScript "namespace-launcher-probe" ''
    #!${pkgs.python3}/bin/python3
    import json, os, signal, subprocess, sys, time
    if sys.argv[1:] == ["--wait"]:
        signal.signal(signal.SIGTERM, lambda *_: sys.exit(42))
        print("ready", flush=True)
        while True: time.sleep(1)
    result = {"uid": os.getuid(), "gid": os.getgid(), "groups": os.getgroups(),
              "netns": os.readlink("/proc/self/ns/net")}
    if sys.argv[1:] != ["--child"]:
        result.update({"args": sys.argv[1:], "stdin": sys.stdin.read(), "cwd": os.getcwd(),
                       "env": {k: os.environ.get(k) for k in ["TEST_VALUE", "CODEX_HOME", "SSH_AUTH_SOCK", "SUDO_UID"]},
                       "dns": open("/etc/resolv.conf").read(),
                       "status": {line.split(":")[0]: line.split(":")[1].strip()
                                  for line in open("/proc/self/status") if line.startswith(("Cap", "NoNewPrivs:"))},
                       "project": open("project.txt").read(),
                       "child": json.loads(subprocess.check_output([sys.argv[0], "--child"]))})
        open("created.txt", "w").write("normal user")
    print(json.dumps(result))
    sys.exit(0 if sys.argv[1:] == ["--child"] else 37)
  '';
  check = pkgs.writeShellScript "namespace-launcher-test-ready" ''
    test -f /run/network-namespaces/vpn/ready
  '';
  # Adapter for tests only. Production uses the real sudo binary and policy.
  sudo = pkgs.writeScript "namespace-launcher-test-sudo" ''
    #!${pkgs.python3}/bin/python3
    import os, sys
    assert sys.argv[1:5] == ["-n", "-C", "4", "--"]
    os.execve(sys.argv[5], sys.argv[5:], {"SUDO_UID": "1000", "SUDO_GID": "100"})
  '';
in
pkgs.callPackage ../../packages/namespace-launcher {
  sudoPath = toString sudo;
  targets = [
    {
      id = "probe";
      namespace = "vpn";
      user = "probe";
      executable = toString probe;
      check = toString check;
    }
  ];
}
