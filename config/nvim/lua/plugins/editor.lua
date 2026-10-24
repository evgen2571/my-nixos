return {
  'NMAC427/guess-indent.nvim',

  {
    'folke/which-key.nvim',
    event = 'VimEnter',

    opts = {
      delay = 180,
      -- Keep the shortcut menu at the bottom without borders.
      preset = 'classic',
      show_help = false,

      win = {
        border = 'none',
        padding = { 0, 1 },
        height = { min = 3, max = 12 },
        no_overlap = false,
      },

      layout = {
        width = { min = 18, max = 34 },
        spacing = 2,
      },

      icons = {
        mappings = false,

        breadcrumb = '>',
        separator = '->',
        group = '+',
        keys = {
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
            require('which-key').show({ keys = '<leader>', loop = true })
          end,
          desc = 'Show all shortcut groups',
        },

        { '<leader>b', group = 'Bookmarks' },
        { '<leader>c', group = 'Code & Build' },
        { '<leader>cm', group = 'CMake' },
        { '<leader>cp', group = 'Competitive programming' },
        { '<leader>cr', group = 'Rust' },
        { '<leader>d', group = 'Debug & Diagnostics' },
        { '<leader>g', group = 'Git' },
        { '<leader>gc', group = 'Git conflicts' },
        { '<leader>h', group = 'Git hunks', mode = { 'n', 'v' } },
        { '<leader>m', group = 'Notebooks' },
        { '<leader>r', group = 'Remote SSH' },
        { '<leader>s', group = 'Search' },
        { '<leader>t', group = 'Tests & Toggles' },
        { '<leader>v', group = 'Markdown' },
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
    init = function()
      vim.api.nvim_create_autocmd('FileType', {
        pattern = {
          'alpha',
          'dashboard',
          'fzf',
          'help',
          'lazy',
          'mason',
          'notify',
          'snacks_dashboard',
          'snacks_notif',
          'snacks_terminal',
          'toggleterm',
          'Trouble',
          'trouble',
        },

        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
    end,

    config = function()
      local indentscope = require('mini.indentscope')

      indentscope.setup({
        symbol = '│',

        draw = {
          delay = 80,

          animation = indentscope.gen_animation.quadratic({
            easing = 'out',
            duration = 180,
            unit = 'total',
          }),

          priority = 50,
        },

        options = {
          try_as_border = true,
          indent_at_cursor = false,
          n_lines = 500,
        },

        mappings = {
          object_scope = 'ii',
          object_scope_with_border = 'ai',
          goto_top = '[i',
          goto_bottom = ']i',
        },
      })

      vim.api.nvim_set_hl(0, 'MiniIndentscopeSymbol', {
        link = 'Comment',
        default = true,
      })
      require('mini.ai').setup({ n_lines = 500 })
      require('mini.surround').setup()

      local statusline = require('mini.statusline')
      statusline.setup({ use_icons = vim.g.have_nerd_font })

      ---@diagnostic disable-next-line: duplicate-set-field
      statusline.section_location = function()
        return '%2l:%-2v'
      end
    end,
  },
}
