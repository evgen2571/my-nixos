return {
  'NMAC427/guess-indent.nvim',
  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      delay = 0,
      preset = 'modern',
      win = { border = 'rounded' },
      icons = {
        mappings = vim.g.have_nerd_font,
        keys = vim.g.have_nerd_font and {} or {
          Up = '<Up> ',
          Down = '<Down> ',
          Left = '<Left> ',
          Right = '<Right> ',
          C = '<C-…> ',
          M = '<M-…> ',
          D = '<D-…> ',
          S = '<S-…> ',
          CR = '<CR> ',
          Esc = '<Esc> ',
          ScrollWheelDown = '<ScrollWheelDown> ',
          ScrollWheelUp = '<ScrollWheelUp> ',
          NL = '<NL> ',
          BS = '<BS> ',
          Space = '<Space> ',
          Tab = '<Tab> ',
          F1 = '<F1>',
          F2 = '<F2>',
          F3 = '<F3>',
          F4 = '<F4>',
          F5 = '<F5>',
          F6 = '<F6>',
          F7 = '<F7>',
          F8 = '<F8>',
          F9 = '<F9>',
          F10 = '<F10>',
          F11 = '<F11>',
          F12 = '<F12>',
        },
      },
      spec = {
        {
          '<leader>?',
          function()
            require('which-key').show { keys = '<leader>', loop = true }
          end,
          desc = 'Show all shortcut groups',
        },
        { '<leader>b', group = '📌 Bookmarks (Harpoon)' },
        { '<leader>c', group = '🧰 Code & build' },
        { '<leader>cm', group = 'CMake' },
        { '<leader>cp', group = 'Competitive programming' },
        { '<leader>cr', group = 'Rust' },
        { '<leader>d', group = '🐛 Debug & diagnostics' },
        { '<leader>g', group = '🌿 Git' },
        { '<leader>gc', group = 'Git conflicts' },
        { '<leader>h', group = 'Git hunks', mode = { 'n', 'v' } },
        { '<leader>m', group = '🧪 Notebooks / Molten' },
        { '<leader>r', group = '🌐 Remote SSH' },
        { '<leader>s', group = '🔎 Find & search' },
        { '<leader>t', group = '🛠️ Tests & toggles' },
        { '<leader>v', group = '📖 Markdown view' },
        -- Preserve established Harpoon aliases without cluttering the guide.
        { '<leader>a', hidden = true },
        { '<leader>e', hidden = true },
      },
    },
  },
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },
  {
    'echasnovski/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }
      require('mini.surround').setup()

      local statusline = require 'mini.statusline'
      statusline.setup { use_icons = vim.g.have_nerd_font }

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },
}
