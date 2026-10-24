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

      sources = {
        default = { 'lsp', 'path', 'buffer', 'snippets', 'lazydev' },

        providers = {
          lazydev = { module = 'lazydev.integrations.blink', score_offset = 100 },
        },
      },

      snippets = { preset = 'default' },
      -- The native matcher needs a matching build; use Lua to avoid binary downloads.
      fuzzy = { implementation = 'lua', prebuilt_binaries = { download = false } },
      signature = { enabled = true },
    },
  },
}
