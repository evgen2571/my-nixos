return {
	"benlubas/molten-nvim",
	version = "^1.0.0",
	ft = { "python" },

	-- Molten registers remote commands itself; Lazy cmd stubs would replace them.
	build = ":UpdateRemotePlugins",

	dependencies = {
		{
			"3rd/image.nvim",
			build = false, -- Use the ImageMagick CLI instead of LuaRocks bindings.
			lazy = true,

			config = function()
				local available, reason = require("languages.python").graphics()
				if not available then
					if vim.env.NVIM_RESEARCH_IMAGES ~= "0" and #vim.api.nvim_list_uis() > 0 then
						vim.notify("Molten images unavailable: " .. reason, vim.log.levels.WARN)
					end
					return
				end

				local ok, err = pcall(function()
					require("image").setup({
						backend = "kitty",
						processor = "magick_cli",
						integrations = { markdown = { enabled = false }, neorg = { enabled = false } },
						max_width_window_percentage = 100,
						max_height_window_percentage = 50,
						tmux_show_only_in_active_window = true,
						window_overlap_clear_enabled = true,
						window_overlap_clear_ft_ignore = {},
					})
				end)

				if ok and require("image").is_enabled() then
					-- Molten reads this once when its first command runs.
					vim.g.molten_image_provider = "image.nvim"
				else
					vim.notify(
						"Molten image.nvim initialization failed: " .. tostring(err or "provider disabled"),
						vim.log.levels.WARN
					)
				end
			end,
		},
	},

	init = function()
		vim.g.molten_output_win_max_height = math.max(1, math.floor(vim.o.lines * 0.5))
		vim.g.molten_output_win_max_width = math.max(1, vim.o.columns - 4)
		vim.g.molten_auto_open_output = false
		vim.g.molten_virt_text_output = true
		vim.g.molten_output_virt_lines = true
		vim.g.molten_virt_text_max_lines = 12
		vim.g.molten_image_provider = "none"
		vim.g.molten_auto_init_behavior = "raise"
	end,

	config = function()
		vim.api.nvim_create_autocmd("VimResized", {
			callback = function()
				vim.g.molten_output_win_max_height = math.max(1, math.floor(vim.o.lines * 0.5))
				vim.g.molten_output_win_max_width = math.max(1, vim.o.columns - 4)
				if next(require("languages.python").ready_kernels) then
					vim.fn.MoltenUpdateOption("output_win_max_height", vim.g.molten_output_win_max_height)
					vim.fn.MoltenUpdateOption("output_win_max_width", vim.g.molten_output_win_max_width)
				end
			end,
		})
		vim.api.nvim_create_autocmd("User", {
			pattern = "MoltenKernelReady",

			callback = function(ev)
				require("languages.python").ready_kernels[ev.data.kernel_id] = true
			end,
		})

		vim.api.nvim_create_autocmd("User", {
			pattern = "MoltenDeinitPost",

			callback = function()
				local active = vim.fn.MoltenRunningKernels(false)
				local ready = require("languages.python").ready_kernels

				for kernel in pairs(ready) do
					if not vim.tbl_contains(active, kernel) then
						ready[kernel] = nil
					end
				end
			end,
		})

		vim.api.nvim_create_autocmd("User", {
			group = vim.api.nvim_create_augroup("research-molten-runtime", { clear = true }),
			pattern = "MoltenInitPre",

			callback = function()
				require("languages.python").prepare_runtime()
			end,
		})
	end,

	keys = {
		{
			"<leader>mi",
			function()
				require("languages.python").kernel()
			end,
			desc = "Molten: project uv kernel",
			ft = "python",
		},

		{ "<leader>mk", "<cmd>MoltenInit<CR>", desc = "Molten: select kernel" },

		{
			"<leader>mc",
			function()
				require("languages.python").cell()
			end,
			desc = "Molten: execute # %% cell",
			ft = "python",
		},

		{
			"]j",
			function()
				require("languages.python").move_cell(1)
			end,
			desc = "Next Python cell",
			ft = "python",
		},

		{
			"[j",
			function()
				require("languages.python").move_cell(-1)
			end,
			desc = "Previous Python cell",
			ft = "python",
		},

		{
			"<leader>ml",
			function()
				require("languages.python").evaluate("MoltenEvaluateLine")
			end,
			desc = "Molten: execute line",
		},

		{
			"<leader>me",
			":<C-u>lua require('languages.python').evaluate('MoltenEvaluateVisual')<CR>gv",
			mode = "x",
			desc = "Molten: execute selection",
		},

		{ "<leader>mo", "<cmd>noautocmd MoltenEnterOutput<CR>", desc = "Molten: enter output" },
		{ "<leader>mh", "<cmd>MoltenHideOutput<CR>", desc = "Molten: hide output" },
		{ "<leader>ms", "<cmd>MoltenInterrupt<CR>", desc = "Molten: interrupt" },

		{
			"<leader>mr",
			function()
				require("languages.python").restart()
			end,
			desc = "Molten: restart kernel",
		},

		{ "<leader>md", "<cmd>MoltenDeinit<CR>", desc = "Molten: stop kernel" },
	},
}
