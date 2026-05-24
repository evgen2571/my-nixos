return {
	{
		"Civitasv/cmake-tools.nvim",
		keys = {
			{ "<leader>cb", "<cmd>CMakeBuild<CR>", desc = "CMake: build" },
			{ "<leader>cg", "<cmd>CMakeGenerateAndRefreshLSP<CR>", desc = "CMake: generate + refresh LSP" },
			{ "<leader>cr", "<cmd>CMakeRun<CR>", desc = "CMake: run" },
			{ "<leader>cs", "<cmd>CMakeSelectBuildTarget<CR>", desc = "CMake: select build target" },
		},
		config = function()
			vim.api.nvim_create_user_command("CMakeGenerateAndRefreshLSP", function()
				vim.cmd("CMakeGenerate")
				vim.cmd("LspRestart clangd")
			end, {})

			require("cmake-tools").setup({
				cmake_command = "cmake",
				ctest_command = "ctest",
				cmake_use_preset = true,
				cmake_regenerate_on_save = true,
				cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=1" },
				cmake_build_directory = "bin/${variant:buildType}",
				cmake_compile_commands_options = {
					action = "soft_link",
					target = vim.loop.cwd(),
				},
				cmake_dap_configuration = {
					name = "cpp",
					type = "codelldb",
					request = "launch",
					stopOnEntry = false,
					runInTerminal = true,
					console = "integratedTerminal",
				},
				cmake_executor = {
					name = "quickfix",
					default_opts = {
						quickfix = {
							show = "always",
							position = "belowright",
							size = 10,
							auto_close_when_success = true,
						},
					},
				},
				cmake_runner = {
					name = "terminal",
					default_opts = {
						terminal = {
							name = "Main Terminal",
							prefix_name = "[CMakeTools]: ",
							split_direction = "horizontal",
							split_size = 11,
							start_insert = false,
							focus = false,
						},
					},
				},
				cmake_notifications = {
					runner = { enabled = true },
					executor = { enabled = true },
				},
				cmake_virtual_text_support = true,
				cmake_use_scratch_buffer = false,
			})
		end,
	},
}
