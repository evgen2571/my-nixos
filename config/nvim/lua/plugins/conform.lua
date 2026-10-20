return {
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = { 'ConformInfo' },

    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true, lsp_format = 'fallback' }
        end,
        mode = '',
        desc = '[F]ormat buffer',
      },
    },

    opts = {
      notify_on_error = false,

      format_on_save = function(bufnr)
        local disable_filetypes = { c = true, cpp = true, markdown = true }

        if disable_filetypes[vim.bo[bufnr].filetype] then
          return nil
        else
          return {
            timeout_ms = 500,
            lsp_format = 'fallback',
          }
        end
      end,

      formatters_by_ft = {
        lua = { 'stylua' },
        rust = { 'rustfmt' },
        python = { 'ruff_format', 'black', stop_after_first = true },
        nix = { 'nixfmt', 'alejandra', stop_after_first = true },
        sh = { 'shfmt' },
        bash = { 'shfmt' },
        cpp = { 'clang_format' },
        c = { 'clang_format' },
        gdscript = { 'gdformat' },
        java = { 'google-java-format' },
        markdown = { 'prettier' },
      },

      formatters = {
        clang_format = {
          command = 'clang-format',
          args = { '--assume-filename', '$FILENAME' },
        },
      },
    },
  },
}
