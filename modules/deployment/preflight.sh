# This script only checks readiness; it never provisions credentials or activates.
set -euo pipefail
fail() { echo "Deployment refused: $*" >&2; exit 1; }
@available@ || fail 'required private host material is unavailable; select the reviewed private input'
identity="${1:-}/var/lib/sops-nix/key.txt"
parent=$(dirname "$identity")
[[ -d $parent && ! -L $parent ]] || fail 'host age identity directory must be a real protected directory'
[[ $(stat -c %u "$parent") == 0 ]] || fail 'host age identity directory must belong to root'
permissions=$(stat -c %a "$parent")
(( (8#$permissions & 0022) == 0 )) || fail 'host age identity directory must not be writable by other users'
[[ -f $identity && ! -L $identity && -s $identity ]] || fail 'provision the protected host age identity before deployment'
[[ $(stat -c %u "$identity") == 0 ]] || fail 'host age identity must belong to root'
case $(stat -c %a "$identity") in
    400|600) ;;
    *) fail 'host age identity must have mode 0400 or 0600' ;;
esac
# Decrypt only to /dev/null at deployment time; never log decrypted values.
env -i PATH="$PATH" SOPS_AGE_KEY_FILE="$identity" \
    sops --decrypt --output /dev/null @ciphertext@ 2>/dev/null \
    || fail 'protected identity cannot decrypt the selected host ciphertext'
