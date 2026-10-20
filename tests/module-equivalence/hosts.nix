# Only the public template may be exported to shareable fixtures.
{ flake }:
let
  lib = flake.inputs.nixpkgs.lib;
  encode =
    value:
    if builtins.isFunction value then
      { _opaque = "function"; }
    else if lib.isDerivation value then
      {
        inherit (value) name outPath drvPath;
        version = value.version or null;
      }
    else if builtins.isPath value then
      toString value
    else if builtins.isList value then
      map encode value
    else if builtins.isAttrs value then
      lib.mapAttrs (_: encode) (removeAttrs value [ "_module" ])
    else
      value;
  schema =
    options:
    lib.mapAttrs (
      _: option:
      if lib.isOption option then
        {
          type = option.type.description;
          default = if option ? default then encode option.default else { _unset = true; };
          readOnly = option.readOnly or false;
          subOptions = schema (option.type.getSubOptions [ ]);
        }
      else
        schema option
    ) options;
  select =
    paths: value:
    builtins.listToAttrs (
      map (name: {
        inherit name;
        value = encode (lib.getAttrFromPath (lib.splitString "." name) value);
      }) paths
    );
  homeEvidence = home: {
    options = schema home.options.my;
    values = encode home.config.my;
    behavior = select [
      "home.packages"
      "home.file"
      "home.activation"
      "home.sessionVariables"
      "home.sessionPath"
      "home.stateVersion"
      "systemd.user"
      "programs.ssh.settings"
      "programs.git.settings"
      "programs.tmux"
      "xdg.configFile"
    ] home.config;
    applications = encode (
      lib.optionalAttrs (home.config.programs ? noctalia) {
        noctalia = { inherit (home.config.programs.noctalia) settings package enable; };
      }
      // lib.optionalAttrs (home.config.programs ? zen-browser) {
        zen = { inherit (home.config.programs.zen-browser) profiles package enable; };
      }
    );
  };
  hostEvidence =
    host:
    let
      c = host.config;
    in
    assert c.my.primaryUser.name == "operator";
    assert c.sops.secrets == { };
    {
      options = schema host.options.my;
      values = encode (removeAttrs c.my [ "primaryUser" ]);
      primaryUser = encode (removeAttrs c.my.primaryUser [ "home" ]);
      homeWiring = {
        inherit (c.home-manager) useGlobalPkgs useUserPackages backupFileExtension;
        inherit (c.my.primaryUser.home) enable;
        module = toString c.my.primaryUser.home.module;
      };
      pam = lib.mapAttrs (_: service: { inherit (service) text; }) c.security.pam.services;
      behavior = select [
        "environment.systemPackages"
        "environment.etc"
        "environment.sessionVariables"
        "fonts.packages"
        "systemd.units"
        "systemd.user.units"
        "systemd.tmpfiles.rules"
        "users.users"
        "users.groups"
        "security.sudo"
        "security.polkit"
        "security.wrappers"
        "networking.firewall"
        "networking.nftables"
        "networking.nameservers"
        "networking.networkmanager.enable"
        "fileSystems"
        "boot.kernelParams"
        "boot.kernelModules"
        "system.activationScripts"
        "system.preSwitchChecks"
        "system.systemBuilderCommands"
        "system.stateVersion"
        "nix.settings"
        "nixpkgs.config"
      ] c;
      homes = lib.mapAttrs (
        name: _:
        homeEvidence {
          config = c.home-manager.users.${name};
          options = host.options.home-manager.users.type.getSubOptions [ ];
        }
      ) c.home-manager.users;
    };
in
assert flake.inputs.private.nixosModules == { };
assert flake.inputs.private.secretFiles == { };
lib.mapAttrs (_: hostEvidence) flake.nixosConfigurations
