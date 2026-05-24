return {
	{
		"Civitasv/cmake-tools.nvim",
		ft = { "c", "cpp", "cmake" },
		cmd = {
			"CMakeBuild",
			"CMakeGenerate",
			"CMakeGenerateAndRefreshLSP",
			"CMakeRun",
			"CMakeSelectBuildTarget",
		},
		config = function()
			local function find_cmake_root(bufnr)
				local path = vim.api.nvim_buf_get_name(bufnr)
				local start = path ~= "" and vim.fs.dirname(path) or vim.uv.cwd()
				local match = vim.fs.find("CMakeLists.txt", {
					path = start,
					upward = true,
					stop = vim.uv.os_homedir(),
				})[1]

				return match and vim.fs.dirname(match) or nil
			end

			local function setup_cmake_keymaps(bufnr)
				if vim.b[bufnr].cmake_tools_keymaps_set then
					return
				end

				local root = find_cmake_root(bufnr)
				if not root then
					return
				end

				local map = function(lhs, rhs, desc)
					vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
				end

				map("<leader>cmb", "<cmd>CMakeBuild<CR>", "CMake: build")
				map("<leader>cmg", "<cmd>CMakeGenerateAndRefreshLSP<CR>", "CMake: generate + refresh LSP")
				map("<leader>cmr", "<cmd>CMakeRun<CR>", "CMake: run")
				map("<leader>cms", "<cmd>CMakeSelectBuildTarget<CR>", "CMake: select build target")

				local ok, which_key = pcall(require, "which-key")
				if ok then
					which_key.add({
						{ "<leader>cm", group = "CMake", buffer = bufnr },
					})
				end

				vim.b[bufnr].cmake_tools_keymaps_set = true
				vim.b[bufnr].cmake_tools_root = root
			end

			vim.api.nvim_create_user_command("CMakeGenerateAndRefreshLSP", function()
				vim.cmd("CMakeGenerate")
				vim.cmd("LspRestart clangd")
			end, {})

			vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
				group = vim.api.nvim_create_augroup("custom-cmake-tools-keymaps", { clear = true }),
				callback = function(event)
					setup_cmake_keymaps(event.buf)
				end,
			})

			require("cmake-tools").setup({
				cmake_command = "cmake",
				ctest_command = "ctest",
				cmake_use_preset = true,
				cmake_regenerate_on_save = true,
				cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=1" },
				cmake_build_directory = "bin/${variant:buildType}",
				cmake_compile_commands_options = {
					action = "soft_link",
					target = vim.uv.cwd(),
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

			setup_cmake_keymaps(vim.api.nvim_get_current_buf())
		end,
	},
}
