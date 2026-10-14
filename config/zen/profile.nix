# Shared declarative Zen profile for PC and laptop.
# Before enabling this, replace example spaces/pins with your existing
# workspace/pin IDs to avoid duplicate entries. See docs/zen-browser.md.
{
  settings = {
    "zen.workspaces.continue-where-left-off" = true;
    "zen.window-sync.enabled" = true;
  };

  # Sine engine is installed by the existing Zen Browser flake.
  # Add Sine store directory IDs here (e.g. "Arc-2.0").
  sine = {
    enable = true;
    mods = [
      # "Arc-2.0"
    ];
  };

  # Preserve existing entries while migrating. Only enable these once all
  # existing workspace/pin IDs are represented by the declarations below.
  spacesForce = false;
  pinsForce = false;

  # Example layout; customize names, URLs, and especially IDs before enabling.
  spaces = {
    Personal = {
      id = "2ffaa943-db93-492b-89cc-91bf1aa7ee01";
      position = 1000;
      icon = "🏠";
    };
    Development = {
      id = "4fa704ee-f023-49a9-9082-c054cfce4d82";
      position = 2000;
      icon = "💻";

      pins."NixOS Packages" = {
        id = "de6b0b59-b37a-4f5b-82cb-5d36a6adab9d";
        url = "https://search.nixos.org/packages";
        position = 100;
      };
    };
    Study = {
      id = "348e8245-e85d-45e9-a707-69d7868b103f";
      position = 3000;
      icon = "📚";

      pins.Codeforces = {
        id = "1166ec46-2b19-4f9e-80f7-613249db734b";
        url = "https://codeforces.com";
        position = 100;
      };
    };
  };

  # Essentials appear across spaces. Standard pinned tabs belong under a space.
  pins.GitHub = {
    id = "c7219e49-73a8-4625-b15f-54699bf201d7";
    url = "https://github.com";
    isEssential = true;
    position = 100;
  };
}
