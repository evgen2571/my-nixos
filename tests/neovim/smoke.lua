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
	assert(not package.loaded.neotest)
	assert(not package.loaded.dap)
	assert(not require("lazy.core.config").plugins["molten-nvim"]._.loaded)
end)

check("Completion acceptance", function()
	require("lazy").load({ plugins = { "blink.cmp" } })
	local preset = require("blink.cmp.keymap.presets").get("default")
	assert(preset["<C-y>"][1] == "select_and_accept")
	local config = require("blink.cmp.config")
	assert(config.snippets.preset == "default")
	assert(config.fuzzy.prebuilt_binaries.download == false)
	assert(preset["<Tab>"][1] == "snippet_forward")
	assert(preset["<S-Tab>"][1] == "snippet_backward")
	assert(vim.fn.maparg("<leader>ta", "n") == "")
end)

check("Python provider", function()
	assert(vim.fn.has("python3") == 1, "Neovim must have a working Python 3 provider for Molten")
end)

check("Python cells", function()
	local py = require("languages.python")
	local lines = { "# %%", "x = 1", "# %%", "print(x)" }
	local first, last = py.cell_bounds(lines, 2)
	assert(first == 2 and last == 2)
	first, last = py.cell_bounds(lines, 3)
	assert(first == 4 and last == 4)
	assert(not py.graphics()) -- headless always uses text output
end)

check("Notebook commands and Python compatibility", function()
	local py = require("languages.python")
	assert(require("custom.python") == py, "Alias must share kernel readiness state")
	local notebook, calls = py.notebook, {}
	py.notebook = function(sync)
		calls[#calls + 1] = sync and "sync" or "pair"
	end

	local ok, err = pcall(function()
		vim.cmd.NotebookPair()
		vim.cmd.NotebookSync()
	end)

	py.notebook = notebook
	assert(ok, err)
	assert(vim.deep_equal(calls, { "pair", "sync" }))
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
	assert(require("dap-python").resolve_python() == require("languages.python").python())
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
	assert(opts.icons.mappings == false)
	assert(opts.win.border == "none")
	assert(opts.layout.width.max == 34)
	assert(opts.layout.spacing == 2)
	assert(opts.win.height.max == 12)
end)

check("Native adaptive hover", function()
	local native, captured = vim.lsp.buf.hover, nil
	vim.lsp.buf.hover = function(opts)
		captured = opts
	end
	local columns, lines = vim.o.columns, vim.o.lines
	local ok, err = pcall(function()
		vim.o.columns, vim.o.lines = 160, 50
		require("integrations.hover").show()
		assert(captured.max_width > 60 and captured.max_height > 12)
		assert(captured.wrap and captured.focusable and captured.border == "rounded")
		local width, height = captured.max_width, captured.max_height
		vim.o.columns, vim.o.lines = 80, 24
		require("integrations.hover").show()
		assert(captured.max_width < width and captured.max_height < height)
	end)
	vim.lsp.buf.hover = native
	vim.o.columns, vim.o.lines = columns, lines
	assert(ok, err)
end)

check("Snacks replacement and SSHFS routing", function()
	local plugins = require("lazy.core.config").plugins
	for _, name in ipairs({
		"telescope.nvim",
		"nvterm",
		"nvim-notify",
		"lazygit.nvim",
		"LuaSnip",
		"mini.indentscope",
		"nvim-web-devicons",
	}) do
		assert(not plugins[name], "Obsolete dependency: " .. name)
	end
	assert(Snacks.config.notifier.enabled and Snacks.config.picker.enabled)
	assert(not Snacks.config.dashboard.enabled and not Snacks.config.explorer.enabled)
	local connections, api = package.loaded["remote-sshfs.connections"], package.loaded["remote-sshfs.api"]
	local original = Snacks.picker.files
	local called
	Snacks.picker.files = function()
		called = "local"
	end
	package.loaded["remote-sshfs.connections"] = {
		is_connected = function()
			return false
		end,
	}
	package.loaded["remote-sshfs.api"] = {
		find_files = function()
			called = "remote"
		end,
	}
	local ok, err = pcall(function()
		local keys = plugins["snacks.nvim"].keys
		for _, key in ipairs(keys) do
			if key[1] == "<leader>sf" then
				key[2]()
				assert(called == "local")
				package.loaded["remote-sshfs.connections"].is_connected = function()
					return true
				end
				key[2]()
				assert(called == "remote")
			end
		end
	end)
	Snacks.picker.files = original
	package.loaded["remote-sshfs.connections"], package.loaded["remote-sshfs.api"] = connections, api
	assert(ok, err)
	require("lazy").load({ plugins = { "remote-sshfs.nvim" } })
	assert(require("remote-sshfs").config.ui.picker == "snacks")
	assert(type(require("remote-sshfs.pickers.snacks").live_grep) == "function")
end)

check("Harpoon 2 project marks and tabline", function()
	local root = vim.fn.tempname()
	vim.fn.mkdir(root, "p")
	local cwd = vim.fn.getcwd()
	vim.cmd.cd(root)
	local other = root .. "/other"
	vim.fn.mkdir(other, "p")
	local old = vim.fn.stdpath("data") .. "/harpoon.json"
	assert(vim.fn.filereadable(old) == 0, "Tests require disposable data")
	vim.fn.writefile({
		vim.json.encode({
			projects = {
				[root] = {
					mark = {
						marks = {
							{ filename = "first.py", row = 1, col = 0 },
							{ filename = "second.py", row = 1, col = 0 },
						},
					},
				},
			},
		}),
	}, old)
	local legacy = vim.json.decode(table.concat(vim.fn.readfile(old), "\n"))
	legacy.projects[other] = { mark = { marks = { { filename = "" }, { filename = "other.py", row = 1, col = 0 } } } }
	vim.fn.writefile({ vim.json.encode(legacy) }, old)
	require("lazy").load({ plugins = { "harpoon" } })
	local harpoon = require("harpoon")
	assert(harpoon:list():length() == 2, "Old marks must be imported")
	harpoon:list():select(2)
	assert(vim.api.nvim_buf_get_name(0) == root .. "/second.py")
	assert(require("integrations.bookmarks").tabline():find("HarpoonActive", 1, true))
	harpoon:list():add({ value = "third.py", context = { row = 1, col = 0 } })
	harpoon:sync()
	require("integrations.bookmarks").import()
	assert(harpoon:list():length() == 3, "Import must not replace new data")
	assert(vim.fn.filereadable(old) == 1, "Old marks must be preserved")
	harpoon:list():remove_at(1)
	assert(require("integrations.bookmarks").tabline():find("second.py", 1, true), "Tabline must survive sparse slots")
	vim.cmd.cd(other)
	assert(harpoon:list():length() == 2 and not harpoon:list():get(1))
	assert(harpoon:list():get(2).value == "other.py", "Project changes must import without renumbering")
	assert(require("integrations.bookmarks").tabline():find("2 ", 1, true))
	vim.cmd.cd(root)
	assert(harpoon:list():get(2).value == "second.py", "Project marks must persist across directory changes")
	vim.fn.delete(old)
	local path = vim.fn.stdpath("data") .. "/harpoon/" .. vim.fn.sha256(root) .. ".json"
	local saved = vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
	assert(#saved[root].__harpoon_files == 3)
	vim.cmd.cd(cwd)
	assert(harpoon:list():length() == 0, "Marks must be project-specific")
end)

check("Graphics requirements and tmux detection", function()
	local uis, executable, system = vim.api.nvim_list_uis, vim.fn.executable, vim.system
	local env = {
		TMUX = vim.env.TMUX,
		TERM = vim.env.TERM,
		TERM_PROGRAM = vim.env.TERM_PROGRAM,
		KITTY_WINDOW_ID = vim.env.KITTY_WINDOW_ID,
		NVIM_RESEARCH_IMAGES = vim.env.NVIM_RESEARCH_IMAGES,
	}
	local passthrough, magick, client = "on", true, "xterm-kitty"
	vim.api.nvim_list_uis = function()
		return { {} }
	end
	vim.fn.executable = function(cmd)
		return cmd == "magick" and (magick and 1 or 0) or 1
	end
	vim.system = function(cmd)
		return {
			wait = function()
				return { code = 0, stdout = cmd[2] == "display-message" and client or passthrough }
			end,
		}
	end
	local ok, err = pcall(function()
		vim.env.NVIM_RESEARCH_IMAGES, vim.env.KITTY_WINDOW_ID = nil, nil
		vim.env.TERM_PROGRAM, vim.env.TERM, vim.env.TMUX = nil, "tmux-256color", "test"
		local py = require("languages.python")
		assert(py.graphics(), "Detect the attached Kitty client inside tmux")
		passthrough = "all"
		assert(py.graphics())
		passthrough = "off"
		local enabled, reason = py.graphics()
		assert(not enabled and reason:find("allow-passthrough", 1, true))
		passthrough, magick = "on", false
		enabled, reason = py.graphics()
		assert(not enabled and reason:find("ImageMagick", 1, true))
		magick, client = true, "xterm-256color"
		assert(not py.graphics())
		vim.env.TMUX, vim.env.TERM = nil, "xterm-kitty"
		assert(py.graphics())
		vim.env.NVIM_RESEARCH_IMAGES = "0"
		assert(not py.graphics())
	end)
	vim.api.nvim_list_uis, vim.fn.executable, vim.system = uis, executable, system
	for _, name in ipairs({ "TMUX", "TERM", "TERM_PROGRAM", "KITTY_WINDOW_ID", "NVIM_RESEARCH_IMAGES" }) do
		vim.env[name] = env[name]
	end
	assert(ok, err)
end)

check("Discoverable keymaps", function()
	for _, lhs in ipairs({
		"<leader>?",
		"<leader>sk",
		"<leader>a",
		"<leader>e",
		"<leader>b1",
		"<leader>b2",
		"<leader>b3",
		"<leader>b4",
	}) do
		assert(vim.fn.maparg(lhs, "n") ~= "", "Missing shortcut: " .. lhs)
	end

	local spec = require("plugins.editor")[2].opts.spec
	local groups = {}

	for _, entry in ipairs(spec) do
		if entry.group then
			assert(not entry.group:find("[^%z\1-\127]"), "Group names must be text-only")
			groups[entry[1]] = entry.group
		end
	end

	assert(groups["<leader>b"])
	for _, lhs in ipairs({ "<leader>ba", "<leader>bm", "<leader>be" }) do
		assert(vim.fn.maparg(lhs, "n") == "")
	end
	assert(groups["<leader>r"] == "Remote SSH")
	assert(groups["<leader>v"])
end)

print("Neovim smoke tests passed")
vim.cmd("qa!")
