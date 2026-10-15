# Shared declarative Zen profile for PC and laptop.
# Adopt existing UUIDs before enabling if you want to preserve existing spaces.
# See docs/zen-browser.md.
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

  # Zen 1.22.2b ships keyboard shortcuts schema 20.
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
      id = "3a84855a-d00d-4b5b-a392-b93a25a261a0";
      position = 1000;
      icon = "✦";
      pins = {
        ChatGPT = mkPin "0a2fecde-fff1-45c4-b654-27383b130d0c" "https://chatgpt.com/" 100;
      }
      // (import ./chatgpt-projects.nix);
      routes = {
        "ChatGPT".reference = "chatgpt.com";
        "Legacy ChatGPT".reference = "chat.openai.com";
      };
    };

    Development = {
      id = "4fa704ee-f023-49a9-9082-c054cfce4d82";
      position = 2000;
      icon = "💻";
      pins = {
        "Competitive Programming" = mkFolder "41458320-bc66-4333-9486-304716712b47" 100 {
          "Codeforces" = mkPin "1166ec46-2b19-4f9e-80f7-613249db734b" "https://codeforces.com/" 100;
          "CSES" = mkPin "36755e34-1c42-4063-88fd-e8bc5c54a937" "https://cses.fi/problemset/" 200;
          "AtCoder" = mkPin "24be4815-f0db-48a4-8738-78a4f5769f84" "https://atcoder.jp/" 300;
          "CP-Algorithms" = mkPin "edd51c4d-6401-4baa-9ec9-d53137771ffa" "https://cp-algorithms.com/" 400;
          "USACO Guide" = mkPin "3b179b51-92c3-4032-8096-85fcd9d90843" "https://usaco.guide/" 500;
          "LeetCode" = mkPin "194a40f9-82be-4d9c-a6c1-8db74b9a67a0" "https://leetcode.com/problemset/" 600;
        };

        "Documentation" = mkFolder "52180e72-d6bf-4b9a-993d-75eb8a7042f3" 200 {
          "NixOS Packages" =
            mkPin "de6b0b59-b37a-4f5b-82cb-5d36a6adab9d" "https://search.nixos.org/packages"
              100;
          "NixOS Options" =
            mkPin "46cd7b8b-49b5-4e14-8cd8-e7a8ab981024" "https://search.nixos.org/options"
              200;
          "Home Manager Options" =
            mkPin "3b0666cc-8add-4e17-b945-c6dfe11b04de" "https://home-manager-options.extranix.com/"
              300;
          "cppreference" = mkPin "56285c02-b5c2-4181-90d3-525409973154" "https://en.cppreference.com/w/" 400;
          "Python Docs" = mkPin "e624e4f9-ae2c-49ac-8f37-6838cf7ffe9f" "https://docs.python.org/3/" 500;
          "Rust Docs" = mkPin "49b153cc-c0dd-4668-b80a-5e72d91dfe88" "https://doc.rust-lang.org/std/" 600;
          "MDN" =
            mkPin "7524ef73-d6c6-41cb-b7fb-47afbba4c1f4" "https://developer.mozilla.org/en-US/docs/Web"
              700;
        };

        "ML and Research" = mkFolder "673d3c02-cb85-4fdf-acea-75f108d8d121" 300 {
          "Kaggle" = mkPin "faa09666-ade2-4f5a-b994-d017dbc9fe1e" "https://www.kaggle.com/" 100;
          "Hugging Face" = mkPin "f3183a06-d75e-4080-88ac-e8dc864a7842" "https://huggingface.co/" 200;
          "PyTorch Docs" =
            mkPin "c0d1a83e-ae73-45a8-9131-c674a352a8ca" "https://docs.pytorch.org/docs/stable/"
              300;
          "scikit-learn" =
            mkPin "28f0064d-5c01-4506-9cca-6326623b7d68" "https://scikit-learn.org/stable/"
              400;
          "arXiv" = mkPin "0f150af6-db6b-45fb-9704-6a96cfadfc6c" "https://arxiv.org/" 500;
        };

        "Developer Tools" = mkFolder "deb74e37-a8d0-4ca8-be37-04981e4a4333" 400 {
          "my-nixos" =
            mkPin "79d53cbf-bb38-40eb-afc1-de90aa9de141" "https://github.com/evgen2571/my-nixos"
              100;
          "Actline" = mkPin "740cfbb5-b9b2-4cad-a131-4e72b5da0624" "https://github.com/evgen2571/actline" 200;
          "Vestra" = mkPin "ccbd9c6f-3c36-4af1-bd49-5b5813b62460" "https://github.com/evgen2571/vestra" 300;
          "Docker Docs" = mkPin "2f28b5ab-dd5b-43b3-962b-daaa9bacc24b" "https://docs.docker.com/" 400;
          "crates.io" = mkPin "0c0ea58f-6f62-4c61-9aea-b412a93803f4" "https://crates.io/" 500;
          "PyPI" = mkPin "f87b6ae5-86ae-46c8-a2ee-6f80bbf133ed" "https://pypi.org/" 600;
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
      id = "2b69e16a-723d-4022-9e93-15e0bd4157fe";
      position = 3000;
      icon = "🎬";
      pins = {
        "Watching" = mkFolder "ab92f9cf-e4bd-4c80-b45e-b1e1767e91a3" 100 {
          "YouTube" = mkPin "53f6c054-79c9-49d1-b4a5-95bb62a889c3" "https://www.youtube.com/" 100;
          "Kinopoisk" = mkPin "8c0f1327-1de5-4371-8582-e8056b38c086" "https://www.kinopoisk.ru/" 200;
          "YouTube Music" = mkPin "6a71bb68-a770-4ce8-85dc-834567e8081b" "https://music.youtube.com/" 300;
        };

        "Anime" = mkFolder "76cf049d-d39e-4eba-b01c-bd23ac69fce1" 200 {
          "AniList" = mkPin "1c17a43a-dcc1-4907-922f-fc88cde2fab2" "https://anilist.co/" 100;
          "Shikimori" = mkPin "8398f15f-aab5-4497-9c6e-7d803d3e35e2" "https://shikimori.one/" 200;
          "MyAnimeList" = mkPin "0a62b7d9-9002-47a6-a53f-7153788371c8" "https://myanimelist.net/" 300;
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
    GitHub = (mkPin "c7219e49-73a8-4625-b15f-54699bf201d7" "https://github.com/" 100) // {
      isEssential = true;
    };
    "Google Calendar" =
      (mkPin "78f37ac0-5498-4395-b37e-1d3bb5258822" "https://calendar.google.com/calendar/" 200)
      // {
        isEssential = true;
      };
  };
}
