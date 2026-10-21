return {
  {
    'saghen/blink.cmp',
    event = 'VimEnter',
    version = '1.*',

    dependencies = {
      'folke/lazydev.nvim',
    },

    opts = {
      keymap = {
        preset = 'default',
      },

      appearance = {
        nerd_font_variant = 'normal',
      },

      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 100 },
      },

      -- Suggestions come from project tools, buffers, and snippets.
      sources = {
        default = { 'lsp', 'path', 'buffer', 'snippets', 'lazydev' },

        providers = {
          lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
        },
      },

      snippets = { preset = 'default' },
      -- Keep the locked Lua plugin reproducible; Rust needs a matching Nix-built library.
      fuzzy = { implementation = 'lua', prebuilt_binaries = { download = false } },
      signature = { enabled = true },
    },
  },
}
