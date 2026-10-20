# Module conventions

Choose the nearest existing module as the style reference. System services,
hardware, boot, networking, and session plumbing belong in NixOS modules. User
applications, XDG files, editors, and user services belong in Home Manager modules.
Host profiles select features; `config/` holds program-native source files.

## Discovery and enablement

`flake/hosts.nix` selects a catalog profile. `lib/module-discovery.nix` recognizes
`*.nixos.nix` and directory `nixos.nix` as NixOS entries, and `*.home.nix` and
directory `home.nix` as Home Manager entries. Typed discovery recurses in sorted
name order even beside a `default.nix`; helpers such as `config.nix`, ordinary
untyped Nix files, symlinks and non-module assets are ignored. Helpers are imported
explicitly by their owner. Each typed entry belongs to exactly one module system.

`lib/module-catalog.nix` owns availability independently for each scope:

| Typed module root | NixOS profiles | Home Manager profiles |
| --- | --- | --- |
| `modules/ai` | None | Desktop |
| `modules/apps`, `modules/desktop`, `modules/files` | Desktop | Desktop |
| `modules/dev` | Desktop | Desktop, server |
| `modules/services` | Desktop, server | None |
| `modules/hardware` | Desktop | None |
| `modules/server` | Server | None |

For example, `dev/fish/nixos.nix` is desktop-only while its colocated `home.nix`
is available on desktops and server. Declaring a typed entry in a scope the root
does not allow is an error, with its path and scope in the diagnostic.

Discovery recognizes an entry, catalog rules make its options available, and host
profiles activate its behavior through the existing enable/settings options.
Availability does not enable a feature. Unconditional entries such as personal
SSH retain their existing behavior. Do not manually import discovered modules
from host profiles.

Core baselines, primary-user/Home Manager baseline wiring, secrets and deployment
are explicitly assembled. `modules/core`, `modules/system-core`,
`modules/deployment` and `modules/secrets.nix` stay outside optional discovery.
Host shared profiles remain outside discovery too. Optional `server/base.nixos.nix` stays
separate from the explicit server baseline.

### Temporary legacy compatibility

The original category roots (`desktops`, `system-*` except `system-core`, and
`user-*`, plus `hardware` and `server`) retain their previous scope/profile rules.
Only the 75 ordered registrations frozen in `lib/module-compatibility.json` can
enter from the untyped layout. Legacy scanning keeps the `default.nix` stopping
rule for these entries. New untyped helpers never become optional modules.

Each registration must resolve to exactly one of its legacy or approved typed
paths. Missing both is an error; keeping both is a duplicate-registration error.
Migration replaces the path in its existing ordered slot, preserving effective
import order even when new feature paths sort differently. New ordinary typed
features follow the compatibility entries, in catalog-root order and recursive
sorted-name order. The catalog returns separate deterministic `systemModules`
and `homeModules` lists for each profile.

The table is frozen from the approved inventory: Tickets #52–#54 move their
assigned implementations and remove the corresponding legacy entry files in the
same change. They do not edit shared discovery, root rules or compatibility
registrations. Any necessary shared change is serialized through the integration
branch owner before another migration integrates. Fixture/inventory coverage
rejects registration drift. This is a temporary ordering bridge: final ticket
#55 must remove legacy scanning and the compatibility table, replacing the latter
with an explicit typed ordering mechanism that preserves the recorded order.
The ordered baseline must never be refreshed simply to accept a new sort order.

Run `python3 tests/module-catalog/test_catalog.py` for extendable directory
fixtures and `nix build .#checks.x86_64-linux.module-catalog --no-link` for the
sandboxed check. `module-equivalence` applies the explicit [migration ledger](../refactor/migrations.json)
to the frozen ordered inventory;
[the comparison contract](../refactor/README.md) covers assembled hosts.

## Add or select a feature

Add an ordinary desktop app at `modules/apps/example.home.nix` (or
`modules/apps/example/home.nix` when it needs helpers). No registration or manual
import is needed; the root rules make it available to desktop Home Manager only.
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

## Layout and comments

Use the example above for small modules: arguments, a `cfg` binding, options,
then a `config = lib.mkIf cfg.enable { ... };` block. Separate options and
configuration sections with a blank line. Leave a blank line after the argument
list and between separate option definitions, helper functions, and service
blocks. Keep the fields of one option together. Group related scalar settings;
automatic formatting alone does not provide these breaks. An enable-only option
needs no extra attribute-set wrapper.

Keep a feature in one file while its options and implementation are easy to read
together. Use a directory with `nixos.nix` or `home.nix` when it needs helpers or separate
source files. Split by responsibility, such as package installation and file
deployment; avoid creating a file for every setting. Shell scripts with their own
control flow belong in `.sh` files, as in `modules/user-dev/tmux/project-list.sh`.

Comments should explain a reason or constraint: why a file must stay writable,
why a dependency is pinned, or which program owns a shortcut. Skip comments that
repeat the next setting. A short section comment can explain what a longer group
of settings or setup steps does. Put it directly above that group, with a blank
line before the comment. Keep security and recovery explanations specific.

The `module-style` flake check runs nixfmt and deadnix over `modules/` and the
package-source map. The `sesh-project-list` check covers project discovery,
symlinks, paths containing spaces, and an unavailable zoxide database.

## Package sources

`pkgs` uses the stable `nixpkgs` input. Use it for ordinary packages.
[lib/package-sources.nix](../../lib/package-sources.nix) lists the explicit
unstable and external-input package selections. `flake/hosts.nix` passes the same
`packageSources` map to NixOS and Home Manager modules:

```nix
{ config, lib, packageSources, ... }:

let
  cfg = config.my.user.ai.codegraph;
in
{
  options.my.user.ai.codegraph.enable = lib.mkEnableOption "CodeGraph";

  config = lib.mkIf cfg.enable {
    home.packages = [ packageSources.codegraph ];
  };
}
```

Change an exception's source in that map. For example, selecting stable Godot
means removing `godot_4` from `inherit (unstable)` and adding:

```nix
godot_4 = inputs.nixpkgs.legacyPackages.${system}.godot_4;
```

Check the selected version and build before switching sources. For unfree stable
packages, use an explicit stable import with `config.allowUnfree = true`, as the
unstable import does. Keep dependency overrides and insecure-package allowances
beside their package selection. Vesktop's allowances apply only to its package
set; sesh's mockery override applies only to sesh. Do not spread either across
the global package set.

Upstream NixOS/Home Manager module imports stay in their owning feature modules.
Zen's beta Home Manager module selects its own package. Input revisions remain
in `flake.lock`; this map does not update or unpin them.

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

The feature-first refactor has a [pre-migration inventory and comparison contract](../refactor/README.md).
