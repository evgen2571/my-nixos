local terminal_cwd = vim.fn.getcwd()

local function search(remote, local_picker)
	return function()
		local connections = package.loaded["remote-sshfs.connections"]
		if connections and connections.is_connected() then
			return require("remote-sshfs.api")[remote]()
		end
		return Snacks.picker[local_picker]()
	end
end

return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		notifier = { enabled = true, style = "minimal" },
		picker = { enabled = true },
		terminal = { win = { position = "float", width = 0.5, height = 0.4, border = "single" } },
		lazygit = { configure = true },
	},
	keys = {
		{
			"<A-i>",
			function()
				Snacks.terminal.toggle(nil, { cwd = terminal_cwd })
			end,
			mode = { "n", "t" },
			desc = "Toggle floating terminal",
		},
		{
			"<leader>gg",
			function()
				Snacks.lazygit()
			end,
			desc = "Open LazyGit",
		},
		{
			"<leader>gl",
			function()
				Snacks.lazygit.log()
			end,
			desc = "Open LazyGit log",
		},
		{
			"<leader>sc",
			function()
				Snacks.picker.colorschemes()
			end,
			desc = "Choose colorscheme",
		},
		{
			"<leader>sh",
			function()
				Snacks.picker.help()
			end,
			desc = "Find help topics",
		},
		{
			"<leader>sk",
			function()
				Snacks.picker.keymaps()
			end,
			desc = "Find keybindings",
		},
		{ "<leader>sf", search("find_files", "files"), desc = "Find files (local / SSH)" },
		{
			"<leader>ss",
			function()
				Snacks.picker.pickers()
			end,
			desc = "Browse search pickers",
		},
		{
			"<leader>sw",
			function()
				Snacks.picker.grep_word()
			end,
			desc = "Find word under cursor",
		},
		{ "<leader>sg", search("live_grep", "grep"), desc = "Search text (local / SSH)" },
		{
			"<leader>sd",
			function()
				Snacks.picker.diagnostics()
			end,
			desc = "Find diagnostics",
		},
		{
			"<leader>sr",
			function()
				Snacks.picker.resume()
			end,
			desc = "Resume previous search",
		},
		{
			"<leader>s.",
			function()
				Snacks.picker.recent()
			end,
			desc = "Recent files",
		},
		{
			"<leader><leader>",
			function()
				Snacks.picker.buffers()
			end,
			desc = "Switch open buffers",
		},
		{
			"<leader>/",
			function()
				Snacks.picker.lines()
			end,
			desc = "Search current file",
		},
		{
			"<leader>s/",
			function()
				Snacks.picker.grep_buffers()
			end,
			desc = "Search across open files",
		},
		{
			"<leader>sn",
			function()
				Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
			end,
			desc = "Find Neovim config files",
		},
		{
			"<leader>sN",
			function()
				Snacks.picker.notifications()
			end,
			desc = "Notification history",
		},
	},
}
