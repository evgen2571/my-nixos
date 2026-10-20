return {
	"mbbill/undotree",

	keys = {
		{ "<leader>tu", "<cmd>UndotreeToggle<CR>", desc = "Toggle undo tree" },
	},

	init = function()
		vim.g.undotree_WindowLayout = 4
		vim.g.undotree_SplitWidth = 50
	end,
}
