return {
	{
		"zbirenbaum/copilot.lua",
		dependencies = {
			{
				"copilotlsp-nvim/copilot-lsp",
				init = function()
					vim.g.copilot_nes_debounce = 500
				end,
			},
		},
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				panel = { enabled = false },

				-- Normal Copilot code completions as inline ghost text.
				suggestion = {
					enabled = true,
					auto_trigger = true,
					hide_during_completion = true,
					debounce = 75,
					keymap = {
						accept = "<M-a>",
						accept_word = false,
						accept_line = false,
						next = "<M-]>",
						prev = "<M-[>",
						dismiss = "<Esc>",
					},
				},

				nes = {
					enabled = false,
				},
			})
		end,
	},
}
