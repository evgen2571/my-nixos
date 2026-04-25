return {
	"obsidian-nvim/obsidian.nvim",
	version = "*", -- recommended, use latest release instead of latest commit
	ft = "markdown",
	opts = {
		legacy_commands = false, -- this will be removed in the next major release
		workspaces = {
			{
				name = "general",
				path = "~/obsidian/general",
			},
		},
	},
}
