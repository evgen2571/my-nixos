return {
	"MagicDuck/grug-far.nvim",

	config = function()
		require("grug-far").setup({})

		vim.keymap.set({ "n", "x" }, "<leader>si", function()
			require("grug-far").open({ visualSelectionUsage = "operate-within-range" })
		end, { desc = "grug-far: Search within range" })
	end,
}
