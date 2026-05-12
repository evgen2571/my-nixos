return {
	{
		"ThePrimeagen/harpoon",
		depencencies = { "nvim-lua/plenary.nvim" },
		config = function()
			require("harpoon").setup({
				tabline = {
					enabled = true,
					show_icons = true,
				},
			})

			local harpoon_mark = require("harpoon.mark")
			local harpoon_ui = require("harpoon.ui")
			vim.keymap.set("n", "<leader>a", harpoon_mark.add_file, { desc = "[A]dd file to Harpoon" })
			vim.keymap.set("n", "<leader>e", harpoon_ui.toggle_quick_menu, { desc = "Open Harpoon" })
			vim.keymap.set("n", "<M-h>", function()
				harpoon_ui.nav_file(1)
			end)
			vim.keymap.set("n", "<M-t>", function()
				harpoon_ui.nav_file(2)
			end)
			vim.keymap.set("n", "<M-n>", function()
				harpoon_ui.nav_file(3)
			end)
			vim.keymap.set("n", "<M-s>", function()
				harpoon_ui.nav_file(4)
			end)
			vim.cmd("highlight! HarpoonInactive guibg=NONE guifg=#63698c")
			vim.cmd("highlight! HarpoonActive guibg=NONE guifg=white")
			vim.cmd("highlight! HarpoonNumberActive guibg=NONE guifg=#7aa2f7")
			vim.cmd("highlight! HarpoonNumberInactive guibg=NONE guifg=#7aa2f7")
			vim.cmd("highlight! TabLineFill guibg=NONE guifg=white")
		end,
	},
}
