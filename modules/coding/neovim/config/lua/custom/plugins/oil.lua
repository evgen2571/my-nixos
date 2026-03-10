return {
	"stevearc/oil.nvim",
	dependencies = { { "nvim-mini/mini.icons", opts = {} } },
	config = function()
		require("oil").setup({
			default_file_explorer = true,
			delete_to_trash = false,
			skip_confirm_for_simple_edits = true,
			columns = { "icon" },
			keymaps = { ["<C-h>"] = false },
			watch_for_changes = true,
			view_options = {
				show_hidden = true,
				natural_order = true,
				is_always_hidden = function(name, _)
					return name == ".." or name == ".git" or name == ".cache" or name == "compile_commands.json"
				end,
			},
			win_options = {
				wrap = true,
			},
		})

		vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Oil" })
		vim.keymap.set("n", "<leader>-", require("oil").toggle_float, { desc = "Float Oil" })
	end,
}
