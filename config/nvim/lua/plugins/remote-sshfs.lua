return {
	"nosduco/remote-sshfs.nvim",

	cmd = {
		"RemoteSSHFSConnect",
		"RemoteSSHFSDisconnect",
		"RemoteSSHFSEdit",
		"RemoteSSHFSReload",
		"RemoteSSHFSFindFiles",
		"RemoteSSHFSLiveGrep",
	},

	dependencies = {
		"folke/snacks.nvim",
		"nvim-lua/plenary.nvim",
	},

	keys = {
		{ "<leader>rc", "<cmd>RemoteSSHFSConnect<CR>", desc = "Remote SSHFS: connect" },
		{ "<leader>rd", "<cmd>RemoteSSHFSDisconnect<CR>", desc = "Remote SSHFS: disconnect" },
		{ "<leader>re", "<cmd>RemoteSSHFSEdit<CR>", desc = "Remote SSHFS: edit SSH configs" },
	},

	opts = {
		ui = { picker = "snacks" },
		connections = {
			ssh_configs = {
				vim.fn.expand("$HOME") .. "/.ssh/config",
				"/etc/ssh/ssh_config",
			},
		},
	},
}
