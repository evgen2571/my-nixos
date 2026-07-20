return {
  {
    -- Keeps Assembly-CSharp.csproj in sync when files are created, deleted,
    -- or renamed from Neovim. The plugin must be loaded before C# buffers.
    'apyra/nvim-unity-sync',
    lazy = false,
    dependencies = {
      -- nvim-unity-sync listens to nvim-tree's file events. Neo-tree remains
      -- the configured file browser; this dependency only supplies the event API.
      {
        'nvim-tree/nvim-tree.lua',
        lazy = false,
      },
    },
    config = function()
      require('unity.plugin').setup {
        -- Do not set unity_path on Linux: :Uopen is optional and the upstream
        -- plugin's default is a Windows path. Unity's own package handles the
        -- editor integration and project-file regeneration.
        unity_cs_template = false,
      }
    end,
  },
}
