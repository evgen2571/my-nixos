# Shared declarative Zen profile for PC and laptop.
# Adopt existing UUIDs before enabling if you want to preserve existing spaces.
# See docs/apps/zen-browser.md.
let
  mkPin = id: url: position: { inherit id url position; };

  mkFolder = id: position: pins: {
    inherit id position pins;
    editedTitle = true;
    isFolderCollapsed = true;
  };
in
{
  settings = {
    "zen.workspaces.continue-where-left-off" = true;
    "zen.window-sync.enabled" = true;

    # Sidebar and Top Toolbar
    "zen.view.use-single-toolbar" = false;
    "zen.view.sidebar-expanded" = true;

    # Nebula transparency
    "zen.widget.linux.transparency" = true;
    "browser.tabs.allow_transparent_browser" = true;
  };

  # Keep synchronized with Zen's zen.keyboard.shortcuts.version.
  # Ctrl+` toggles compact mode; other bindings remain browser defaults.
  keyboardShortcutsVersion = 21;

  keyboardShortcuts = [
    {
      id = "zen-compact-mode-toggle";
      key = "`";
      modifiers.control = true;
    }
  ];

  sine = {
    enable = true;

    mods = [
      # Add Sine store mod IDs, e.g. "Arc-2.0".
    ];
  };

  # Preserve undeclared spaces, pins, and routes while migrating.
  spacesForce = false;
  pinsForce = false;

  spaceRouting = {
    force = false;
    defaultExternalRoute = "most-recent-space";
  };

  spaces = {
    ChatGPT = {
      id = "17fbd6ba-7c78-4023-a335-8709413502d6";
      position = 1000;
      icon = "✦";

      pins = {
        ChatGPT = mkPin "b5685e80-d828-4c14-a6c8-cb8e98b8e37f" "https://chatgpt.com/" 100;
      }
      // (import ./chatgpt-projects.nix);

      routes = {
        "ChatGPT".reference = "chatgpt.com";
        "Legacy ChatGPT".reference = "chat.openai.com";
      };
    };

    Development = {
      id = "a0bc74fb-6f7f-42e3-bf3b-29ad34b1b4dc";
      position = 2000;
      icon = "💻";

      pins = {
        "Competitive Programming" = mkFolder "3bfa7678-117a-400a-bfd3-eb27798fb04d" 100 {
          "Codeforces" = mkPin "8b2227cf-69bf-495c-94f2-43986a61230a" "https://codeforces.com/" 100;
          "CSES" = mkPin "f3e6e0c3-a2de-4829-9c8f-2334b189be9e" "https://cses.fi/problemset/" 200;
          "AtCoder" = mkPin "3ec7f3f1-3244-42e3-bcf8-0688d2545c02" "https://atcoder.jp/" 300;
          "CP-Algorithms" = mkPin "15564ba8-ff67-4dfd-9181-c6da1277f2cf" "https://cp-algorithms.com/" 400;
          "USACO Guide" = mkPin "a53f85e0-24ca-4f01-8bed-f980f18d3832" "https://usaco.guide/" 500;
          "LeetCode" = mkPin "8f6983d4-7692-4d85-8a48-2ab856fe4244" "https://leetcode.com/problemset/" 600;
        };

        "Documentation" = mkFolder "2b7aa35e-0db5-4785-b54d-01c5e0004237" 200 {
          "NixOS Packages" =
            mkPin "60bba716-0da3-45bb-adbd-7ef5fc6e2ffc" "https://search.nixos.org/packages"
              100;

          "NixOS Options" =
            mkPin "da55274d-4d82-43e0-b9f4-e3a7b57c5108" "https://search.nixos.org/options"
              200;

          "Home Manager Options" =
            mkPin "48a0b5b6-a7b4-46b2-8eb9-ebcd9ad3ef3a" "https://home-manager-options.extranix.com/"
              300;

          "cppreference" = mkPin "4b318349-f1cf-4435-b238-62943950dfd1" "https://en.cppreference.com/w/" 400;
          "Python Docs" = mkPin "2b1b2143-8e63-4b4d-b9f5-a81c93181914" "https://docs.python.org/3/" 500;
          "Rust Docs" = mkPin "9bab68d0-120b-4f73-bdb5-e6762286512f" "https://doc.rust-lang.org/std/" 600;

          "MDN" =
            mkPin "fdce1cdc-82e2-4fc4-b669-739879049eca" "https://developer.mozilla.org/en-US/docs/Web"
              700;
        };

        "ML and Research" = mkFolder "8c506b84-ba5e-4e6c-ab41-78e2b076a530" 300 {
          "Kaggle" = mkPin "c6b0733a-4dba-4c9e-a135-3424b18b0f45" "https://www.kaggle.com/" 100;
          "Hugging Face" = mkPin "d5f1cd30-fdc4-4f85-ba87-31d8bf0edbd3" "https://huggingface.co/" 200;

          "PyTorch Docs" =
            mkPin "5a1aeca0-9cfe-4980-8ad1-5cd59d4df09f" "https://docs.pytorch.org/docs/stable/"
              300;

          "scikit-learn" =
            mkPin "2772e760-8e09-4488-9cfb-a0e92d8a69fa" "https://scikit-learn.org/stable/"
              400;

          "arXiv" = mkPin "71bbdfec-a756-46c9-81d3-cb40835af3a7" "https://arxiv.org/" 500;
        };

        "Developer Tools" = mkFolder "6bf10a3c-fb4f-43e6-94a9-2ba12d222fdc" 400 {
          "Docker Docs" = mkPin "ab801123-a9df-42a5-827f-7166e43d3ae5" "https://docs.docker.com/" 400;
          "crates.io" = mkPin "12bf767c-8c52-40fb-856d-0ab2d68ab203" "https://crates.io/" 500;
          "PyPI" = mkPin "ea268bfd-fc11-4068-8cca-8316f0394152" "https://pypi.org/" 600;
        };
      };

      routes = {
        "Codeforces".reference = "codeforces.com";
        "CSES".reference = "cses.fi";
        "AtCoder".reference = "atcoder.jp";
        "CP-Algorithms".reference = "cp-algorithms.com";
        "USACO Guide".reference = "usaco.guide";
        "LeetCode".reference = "leetcode.com";
        "NixOS Search".reference = "search.nixos.org";
        "Nix Documentation".reference = "nix.dev";
        "Home Manager Options".reference = "home-manager-options.extranix.com";
        "cppreference".reference = "cppreference.com";
        "Python Docs".reference = "docs.python.org";
        "Rust Docs".reference = "doc.rust-lang.org";
        "MDN".reference = "developer.mozilla.org";
        "Kaggle".reference = "kaggle.com";
        "Hugging Face".reference = "huggingface.co";
        "PyTorch Documentation".reference = "docs.pytorch.org";
        "scikit-learn".reference = "scikit-learn.org";
        "arXiv".reference = "arxiv.org";
      };
    };

    "Chill / Watch" = {
      id = "7b71cd25-6d3b-4b20-9af2-3352fc350a0b";
      position = 3000;
      icon = "🎬";

      pins = {
        "Watching" = mkFolder "4f9a2ccf-b1fe-486e-abe7-5ba8dcbc4044" 100 {
          "YouTube" = mkPin "40c2a2be-90df-4a6b-b0aa-85b84268ef72" "https://www.youtube.com/" 100;
          "Kinopoisk" = mkPin "65772eb6-1a21-4379-a1b1-1a5e22594090" "https://www.kinopoisk.ru/" 200;
          "YouTube Music" = mkPin "aa8400d9-6e0b-42d1-b270-1404fe38471b" "https://music.youtube.com/" 300;
        };

        "Anime" = mkFolder "78cd0e49-9704-4a78-9edc-d47f413a5dd8" 200 {
          "AniList" = mkPin "d95c861f-c40c-461a-ae86-9405826a9cae" "https://anilist.co/" 100;
          "Shikimori" = mkPin "269ec8dd-9dbc-49c9-91b1-eab3b3dd2ba1" "https://shikimori.one/" 200;
          "MyAnimeList" = mkPin "41df46fa-bc57-40f6-b627-e664cc4fe9aa" "https://myanimelist.net/" 300;
        };
      };

      routes = {
        "YouTube".reference = "youtube.com";
        "Short YouTube Links".reference = "youtu.be";
        "Kinopoisk".reference = "kinopoisk.ru";
        "AniList".reference = "anilist.co";
        "Shikimori".reference = "shikimori.one";
        "MyAnimeList".reference = "myanimelist.net";
      };
    };
  };

  # Essentials are globally visible in all workspaces.
  pins = {
    GitHub = (mkPin "25787836-e40a-4c75-990a-c6ea4acbf027" "https://github.com/" 100) // {
      isEssential = true;
    };

    "Google Calendar" =
      (mkPin "c2483f2b-bc33-4bc0-bdf1-185cadd24b38" "https://calendar.google.com/calendar/" 200)
      // {
        isEssential = true;
      };
  };
}
