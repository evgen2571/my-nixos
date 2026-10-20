return {
  {
    'nvim-telescope/telescope.nvim',
    event = 'VimEnter',

    dependencies = {
      'nvim-lua/plenary.nvim',

      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',

        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },

      { 'nvim-telescope/telescope-ui-select.nvim' },
      { 'nvim-tree/nvim-web-devicons', enabled = vim.g.have_nerd_font },
    },

    config = function()
      -- Telescope's pinned utils expect vim.F.if_nil (removed in 0.12) or
      -- vim.nonnil (added in 0.13). Keep the fallback private to Telescope.
      local utils = require('telescope.utils')

      if not utils.if_nil then
        utils.if_nil = function(value, default)
          if value == nil then
            return default
          end
          return value
        end
      end

      require('telescope').setup {
        pickers = {
          colorscheme = {
            enable_preview = true,
          },
        },

        extensions = {
          ['ui-select'] = {
            require('telescope.themes').get_dropdown(),
          },
        },
      }

      pcall(require('telescope').load_extension, 'fzf')
      pcall(require('telescope').load_extension, 'remote-sshfs')
      pcall(require('telescope').load_extension, 'ui-select')

      local builtin = require 'telescope.builtin'

      local function remote_sshfs_or_local(action, local_action)
        return function()
          local connections = package.loaded['remote-sshfs.connections']
          local api = package.loaded['remote-sshfs.api']
          if connections and api and connections.is_connected() then
            return api[action]()
          end
          return local_action()
        end
      end

      vim.keymap.set('n', '<leader>sc', builtin.colorscheme, { desc = 'Choose colorscheme' })
      vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = 'Find help topics' })
      vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = 'Find keybindings' })
      vim.keymap.set('n', '<leader>sf', remote_sshfs_or_local('find_files', function()
        builtin.find_files()
      end), { desc = 'Find files (local / SSH)' })
      vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = 'Browse search pickers' })
      vim.keymap.set('n', '<leader>sw', builtin.grep_string, { desc = 'Find word under cursor' })
      vim.keymap.set('n', '<leader>sg', remote_sshfs_or_local('live_grep', function()
        builtin.live_grep()
      end), { desc = 'Search text (local / SSH)' })
      vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = 'Find diagnostics' })
      vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = 'Resume previous search' })
      vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = 'Recent files' })
      vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = 'Switch open buffers' })

      vim.keymap.set('n', '<leader>/', function()
        builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
          winblend = 10,
          previewer = false,
        })
      end, { desc = 'Search current file' })

      vim.keymap.set('n', '<leader>s/', function()
        builtin.live_grep {
          grep_open_files = true,
          prompt_title = 'Live Grep in Open Files',
        }
      end, { desc = 'Search across open files' })

      vim.keymap.set('n', '<leader>sn', function()
        builtin.find_files { cwd = vim.fn.stdpath 'config' }
      end, { desc = 'Find Neovim config files' })
    end,
  },
}
