return {
	"nosduco/remote-sshfs.nvim",

	cmd = {
		"RemoteSSHFSConnect",
		"RemoteSSHFSDisconnect",
		"RemoteSSHFSEdit",
		"RemoteSSHFSFindFiles",
		"RemoteSSHFSLiveGrep",
	},

	dependencies = {
		"nvim-telescope/telescope.nvim",
		"nvim-lua/plenary.nvim",
	},

	opts = {
		connections = {
			ssh_configs = {
				vim.fn.expand("$HOME") .. "/.ssh/config",
				"/etc/ssh/ssh_config",
			},
		},
	},

	config = function(_, opts)
		require("remote-sshfs").setup(opts)
		pcall(require("telescope").load_extension, "remote-sshfs")

		local api = require("remote-sshfs.api")
		vim.keymap.set("n", "<leader>rc", api.connect, { desc = "Remote SSHFS: connect" })
		vim.keymap.set("n", "<leader>rd", api.disconnect, { desc = "Remote SSHFS: disconnect" })
		vim.keymap.set("n", "<leader>re", api.edit, { desc = "Remote SSHFS: edit SSH configs" })
	end,
}
