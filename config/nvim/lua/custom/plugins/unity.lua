return {
  {
    -- Keeps Unity project files in sync when C# files change from Neovim.
    -- The companion Unity package is installed per project from:
    -- https://github.com/apyra/nvim-unity.git
    'apyra/nvim-unity-sync',
    ft = { 'cs' },
    config = function()
      require('unity.plugin').setup()

      -- nvim-unity-sync currently installs a VimLeave autocommand that runs
      -- `pkill -f unity2025`. Closing Neovim must not terminate Unity.
      for _, autocmd in ipairs(vim.api.nvim_get_autocmds { event = 'VimLeave' }) do
        if autocmd.command == "os.execute('pkill -f unity2025')" then
          vim.api.nvim_del_autocmd(autocmd.id)
        end
      end
    end,
  },
}
