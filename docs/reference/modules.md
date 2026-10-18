# Module conventions

Choose the nearest existing module as the style reference. System services,
hardware, boot, networking, and session plumbing belong in NixOS modules. User
applications, XDG files, editors, and user services belong in Home Manager modules.
Host profiles select features; `config/` holds program-native source files.

## Discovery and enablement

`flake/hosts.nix` selects a catalog profile. `lib/module-catalog.nix` chooses its
module roots; `lib/module-discovery.nix` recursively imports `.nix` files.
A directory containing `default.nix` is imported as one module, and that entry
point must explicitly import any module helpers beside it.

| Module root | Scope | Profiles |
| --- | --- | --- |
| `modules/desktops`, `modules/hardware`, `modules/system-apps`, `modules/system-dev`, `modules/system-files` | NixOS | Desktop |
| `modules/system-services` | NixOS | Desktop, server |
| `modules/server` | NixOS | Server |
| `modules/user-ai`, `modules/user-apps`, `modules/user-desktop`, `modules/user-files` | Home Manager | Desktop |
| `modules/user-dev` | Home Manager | Desktop, server |

The system-core base/user modules are explicitly imported by host configurations;
`modules/secrets.nix` is imported by flake assembly. They are outside discovered
roots. Host shared profiles also remain outside discovery.

Discovery makes options available. Hosts enable them separately. Do not manually
import a discovered module from a host profile. Keep implementation helpers inside
a directory owned by `default.nix` so they do not become accidental modules.

## Add or select a feature

A minimal Home Manager module follows the existing option namespaces:

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.my.user.apps.example;
in
{
  options.my.user.apps.example.enable = lib.mkEnableOption "Example application";
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.example ];
  };
}
```

Select it in `hosts/<host>/profile.nix`:

```nix
my.primaryUser.home.settings.my.user.apps.example.enable = true;
```

System services use `my.system.*`; desktop and hardware options use the existing
`my.desktop.*`, `my.hardware.*`, and `my.server.*` structure. Look for an existing
option before introducing another. Prefer native NixOS/Home Manager integration
when it already owns the package or service.

The primary-user adapter applies deferred `my.primaryUser.home.settings` to
`home-manager.users`. Keep host-specific user choices there, without a parallel
host-local Home Manager tree.

Use `mkDefault` for intended overridable defaults, as the workstation bundle does.
Shared PC/laptop feature selections retain ordinary priority. Avoid `mkForce`
unless the override is deliberate. Keep system and home state versions stable
during normal updates.

## File deployment

Use application-specific Home Manager options, `xdg.configFile`, and the existing
`lib/config-paths.nix` adapters. Inspect the owning module before changing how files
are installed.

| Application | Ownership to preserve |
| --- | --- |
| Fish | Static config file and recursive snippet/function trees; directories remain writable |
| Kitty | PC source file; laptop generated text appends its font-size override |
| Niri | Individual static source leaves, with a host-selected workspace source mapped to `sub/workspaces.kdl`; generated Noctalia includes remain writable siblings |
| Noctalia | Native settings from TOML plus explicit common/profile/template links; generated themes and runtime settings remain separate |
| Neovim | Writable activation-time source copy, excluding generated `lua/matugen.lua` |
| Zen | Selected settings within a browser-owned profile; sessions/logins/databases remain writable |
| tmux/sesh | Generated configuration; sesh substitutes the packaged executable path |
| Skillshare | Nix installs the CLI; resources and selections remain runtime-managed |

Niri discovers nested source leaves automatically. Add the source file and its
KDL include, then stage new files so Git flakes can see them. Workspace variants
are excluded from ordinary discovery; only the selected source gets the common
deployed name. Keep generated `noctalia*.kdl` outside the static source tree.

For a new exceptional target, exclude the ordinary source before declaring its
selected alias. Avoid two declarations owning the same effective leaf through
recursive and individual mappings. Inspect evaluated `home.file` targets,
permissions, and source/text mode when changing adapters.

`tests/config-paths/` covers the source adapters and is registered as `config-paths`.
An adapter refactor should compare effective leaf contents and activation behavior
on both desktops, plus the server for shared user modules. Store paths can change
with a source revision without changing file contents.

## Sensitive inputs and validation

`flake/hosts.nix` explicitly selects source mode before imports and passes
`secretFile`, `secretSource`, and `requirePrivate` to modules. Private host modules
join the assembly without changing discovery. Guard optional secret declarations
and their consumers. See [secrets](../operations/secrets.md).

Pass protected runtime secret paths to consumers; never read credentials into Nix
strings or generated world-readable files. Preserve production deployment guards.

Use [the configuration map](configuration.md#choose-verification-by-impact) for
checks. Verify both availability and intended enablement, then format and evaluate
all affected hosts. Generated services/files may require a non-activating build.
Changes to live systems remain a separately authorized step.
