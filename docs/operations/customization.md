# Make the setup yours

Start with the host you created in [installation](installation.md).
Add one feature at a time, build it, and check it before adding more. My profiles
can show you how a feature is used, but they also enable my applications, VPN
roles, and machine-specific settings.

## Choose the file to edit

| You want to change | Edit | Why |
| --- | --- | --- |
| Hostname, boot, mounts, networking, timezone, or account | `hosts/my-host/configuration.nix` and its hardware declaration | These describe your machine and access policy |
| Which features the machine uses | `hosts/my-host/profile.nix` | A profile selects existing options |
| Application settings or keybindings | The corresponding source under `config/` | The owning Home Manager module deploys those files |
| How a feature installs packages or runs services | Its module under `modules/` | Modules implement behavior shared across hosts |
| Which package source an exception uses | `lib/package-sources.nix` | [Package selections](../reference/modules.md#package-sources) are shared by NixOS and Home Manager |
| Available module roots or flake outputs | `lib/module-catalog.nix` or `flake/hosts.nix`, only when needed | Assembly and discovery already handle ordinary module files |

Home Manager is integrated through `my.primaryUser`: it derives the user's name
and home directory. Put user settings under `my.primaryUser.home.settings` so
that the account and Home Manager stay aligned.

## Enable an existing feature

For a small example, enable Git for your user. Edit `hosts/my-host/profile.nix`:

```nix
{ ... }:
{
  my.primaryUser.home.settings.my.user.dev.git.enable = true;
}
```

Set your optional Git identity in `hosts/my-host/configuration.nix`, inside its
existing `my.primaryUser` block:

```nix
git.userName = "Example Person";
git.userEmail = "person@example.invalid";
```

Replace these example values before using Git. The adapter passes them to the
Git module. Inspect `modules/dev/git.home.nix` for its other defaults before
turning it on. For system features, set their system option in the profile
instead; for example `my.system.services.tailscale.enable = true` enables the
Tailscale service, but enrollment remains a separate runtime task.

Stage and check your change from the repository root:

```sh
git add hosts/my-host
nix eval --raw .#nixosConfigurations.my-host.config.networking.hostName --no-write-lock-file
nix build --no-link .#nixosConfigurations.my-host.config.system.build.toplevel --no-write-lock-file
```

The evaluation should print your chosen hostname. The build should finish with
no configuration errors. It creates a system in the store; your running system
and user environment change only when you [activate it](maintenance.md#apply-a-reviewed-change).

## Choose desktop and server features

For desktop options, register your host with `moduleProfiles.desktop`. System
session settings live under `my.desktop.*`; user integration lives under
`my.primaryUser.home.settings.my.user.*`. Niri's session module is
`modules/desktops/niri/default.nix`, while its dotfile adapter is
`modules/user-desktop/niri/config.nix`. They have different jobs: installing a
session doesn't select all my personal KDL files.

My Niri files include Noctalia-generated files and host-specific workspaces.
Before enabling `my.user.desktop.niriConfig`, read its workspace option and
`lib/config-paths.nix`, then adapt your outputs and workspace source. Don't
copy the PC's monitor names to a laptop. The [shared desktop profile](../../hosts/common/desktop.nix)
shows which applications I choose on both machines. Select only the features
you need. The [greeter guide](noctalia-greeter.md) explains the separate
login and keyring requirements. A key-only SSH host doesn't yet have a desktop
login password; configure [an encrypted console password](secrets.md#console-passwords)
before relying on password-based graphical login.

For a server, keep `moduleProfiles.server` and enable only the services you need.
Read each module's options before enabling storage, Docker, SSH, or Syncthing.
My [server guide](server.md) explains the `/srv/*` boundaries. The VPN gateway is
an optional, security-sensitive setup that needs its own credentials and peers;
it isn't needed for ordinary server or desktop use.

## Edit an application's configuration

Find the owning module first. For example, `modules/user-dev/neovim/config.nix`
deploys `config/nvim/`, and `modules/apps/zen-browser.home.nix` uses the Zen
profile source. Check the module to see which source file actually reaches your
host, then edit that file and build again.

Some files intentionally stay writable. Neovim activation copies its source and
preserves generated `lua/matugen.lua`; it doesn't link the whole directory into
the read-only store. Noctalia generates theme files, Zen keeps browser sessions,
and Skillshare manages writable agent resources. Don't replace these boundaries
with immutable links or delete runtime data to make a rebuild succeed. See
[state ownership](../reference/architecture.md)
and the relevant [application guide](../../README.md).

## Add a module when an option doesn't exist

Search the nearest subsystem for an existing option first. If you need new
behavior, use a NixOS module for system services or hardware, and a Home Manager
module for per-user packages, settings, or services. Follow the
[module examples and discovery rules](../reference/modules.md#add-or-select-a-feature).

A `.nix` file under a discovered root is available automatically. A directory
with `default.nix` is one module, whose entry point imports its helpers. Enable
the option in your host profile; don't add another manual import to that profile.
Only a new module root requires changing the catalog.

Build every host affected by a shared change, and run the relevant checks from
[maintenance](maintenance.md#check-before-activation). Keep optional features
disabled unless selected. Never put private credentials into Nix strings or
application source files; use [runtime secret paths](secrets.md#single-repository-setup).
