return {
  'nvim-neo-tree/neo-tree.nvim',
  version = '*',

  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
    'MunifTanjim/nui.nvim',
  },

  lazy = false,

  keys = {
    { '\\', ':Neotree reveal<CR>', desc = 'NeoTree reveal', silent = true },
  },

  opts = {
    filesystem = {
      window = {
        mappings = {
          ['\\'] = 'close_window',
        },
      },
    },

    -- nvim-unity-sync listens to nvim-tree events, while this configuration
    -- uses neo-tree. Re-scan the Assets tree after neo-tree changes so the
    -- generated Assembly-CSharp.csproj is updated immediately.
    event_handlers = {
      {
        event = 'file_added',

        handler = function()
          vim.schedule(function()
            pcall(vim.cmd, 'Usync')
          end)
        end,
      },

      {
        event = 'file_deleted',

        handler = function()
          vim.schedule(function()
            pcall(vim.cmd, 'Usync')
          end)
        end,
      },

      {
        event = 'file_moved',

        handler = function()
          vim.schedule(function()
            pcall(vim.cmd, 'Usync')
          end)
        end,
      },

      {
        event = 'file_renamed',

        handler = function()
          vim.schedule(function()
            pcall(vim.cmd, 'Usync')
          end)
        end,
      },
    },
  },
}
