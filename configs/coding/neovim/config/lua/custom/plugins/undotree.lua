return {
	"mbbill/undotree",
	config = function()
		vim.keymap.set("n", "<leader>t", "<CMD>UndotreeToggle<CR>", { desc = "Undo Tree" })
		vim.g.undotree_WindowLayout = 4
		vim.g.undotree_SplitWidth = 50
	end,
}
