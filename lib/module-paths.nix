{ root }:
{
  ai = {
    codex = root + "/modules/ai/codex.nix";
    llamaCpp = root + "/modules/ai/llama-cpp.nix";
    ollama = root + "/modules/ai/ollama.nix";
  };

  apps = {
    aagl = root + "/modules/apps/aagl.nix";
    bitwarden = root + "/modules/apps/bitwarden.nix";
    chrome = root + "/modules/apps/chrome.nix";
    kdeConnect = root + "/modules/apps/kde-connect.nix";
    lutris = root + "/modules/apps/lutris.nix";
    obs = root + "/modules/apps/obs.nix";
    obsidian = root + "/modules/apps/obsidian.nix";
    osuLazer = root + "/modules/apps/osu-lazer.nix";
    prismLauncher = root + "/modules/apps/prism-launcher.nix";
    steam = root + "/modules/apps/steam.nix";
    telegram = root + "/modules/apps/telegram.nix";
    vesktop = root + "/modules/apps/vesktop.nix";
    youtubeMusic = root + "/modules/apps/youtube-music.nix";
    zenBrowser = root + "/modules/apps/zen-browser.nix";
  };

  coding = {
    devTools = root + "/modules/coding/dev-tools.nix";
    docker = root + "/modules/coding/docker";
    fish = root + "/modules/coding/fish";
    fishConfig = root + "/modules/coding/fish/config.nix";
    git = root + "/modules/coding/git.nix";
    kitty = root + "/modules/coding/kitty";
    neovim = root + "/modules/coding/neovim";
    starship = root + "/modules/coding/starship";
    tmux = root + "/modules/coding/tmux";
    vscode = root + "/modules/coding/vscode.nix";
    zed = root + "/modules/coding/zed.nix";
  };

  fileManagers = {
    dolphin = root + "/modules/file-managers/dolphin.nix";
    thunar = root + "/modules/file-managers/thunar.nix";
    yazi = root + "/modules/file-managers/yazi.nix";
  };

  hardware = {
    nvidia = root + "/modules/hardware/nvidia.nix";
    screenRecorder = root + "/modules/hardware/screen-recorder.nix";
  };

  wm = {
    cinnamon = root + "/modules/wm/cinnamon";
    gnome = root + "/modules/wm/gnome";
    hyprland = root + "/modules/wm/hyprland";
    hyprlandConfig = root + "/modules/wm/hyprland/config.nix";
    ly = root + "/modules/wm/ly.nix";
    niri = root + "/modules/wm/niri";
    niriConfig = root + "/modules/wm/niri/config.nix";
    noctalia = root + "/modules/wm/noctalia";
    opentabletdriver = root + "/modules/wm/opentabletdriver.nix";
    screenRecorder = root + "/modules/wm/screen-recorder.nix";
    virtualization = root + "/modules/wm/virtualization.nix";
    xserver = root + "/modules/wm/xserver.nix";
  };
}
