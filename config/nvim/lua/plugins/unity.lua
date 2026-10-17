local function project_root(path)
  path = vim.fn.fnamemodify(path or vim.fn.getcwd(), ':p:h')

  while path and path ~= '' do
    if vim.fn.isdirectory(path .. '/Assets') == 1
      and vim.fn.isdirectory(path .. '/Packages') == 1
      and vim.fn.isdirectory(path .. '/ProjectSettings') == 1 then
      return path
    end

    local parent = vim.fn.fnamemodify(path, ':h')
    if parent == path then
      break
    end
    path = parent
  end
end

return {
  {
    -- Unity's own Package Manager generates the .sln/.csproj files. The
    -- upstream sync plugin requires Library and reports fresh projects as
    -- invalid, so keep project detection local and platform-independent.
    'apyra/nvim-unity-sync',
    enabled = false,
  },
  {
    'nvim-lua/plenary.nvim',
    lazy = false,
    config = function()
      vim.api.nvim_create_user_command('Ustatus', function()
        local root = project_root(vim.api.nvim_buf_get_name(0))
        if not root then
          vim.notify('[Unity] No Unity project found (expected Assets, Packages, and ProjectSettings).', vim.log.levels.WARN)
          return
        end

        local solution = vim.fn.glob(root .. '/*.slnx')
        if solution == '' then
          solution = vim.fn.glob(root .. '/*.sln')
        end
        vim.notify(string.format('[Unity] Project: %s\nSolution: %s', root, solution ~= '' and solution or 'not generated yet'), vim.log.levels.INFO)
      end, { desc = 'Show Unity project status' })

      vim.api.nvim_create_user_command('Usync', function()
        local root = project_root(vim.api.nvim_buf_get_name(0))
        if not root then
          vim.notify('[Unity] No Unity project found.', vim.log.levels.WARN)
          return
        end
        vim.notify('[Unity] Project detected. Regenerate project files from Unity: Edit > Preferences > External Tools > Regenerate project files.', vim.log.levels.INFO)
      end, { desc = 'Show Unity project-file regeneration instructions' })
    end,
  },
}