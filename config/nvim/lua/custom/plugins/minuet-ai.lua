return {
	"milanglacier/minuet-ai.nvim",
	event = "InsertEnter",
	keys = {
		{
			"<leader>ta",
			function()
				require("minuet.virtualtext").action.toggle_auto_trigger()
			end,
			desc = "Toggle AI completion for buffer",
		},
	},
	config = function()
		require("minuet").setup({
			virtualtext = {
				-- Manual suggestions by default; opt into inference per buffer.
				-- Use auto_trigger_ignore_ft below if a filetype is too noisy.
				auto_trigger_ft = {},
				auto_trigger_ignore_ft = {},
				show_on_completion_menu = false,
				keymap = {
					-- accept whole completion
					accept = "<C-y>",
					-- accept one line
					accept_line = "<A-a>",
					-- accept n lines (prompts for number)
					-- e.g. "A-z 2 CR" will accept 2 lines
					accept_n_lines = "<A-z>",
					-- Cycle to prev completion item, or manually invoke completion
					prev = "<A-[>",
					-- Cycle to next completion item, or manually invoke completion
					next = "<A-]>",
					dismiss = "<A-e>",
				},
			},

			provider = "openai_fim_compatible",
			n_completions = 1, -- recommend for local model for resource saving
			-- I recommend beginning with a small context window size and incrementally
			-- expanding it, depending on your local computing power. A context window
			-- of 512, serves as an good starting point to estimate your computing
			-- power. Once you have a reliable estimate of your local computing power,
			-- you should adjust the context window to a larger value.
			context_window = 512,
			provider_options = {
				openai_fim_compatible = {
					-- For Windows users, TERM may not be present in environment variables.
					-- Consider using APPDATA instead.
					api_key = "TERM",
					name = "Ollama",
					end_point = "http://localhost:11434/v1/completions",
					model = "qwen2.5-coder:1.5b",
					optional = {
						max_tokens = 56,
						top_p = 0.9,
					},
				},
			},
		})
	end,
}
