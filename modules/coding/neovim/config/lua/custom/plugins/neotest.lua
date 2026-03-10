return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"antoinemadec/FixCursorHold.nvim",
		"nvim-treesitter/nvim-treesitter",
		"alfaix/neotest-gtest",
		"nvim-neotest/neotest-vim-test",
	},
	lazy = true,

	config = function()
		require("neotest").setup({
			adapters = {
				require("neotest-gtest")({
					gtest_command = "./build/tests/*",

					gtest_cmake_command = "ctest",
					gtest_cmake_args = { "--output-on-failure" },

					env = {
						GTEST_FILTER = "*",
					},

					cwd = function()
						return vim.fn.getcwd()
					end,

					is_test_file = function(file_path)
						return string.match(file_path, "_test%.cpp$") or string.match(file_path, "Test%.cpp$")
					end,
				}),
			},
		})
	end,
}
