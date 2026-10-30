{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.system.services.networkNamespaces;
  apps = cfg.applications;

  userApps =
    lib.foldlAttrs
      (
        registrations: id: path:
        registrations
        //
          lib.mapAttrs'
            (
              user: hm:
              let
                app = lib.getAttrFromPath path hm.my.user;
              in
              lib.nameValuePair "${id}-${user}" {
                inherit user;
                namespace = app.networkNamespace;
                package = app.unwrappedPackage;
              }
            )
            (
              lib.filterAttrs (
                _: hm:
                let
                  app = lib.attrByPath path { } hm.my.user;
                in
                (app.enable or false) && (app.networkNamespace or null) != null
              ) (config.home-manager.users or { })
            )
      )
      { }
      {
        antigravity-cli = [
          "ai"
          "antigravityCli"
        ];
        chatgpt = [
          "ai"
          "chatgpt"
        ];
        claude-code = [
          "ai"
          "claudeCode"
        ];
        codex = [
          "ai"
          "codex"
        ];
        orca = [
          "ai"
          "orca"
        ];
        cisco-packet-tracer = [
          "apps"
          "ciscoPacketTracer"
        ];
      };

  targets = lib.mapAttrsToList (id: app: {
    inherit id;
    inherit (app) namespace user;
    executable = lib.getExe app.package;
    check = "/etc/network-namespaces/${app.namespace}-check";
  }) apps;

  launcher = pkgs.callPackage ../../../pkgs/namespace-launcher { inherit targets; };
in
{
  options.my.system.services.networkNamespaces = {
    applications = lib.mkOption {
      default = { };
      description = "Immutable app registrations authorized for namespace entry.";
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            namespace = lib.mkOption {
              type = lib.types.str;
              description = "Enabled VPN namespace name.";
            };

            user = lib.mkOption {
              type = lib.types.str;
              description = "Normal user allowed to execute this registration.";
            };

            package = lib.mkOption {
              type = lib.types.package;
              description = "Real application package; its main executable is fixed at build time.";
            };
          };
        }
      );
    };

    launcherPackage = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = launcher;
      description = "Unprivileged launcher and sudo-authorized entry helper generated from application registrations.";
    };
  };

  config = lib.mkIf cfg.enable {
    my.system.services.networkNamespaces.applications = userApps;

    assertions = lib.mapAttrsToList (id: app: {
      assertion =
        builtins.match "[a-zA-Z][a-zA-Z0-9_-]*" id != null
        && builtins.match "[a-z_][a-z0-9_-]*" app.user != null
        && (cfg.namespaces.${app.namespace}.enable or false)
        && (config.users.users.${app.user}.isNormalUser or false)
        && lib.hasPrefix "/nix/store/" (lib.getExe app.package);

      message = "Namespace application ${id} must name an enabled namespace, normal user and immutable application executable.";
    }) apps;

    environment.systemPackages = lib.optional (apps != { }) launcher;

    security.sudo.extraRules = lib.optionals (apps != { }) [
      {
        users = lib.unique (map (app: app.user) (builtins.attrValues apps));

        commands = [
          {
            command = "${launcher}/bin/namespace-enter *";

            options = [
              "NOPASSWD"
              "NOSETENV"
            ];
          }
        ];
      }
    ];

    # Only descriptor 3 carries the sealed user environment. It is read after
    # setns/mounts and complete privilege drop, so SETENV is never granted.
    security.sudo.extraConfig = lib.optionalString (apps != { }) ''
      Defaults!${launcher}/bin/namespace-enter closefrom_override, !use_pty, env_reset
    '';
  };
}
