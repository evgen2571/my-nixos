return {
	"benlubas/molten-nvim",
	version = "^1.0.0",
	ft = { "python" },
	-- Remote commands are registered by rplugin.vim; cmd stubs would delete them.

	build = ":UpdateRemotePlugins",
	dependencies = {
		{
			"3rd/image.nvim",
			build = false, -- CLI processor needs no LuaRocks/magick bindings.
			lazy = true,
			config = function()
				if not require("custom.languages.python").graphics() then
					return
				end
				local ok, err = pcall(function()
					require("image").setup({
						backend = "kitty",
						processor = "magick_cli",
						integrations = { markdown = { enabled = false }, neorg = { enabled = false } },
						max_height_window_percentage = 40,
						window_overlap_clear_enabled = true,
					})
				end)
				if not ok then
					vim.notify("Image rendering unavailable: " .. tostring(err), vim.log.levels.WARN)
				end
			end,
		},
	},
	init = function()
		vim.g.molten_output_win_max_height = 20
		vim.g.molten_auto_open_output = false
		vim.g.molten_virt_text_output = true
		vim.g.molten_virt_text_max_lines = 12
		vim.g.molten_image_provider = "none"
		vim.g.molten_auto_init_behavior = "raise"
	end,
	config = function()
		vim.api.nvim_create_autocmd("User", {
			pattern = "MoltenKernelReady",
			callback = function(ev)
				require("custom.languages.python").ready_kernels[ev.data.kernel_id] = true
			end,
		})
		vim.api.nvim_create_autocmd("User", {
			pattern = "MoltenDeinitPost",
			callback = function()
				local active = vim.fn.MoltenRunningKernels(false)
				local ready = require("custom.languages.python").ready_kernels
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
				require("custom.languages.python").prepare_runtime()
			end,
		})
		if require("custom.languages.python").graphics() then
			local ok = pcall(require, "image")
			if ok and require("image").is_enabled() then
				vim.g.molten_image_provider = "image.nvim"
			end
		end
	end,
	keys = {
		{
			"<leader>mi",
			function()
				require("custom.languages.python").kernel()
			end,
			desc = "Molten: project uv kernel",
			ft = "python",
		},
		{ "<leader>mk", "<cmd>MoltenInit<CR>", desc = "Molten: select kernel" },
		{
			"<leader>mc",
			function()
				require("custom.languages.python").cell()
			end,
			desc = "Molten: execute # %% cell",
			ft = "python",
		},
		{
			"]j",
			function()
				require("custom.languages.python").move_cell(1)
			end,
			desc = "Next Python cell",
			ft = "python",
		},
		{
			"[j",
			function()
				require("custom.languages.python").move_cell(-1)
			end,
			desc = "Previous Python cell",
			ft = "python",
		},
		{
			"<leader>ml",
			function()
				require("custom.languages.python").evaluate("MoltenEvaluateLine")
			end,
			desc = "Molten: execute line",
		},
		{
			"<leader>me",
			":<C-u>lua require('custom.languages.python').evaluate('MoltenEvaluateVisual')<CR>gv",
			mode = "x",
			desc = "Molten: execute selection",
		},
		{ "<leader>mo", "<cmd>noautocmd MoltenEnterOutput<CR>", desc = "Molten: enter output" },
		{ "<leader>mh", "<cmd>MoltenHideOutput<CR>", desc = "Molten: hide output" },
		{ "<leader>ms", "<cmd>MoltenInterrupt<CR>", desc = "Molten: interrupt" },
		{
			"<leader>mr",
			function()
				require("custom.languages.python").restart()
			end,
			desc = "Molten: restart kernel",
		},
		{ "<leader>md", "<cmd>MoltenDeinit<CR>", desc = "Molten: stop kernel" },
	},
}
