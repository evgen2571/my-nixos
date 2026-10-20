return {
	"nvim-neotest/neotest",

	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"alfaix/neotest-gtest",
		"nvim-neotest/neotest-python",
	},

	keys = {
		{
			"<leader>tn",
			function()
				require("neotest").run.run()
			end,
			desc = "Test: nearest",
		},

		{
			"<leader>tf",
			function()
				require("neotest").run.run(vim.fn.expand("%:p"))
			end,
			desc = "Test: file",
		},

		{
			"<leader>ts",
			function()
				require("neotest").summary.toggle()
			end,
			desc = "Test: summary",
		},

		{
			"<leader>to",
			function()
				require("neotest").output.open({ enter = true })
			end,
			desc = "Test: output",
		},

		{
			"<leader>tx",
			function()
				require("neotest").run.stop()
			end,
			desc = "Test: stop",
		},

		{
			"<leader>td",
			function()
				require("dap")
				require("neotest").run.run({ strategy = "dap" })
			end,
			desc = "Test: debug nearest",
		},
	},

	config = function()
		local adapters = {}
		-- neotest-gtest parses its query at import time. A missing C++ parser
		-- must not prevent Python testing during first-time parser installation.
		local ok, gtest = pcall(require, "neotest-gtest")

		if ok then
			adapters[#adapters + 1] = gtest.setup({
				debug_adapter = "lldb",

				is_test_file = function(path)
					return path:match("_test%.cpp$") ~= nil
						or path:match("Test%.cpp$") ~= nil
						or path:match("/test_[^/]+%.cpp$") ~= nil
				end,
			})
		else
			vim.notify("GoogleTest needs :TSInstall cpp; restart Neovim after installation", vim.log.levels.WARN)
		end

		require("neotest").setup({
			discovery = { concurrent = 1 },

			adapters = vim.list_extend(adapters, {
				require("neotest-python")({
					runner = "pytest",

					python = function(root)
						return require("languages.python").python(root)
					end,

					dap = { justMyCode = false },
				}),
			}),
		})
	end,
}
