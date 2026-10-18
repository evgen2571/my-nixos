#!/usr/bin/env bash
# Disposable Git source and synthetic encrypted data; never touches runtime state.
set -euo pipefail
repo=$(git rev-parse --show-toplevel)
scratch=$(mktemp -d)
vm_pid=
cleanup() {
  if [[ -n $vm_pid ]]; then kill "$vm_pid" 2>/dev/null || true; wait "$vm_pid" 2>/dev/null || true; fi
  rm -rf "$scratch"
}
trap cleanup EXIT
export TEST_SOURCE="$repo" TEST_TARGET="$scratch/repo"
python3 - <<'PY'
import os, pathlib, shutil, subprocess
source=pathlib.Path(os.environ['TEST_SOURCE']); target=pathlib.Path(os.environ['TEST_TARGET'])
for name in subprocess.check_output(['git','-C',str(source),'ls-files','-z']).split(b'\0'):
    if not name: continue
    path=source/os.fsdecode(name)
    if not path.is_file(): continue
    dest=target/os.fsdecode(name); dest.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(path,dest)
PY
cd "$scratch/repo"
git init -q
git config user.email fixture@example.invalid
git config user.name Fixture
# Prove the tracked template works, independently of any private sibling.
git add .
git commit -qm 'fixture: public source'
sha256sum flake.lock > "$scratch/lock.sha256"
nix flake show --no-write-lock-file > "$scratch/show.log" 2>&1
sha256sum -c "$scratch/lock.sha256"
cp -r templates/host hosts/fixture
ssh-keygen -q -t ed25519 -N '' -f "$scratch/login"
# No private keys enter the Git fixture or Nix store.
export TEST_PUBLIC_KEY="$scratch/login.pub"
python3 - <<'PY'
import os, pathlib
p=pathlib.Path('hosts/fixture/configuration.nix');s=p.read_text().replace('"replace-me";', '"fixture";',1)
s=s.replace('authorizedKeys = [ ];','authorizedKeys = [ '+__import__('json').dumps(pathlib.Path(os.environ['TEST_PUBLIC_KEY']).read_text().strip())+' ];')
s=s.replace('services.openssh = {','security.sudo.wheelNeedsPassword = false;\n  networking.firewall.allowedTCPPorts = [ 22 ];\n  services.openssh = {')
p.write_text(s)
pathlib.Path('hosts/fixture/profile.nix').write_text('{ pkgs, ... }: { environment.systemPackages = [ pkgs.age pkgs.sops ]; }')
pathlib.Path('hosts/fixture/hardware-configuration.nix').write_text('''{ ... }: {
  boot.loader.grub.enable = false;
  fileSystems."/" = { device = "/dev/disk/by-label/fixture"; fsType = "ext4"; };
}''')
p=pathlib.Path('flake/hosts.nix');s=p.read_text().replace('flake.nixosConfigurations = {','''flake.nixosConfigurations = {
    fixture = mkHost {
      host = "fixture";
      hostModule = ../hosts/fixture/configuration.nix;
      profile = moduleProfiles.server;
      secretSource = "none";
    };''');p.write_text(s)
PY
git add hosts flake
nix build --no-link .#nixosConfigurations.fixture.config.system.build.toplevel --no-write-lock-file
# Prove key-only first login in a disposable user-networked VM when KVM is available.
if [[ -r /dev/kvm && -w /dev/kvm ]]; then
  nix build --out-link "$scratch/vm" .#nixosConfigurations.fixture.config.system.build.vm --no-write-lock-file
  port=$(python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1",0)); print(s.getsockname()[1]); s.close()')
  QEMU_NET_OPTS="hostfwd=tcp:127.0.0.1:$port-:22" QEMU_OPTS="-nographic" \
    NIX_DISK_IMAGE="$scratch/disk.qcow2" "$scratch/vm/bin/run-fixture-vm" > "$scratch/vm.log" 2>&1 &
  vm_pid=$!
  connected=false
  for ((attempt = 0; attempt < 120; attempt++)); do
    if ssh -i "$scratch/login" -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null -o ConnectTimeout=2 -p "$port" operator@127.0.0.1 \
      'test "$(id -un)" = operator' > "$scratch/ssh.log" 2>&1; then connected=true; break; fi
    kill -0 "$vm_pid" 2>/dev/null || { echo 'Disposable VM exited before first login' >&2; exit 1; }
    sleep 1
  done
  [[ $connected == true ]] || { echo 'Disposable VM first login failed' >&2; exit 1; }
  # Exercise the actual guard as root in the disposable guest, with synthetic data.
  {
    cat <<'GUEST'
set -euo pipefail
install -d -m 0700 /var/lib/sops-nix
age-keygen -o /var/lib/sops-nix/key.txt 2>/dev/null
chmod 0600 /var/lib/sops-nix/key.txt
recipient=$(age-keygen -y /var/lib/sops-nix/key.txt)
printf 'example_token: fixture-only\n' | sops --encrypt --age "$recipient" --input-type yaml --output-type yaml /dev/stdin > /tmp/guard.yaml
cat > /tmp/preflight <<'GUARD'
GUEST
    sed -e 's/@available@/true/g' -e 's|@ciphertext@|/tmp/guard.yaml|g' modules/deployment/preflight.sh
    cat <<'GUEST'
GUARD
bash /tmp/preflight
chmod 0644 /var/lib/sops-nix/key.txt
if bash /tmp/preflight; then echo 'Unsafe identity permissions accepted'; exit 1; fi
chmod 0600 /var/lib/sops-nix/key.txt
mv /var/lib/sops-nix/key.txt /var/lib/sops-nix/original
age-keygen -o /var/lib/sops-nix/key.txt 2>/dev/null
chmod 0600 /var/lib/sops-nix/key.txt
if bash /tmp/preflight; then echo 'Wrong host identity accepted'; exit 1; fi
rm /var/lib/sops-nix/key.txt
if bash /tmp/preflight; then echo 'Missing identity accepted'; exit 1; fi
GUEST
  } | ssh -i "$scratch/login" -o IdentitiesOnly=yes -o BatchMode=yes -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null -p "$port" operator@127.0.0.1 'sudo bash -s'
  kill "$vm_pid"; wait "$vm_pid" || true
  vm_pid=
  echo 'Disposable template VM key-only SSH first login passed'
else
  echo 'SKIP: /dev/kvm is unavailable for disposable first-login VM' >&2
fi
# Explicit local SOPS, with a runtime-generated disposable identity outside source.
age-keygen -o "$scratch/age-identity" 2>/dev/null
recipient=$(age-keygen -y "$scratch/age-identity")
mkdir -p secrets/hosts
printf 'example_token: fixture-only\n' | sops --encrypt --age "$recipient" --input-type yaml --output-type yaml /dev/stdin > secrets/hosts/fixture.yaml
printf 'creation_rules:\n  - path_regex: secrets/hosts/fixture\\.yaml$\n    age: %s\n' "$recipient" > .sops.yaml
python3 - <<'PY'
from pathlib import Path
p=Path('flake/hosts.nix');s=p.read_text().replace('secretSource = "none";', 'secretSource = "local";',1);p.write_text(s)
p=Path('hosts/fixture/profile.nix');p.write_text('''{ secretFile, ... }: {
  sops.secrets.example-token = { sopsFile = secretFile; key = "example_token"; mode = "0400"; };
}''')
PY
git add .sops.yaml secrets hosts flake
nix build --no-link .#nixosConfigurations.fixture.config.system.build.toplevel --no-write-lock-file
# A missing required encrypted field must fail evaluation, never select another source.
sed -i 's/example_token:/wrong_field:/' secrets/hosts/fixture.yaml
if nix eval --raw .#nixosConfigurations.fixture.config.system.build.toplevel.drvPath --no-write-lock-file > "$scratch/missing-field.log" 2>&1; then
  echo 'Missing required SOPS field unexpectedly accepted' >&2; exit 1
fi
rg -q 'missing an encrypted required field' "$scratch/missing-field.log"
# Missing first-login configuration is rejected even in no-secrets mode.
sed -i 's/secretSource = "local";/secretSource = "none";/' flake/hosts.nix
cp templates/host/configuration.nix hosts/fixture/configuration.nix
cp templates/host/profile.nix hosts/fixture/profile.nix
if nix eval --raw .#nixosConfigurations.fixture.config.system.build.toplevel.drvPath --no-write-lock-file > "$scratch/login.log" 2>&1; then
  echo 'Missing first-login configuration unexpectedly accepted' >&2; exit 1
fi
rg -q 'choose a hostname, your SSH public key' "$scratch/login.log"
sha256sum -c "$scratch/lock.sha256"
echo 'Standalone none/local builds, missing encrypted field and first-login refusal passed'
