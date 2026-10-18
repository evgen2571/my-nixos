# Selection happens before module imports; never infer a source from file existence.
{
  root,
  private,
  host,
  source,
}:
let
  fail = message: throw "secret source for ${host}: ${message}";
  files = private.secretFiles or { };
  modules = private.nixosModules or { };
  file = if source == "local" then root + "/secrets/hosts/${host}.yaml" else files.${host} or null;
in
if source == "none" then
  {
    file = null;
    modules = [ ];
  }
else if
  !(builtins.elem source [
    "local"
    "private"
  ])
then
  fail "choose none, local or private explicitly"
else if source == "private" && !(builtins.isAttrs files && builtins.isAttrs modules) then
  fail "private secretFiles and nixosModules must be attribute sets"
else if file != null && !(builtins.isPath file && builtins.pathExists file) then
  fail "selected ciphertext must be an existing Nix path (stage new Git files)"
else if source == "local" && !(builtins.pathExists (root + "/.sops.yaml")) then
  fail "local mode requires a tracked .sops.yaml recipient policy"
else if source == "private" && file == null && (files ? ${host} || modules ? ${host}) then
  fail "incomplete private host input: supply host ciphertext"
else
  {
    inherit file;
    modules = if source == "private" && modules ? ${host} then [ modules.${host} ] else [ ];
  }
