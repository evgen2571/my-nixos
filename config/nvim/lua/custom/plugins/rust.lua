local function terminal_cmd(cmd)
	return function()
		vim.cmd("botright 12split")
		vim.cmd("terminal " .. cmd)
		vim.cmd("startinsert")
	end
end

return {
	"mrcjkb/rustaceanvim",
	version = "^6",
	ft = { "rust" },
	init = function()
		vim.g.rustaceanvim = {
			dap = {
				adapter = {
					type = "executable",
					command = vim.fn.exepath("lldb-dap") ~= "" and vim.fn.exepath("lldb-dap") or "lldb-dap",
					name = "lldb",
				},
			},
			server = {
				default_settings = {
					["rust-analyzer"] = {
						cargo = {
							allTargets = true,
							buildScripts = { enable = true },
							features = "all",
						},
						check = {
							allTargets = true,
							command = "clippy",
							features = "all",
						},
						checkOnSave = true,
						procMacro = { enable = true },
					},
				},
			},
			tools = {
				hover_actions = { auto_focus = true },
			},
		}
	end,
	keys = {
		{ "<leader>cra", "<cmd>RustLsp runnables<CR>", desc = "Rust: runnables", ft = "rust" },
		{ "<leader>crt", "<cmd>RustLsp testables<CR>", desc = "Rust: testables", ft = "rust" },
		{ "<leader>crm", "<cmd>RustLsp expandMacro<CR>", desc = "Rust: expand macro", ft = "rust" },
		{ "<leader>crd", "<cmd>RustLsp openDocs<CR>", desc = "Rust: open docs.rs", ft = "rust" },
		{ "<leader>cre", "<cmd>RustLsp explainError<CR>", desc = "Rust: explain error", ft = "rust" },
		{ "<leader>crh", "<cmd>RustLsp hover actions<CR>", desc = "Rust: hover actions", ft = "rust" },
		{ "<leader>crR", "<cmd>RustLsp reloadWorkspace<CR>", desc = "Rust: reload workspace", ft = "rust" },
		{
			"<leader>crk",
			terminal_cmd("cargo check --all-targets --all-features"),
			desc = "Rust: cargo check",
			ft = "rust",
		},
		{
			"<leader>crl",
			terminal_cmd("cargo clippy --all-targets --all-features"),
			desc = "Rust: cargo clippy",
			ft = "rust",
		},
		{ "<leader>crr", terminal_cmd("cargo run"), desc = "Rust: cargo run", ft = "rust" },
		{ "<leader>crw", terminal_cmd("cargo watch -x check"), desc = "Rust: cargo watch check", ft = "rust" },
	},
}
