{ root }:
{
  coding = {
    fishConfigDir = root + "/configs/coding/fish/config";
    kittyConf = root + "/configs/coding/kitty/kitty.conf";
    neovimConfigDir = root + "/configs/coding/neovim/config";
    starshipToml = root + "/configs/coding/starship/starship.toml";
  };

  wm = {
    hyprlandConfigDir = root + "/configs/wm/hyprland/config";
    niriConfigDir = root + "/configs/wm/niri/config";
    noctaliaConfigDir = root + "/configs/wm/noctalia/config";
  };
}
