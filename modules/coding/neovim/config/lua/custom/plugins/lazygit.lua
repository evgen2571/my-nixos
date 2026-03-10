return {
	"kdheepak/lazygit.nvim",
	lazy = true,
	cmd = {
		"LazyGit",
		"LazyGitConfig",
		"LazyGitCurrentFile",
		"LazyGitFilter",
		"LazyGitFilterCurrentFile",
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	keys = {
		{ "<leader>gg", "<CMD>LazyGit<CR>", desc = "Open Lazy[G]it" },
		{ "<leader>gl", "<CMD>LazyGitLog<CR>", desc = "Open Lazy[G]it [L]og" },
	},
}
