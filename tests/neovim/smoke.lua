vim.notify = function(msg)
	print(msg)
end
-- Run with the repository config on runtimepath and plugins installed (see README).
local function check(name, fn)
	local ok, err = pcall(fn)
	if not ok then
		error(name .. ": " .. tostring(err))
	end
	print("PASS: " .. name)
end
check("startup and lazy loading", function()
	assert(package.loaded["nvim-treesitter"])
	assert(not package.loaded.minuet)
	assert(not package.loaded.neotest)
	assert(not package.loaded.dap)
	assert(not require("lazy.core.config").plugins["molten-nvim"]._.loaded)
end)
check("Python provider", function()
	assert(vim.fn.has("python3") == 1, "Neovim must have a working Python 3 provider for Molten")
end)
check("Python cells", function()
	local py = require("custom.python")
	local lines = { "# %%", "x = 1", "# %%", "print(x)" }
	local first, last = py.cell_bounds(lines, 2)
	assert(first == 2 and last == 2)
	first, last = py.cell_bounds(lines, 3)
	assert(first == 4 and last == 4)
	assert(not py.graphics()) -- headless always uses text output
end)
check("Tree-sitter and textobjects", function()
	vim.cmd.edit(vim.fn.tempname() .. ".py")
	vim.api.nvim_buf_set_lines(
		0,
		0,
		-1,
		false,
		{ "def square(x):", "    return x * x", "", "class Model:", "    pass" }
	)
	vim.bo.filetype = "python"
	local parser = vim.treesitter.get_parser(0, "python")
	assert(parser:parse()[1]:root():type() == "module")
	assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()])
	local query = vim.treesitter.query.get("python", "textobjects")
	local found = false
	for _, capture in ipairs(query.captures) do
		if capture == "function.outer" then
			found = true
		end
	end
	assert(found)
	assert(vim.fn.maparg("af", "o") ~= "")
	vim.api.nvim_win_set_cursor(0, { 1, 0 })
	vim.cmd("normal daf")
	assert(not table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n"):find("def square", 1, true))
	vim.bo.modified = false
end)
check("DAP registration", function()
	local dap = require("dap")
	assert(dap.adapters.lldb.command == vim.fn.exepath("lldb-dap"))
	assert(vim.fn.executable(dap.adapters.lldb.command) == 1)
	assert(dap.configurations.cpp[1].type == "lldb")
	assert(dap.configurations.c[1].type == "lldb")
	assert(type(dap.adapters.python) == "function")
	assert(type(dap.adapters.go) == "function")
	assert(require("dap-python").resolve_python() == require("custom.python").python())
end)
check("pytest and GoogleTest adapters", function()
	require("neotest")
	local adapter = require("neotest-python")({ runner = "pytest" })
	assert(adapter.is_test_file("/tmp/test_example.py"))
	assert(require("neotest-gtest.config").debug_adapter == "lldb")
	assert(require("neotest-gtest").is_test_file("/tmp/ExampleTest.cpp"))
	for _, lhs in ipairs({ "<leader>tn", "<leader>tf", "<leader>td" }) do
		assert(vim.fn.maparg(lhs, "n") ~= "")
	end
end)
check("LSP, formatting and lint policy", function()
	assert(vim.lsp.config.pyright.settings.python.analysis.diagnosticMode == "openFilesOnly")
	assert(vim.lsp.config.pyright.settings.pyright.disableOrganizeImports)
	assert(vim.lsp.config.ruff)
	local lint = require("lint")
	assert(not lint.linters_by_ft.python)
	assert(require("conform").get_formatter_info("ruff_format", 0).available)
end)
check("Markdown editing without Obsidian", function()
	local plugins = require("lazy.core.config").plugins
	assert(plugins["render-markdown.nvim"])
	assert(not plugins["obsidian.nvim"])
	assert(plugins["render-markdown.nvim"].opts.completions.lsp.enabled)
	assert(vim.lsp.config.marksman)
	vim.cmd.edit(vim.fn.tempname() .. ".md")
	vim.bo.filetype = "markdown"
	assert(vim.wo.wrap and vim.wo.linebreak and vim.wo.breakindent)
	assert(not vim.wo.list and not vim.wo.relativenumber)
	assert(vim.fn.maparg("<leader>vr", "n") ~= "")
	assert(vim.fn.maparg("<leader>vp", "n") ~= "")
	assert(require("conform").get_formatter_info("prettier", 0).available)
	vim.bo.modified = false
end)
check("Popup documentation and compact shortcut menu", function()
	local hover = vim.fn.maparg("K", "n", false, true)
	assert(hover.desc == "Documentation: hover at cursor")
	assert(vim.lsp.config.gopls, "gopls LSP is not registered")

	local opts = require("lazy.core.config").plugins["which-key.nvim"].opts
	assert(opts.preset == "classic")
	assert(opts.win.border == "none")
	assert(opts.layout.width.max == 34)
	assert(opts.layout.spacing == 2)
	assert(opts.win.height.max == 12)
end)
check("Telescope fallback for Neovim 0.12", function()
	require("lazy").load({ plugins = { "telescope.nvim" } })
	local utils = require("telescope.utils")
	assert(type(utils.if_nil) == "function")
	assert(utils.if_nil(nil, "fallback") == "fallback")
	assert(utils.if_nil(false, true) == false)
end)
check("Discoverable keymaps", function()
	for _, lhs in ipairs({
		"<leader>?", "<leader>sk", "<leader>ba", "<leader>bm",
		"<leader>b1", "<leader>b2", "<leader>b3", "<leader>b4",
	}) do
		assert(vim.fn.maparg(lhs, "n") ~= "", "Missing shortcut: " .. lhs)
	end
	local spec = require("lazy.core.config").plugins["which-key.nvim"].opts.spec
	local groups = {}
	for _, entry in ipairs(spec) do
		if entry.group then
			groups[entry[1]] = entry.group
		end
	end
	assert(groups["<leader>b"])
	assert(groups["<leader>r"] == "🌐 Remote SSH")
	assert(groups["<leader>v"])
end)
check("AI toggle without Ollama inference", function()
	require("minuet")
	local action = require("minuet.virtualtext").action
	action.toggle_auto_trigger()
	assert(vim.b.minuet_virtual_text_auto_trigger)
	action.toggle_auto_trigger()
	assert(not vim.b.minuet_virtual_text_auto_trigger)
end)
print("Neovim smoke tests passed")
vim.cmd("qa!")
