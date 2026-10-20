return {
  {
    'habamax/vim-godot',
    ft = { 'gdscript', 'gsl' },

    init = function()
      -- The Nix module provides the Godot 4 executable as `godot4`.
      vim.g.godot_executable = 'godot4'
    end,
  },
}
