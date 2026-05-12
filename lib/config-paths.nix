{ root }:
{
  coding = {
    fishConfigDir = root + "/config/fish";
    kittyConf = root + "/config/kitty/kitty.conf";
    neovimConfigDir = root + "/config/nvim";
    starshipToml = root + "/config/starship/starship.toml";
  };

  wm = {
    hyprlandConfigDir = root + "/config/hyprland";
    niriConfigDir = root + "/config/niri";
    noctaliaConfigDir = root + "/config/noctalia";
  };
}
