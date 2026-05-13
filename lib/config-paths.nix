{ root }:
{
  dev = {
    fish.configDir = root + "/config/fish";
    kitty.configFile = root + "/config/kitty/kitty.conf";
    neovim.configDir = root + "/config/nvim";
    starship.configFile = root + "/config/starship/starship.toml";
  };

  wm = {
    hyprlandConfigDir = root + "/config/hyprland";
    niriConfigDir = root + "/config/niri";
    noctaliaConfigDir = root + "/config/noctalia";
  };
}
