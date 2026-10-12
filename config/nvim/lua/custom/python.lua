-- Resolve from the buffer, not Neovim's startup directory or a particular host.
local M = {}
function M.root(path)
	path = path or vim.api.nvim_buf_get_name(0)
	local start = path ~= "" and vim.fs.dirname(path) or vim.fn.getcwd()
	return vim.fs.root(start, { "pyproject.toml", "uv.lock", "pytest.ini", ".git" }) or start
end
function M.python(root)
	root = root or M.root()
	local env = vim.env.UV_PROJECT_ENVIRONMENT
	if env and not vim.startswith(env, "/") then
		env = root .. "/" .. env
	end
	for _, dir in ipairs({ env or root .. "/.venv", vim.env.VIRTUAL_ENV or "" }) do
		local python = dir .. "/bin/python"
		if vim.fn.executable(python) == 1 then
			return python
		end
	end
	-- A uv project must not silently run against system site-packages.
	if vim.uv.fs_stat(root .. "/pyproject.toml") or vim.uv.fs_stat(root .. "/uv.lock") then
		return (env or root .. "/.venv") .. "/bin/python"
	end
	return vim.fn.exepath("python3")
end
function M.terminal(args, root)
	root = root or M.root()
	if vim.fn.executable(args[1]) ~= 1 then
		vim.notify("Missing executable: " .. args[1], vim.log.levels.WARN)
		return
	end
	vim.cmd("botright 12split")
	vim.fn.jobstart(args, { term = true, cwd = root })
	vim.cmd.startinsert()
end
function M.run(args)
	M.terminal(vim.list_extend({ "uv", "run" }, args))
end
function M.cell_bounds(lines, row)
	local first, last = 1, #lines
	for i, line in ipairs(lines) do
		if line:match("^%s*#%s*%%%%") then
			if i <= row then
				first = i + 1
			else
				last = i - 1
				break
			end
		end
	end
	return first, last
end
function M.cell()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local first, last = M.cell_bounds(lines, vim.fn.line("."))
	if first <= last then
		local ok, err = pcall(vim.fn.MoltenEvaluateRange, first, last)
		if not ok then
			vim.notify("Initialize a kernel with <leader>mi first: " .. tostring(err), vim.log.levels.WARN)
		end
	end
end
function M.move_cell(direction)
	vim.fn.search("^\\s*#\\s*%%", direction < 0 and "bW" or "W")
end
function M.prepare_runtime()
	-- Molten's pinned release writes a connection file under data_dir/runtime
	-- without creating that directory. Ask the provider for the actual Jupyter path.
	local provider = vim.g.python3_host_prog or vim.fn.exepath("python3")
	local result = vim.system(
		{
			provider,
			"-c",
			'from pathlib import Path; from jupyter_core.paths import jupyter_data_dir; Path(jupyter_data_dir(), "runtime").mkdir(mode=0o700, parents=True, exist_ok=True)',
		},
		{ text = true }
	):wait(5000)
	if result.code ~= 0 then
		vim.notify("Jupyter provider unavailable; apply Home Manager and run :UpdateRemotePlugins", vim.log.levels.WARN)
		return false
	end
	return true
end
function M.kernel()
	local python = M.python()
	if not python:find("/bin/python", 1, true) or python == vim.fn.exepath("python3") then
		vim.notify("Create the project environment with uv sync and add ipykernel first", vim.log.levels.WARN)
		return
	end
	-- The project path gives each kernelspec a stable, distinct name. Never installs globally managed packages.
	local name = "nvim-" .. vim.fn.sha256(M.root()):sub(1, 12)
	vim.system({
		python,
		"-m",
		"ipykernel",
		"install",
		"--user",
		"--name",
		name,
		"--display-name",
		vim.fs.basename(M.root()) .. " (uv)",
	}, { text = true }, function(result)
		vim.schedule(function()
			if result.code ~= 0 then
				vim.notify("Kernel registration failed; uv add --dev ipykernel\n" .. result.stderr, vim.log.levels.WARN)
			else
				local ok, err = pcall(vim.cmd, "MoltenInit " .. name)
				if not ok then
					vim.notify(tostring(err), vim.log.levels.WARN)
				end
			end
		end)
	end)
end
function M.graphics()
	if vim.env.NVIM_RESEARCH_IMAGES == "0" or #vim.api.nvim_list_uis() == 0 then
		return false
	end
	if not (vim.env.KITTY_WINDOW_ID or vim.env.TERM == "xterm-kitty") then
		return false
	end
	if vim.env.TMUX then
		local result = vim.system({ "tmux", "show-options", "-gv", "allow-passthrough" }, { text = true }):wait(1000)
		if result.code ~= 0 or not (result.stdout or ""):match("on") then
			return false
		end
	end
	return vim.fn.executable("magick") == 1
end
function M.notebook(sync)
	local path = vim.api.nvim_buf_get_name(0)
	if not (path:match("%.ipynb$") or (sync and path:match("%.py$"))) then
		vim.notify("NotebookPair needs an .ipynb; NotebookSync needs a paired .py or .ipynb", vim.log.levels.WARN)
		return
	end
	if vim.bo.modified then
		vim.notify("Save this buffer before notebook synchronization", vim.log.levels.WARN)
		return
	end
	local stem = path:gsub("%.ipynb$", ""):gsub("%.py$", "")
	-- Do not overwrite an unrelated Python file when first pairing.
	if not sync and vim.uv.fs_stat(stem .. ".py") then
		vim.notify(
			"Python sibling already exists; inspect its pairing metadata and use NotebookSync",
			vim.log.levels.WARN
		)
		return
	end
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local name = vim.api.nvim_buf_get_name(buf)
		if (name == stem .. ".py" or name == stem .. ".ipynb") and vim.bo[buf].modified then
			vim.notify("Save both paired buffers before synchronization", vim.log.levels.WARN)
			return
		end
	end
	if vim.fn.executable("jupytext") ~= 1 then
		vim.notify("Jupytext is unavailable; apply the Python Home Manager toolchain", vim.log.levels.WARN)
		return
	end
	local args = sync and { "jupytext", "--sync", path }
		or { "jupytext", "--set-formats", "ipynb,py:percent", "--sync", path }
	vim.system(args, { text = true }, function(result)
		vim.schedule(function()
			if result.code ~= 0 then
				vim.notify("Notebook conversion failed: " .. result.stderr, vim.log.levels.ERROR)
				return
			end
			vim.cmd.checktime()
			vim.cmd.edit(vim.fn.fnameescape(stem .. ".py"))
			vim.notify("Paired notebook synchronized; outputs remain in .ipynb")
		end)
	end)
end
return M
