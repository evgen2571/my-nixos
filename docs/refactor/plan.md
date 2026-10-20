# Module inventory and equivalence plan

Spec: [#50](https://github.com/evgen2571/my-nixos/issues/50), under #49.
Baseline: `cb75bb68aaf0412f26488d63e4556e36c31193bd`.
Integration branch: `evgen2571/1-6-establish-module-inventory-and-host-equivale`.

- [x] Capture original ordered catalog outputs, explicit assembly and every module/helper/asset; assign typed targets without moving source.
- [x] Capture public assembled host/Home Manager option schemas and effective behavior; provide strict reproducible comparisons with narrow source-root normalization.
- [x] Run baseline flake/application/VPN/VM checks, audit private access without publishing material, and record limitations.
- [ ] Review standards and spec, verify the clean committed tree, publish one draft integration PR and update issue checkboxes.

The agreed seams are the four catalog outputs and three assembled hosts/users
(parent issue Testing Decisions). Fixtures must include disabled options. Keep
package paths, command arguments, file destinations/permissions and activation
ordering. Never normalize arbitrary store hashes. A changed derivation requires
content/build review before accepting a relocation. Private snapshots stay local.
No module migration, input update or live activation is part of this stage.
