local function cp_root()
	return vim.fs.normalize(vim.fn.expand("~/dev/cp"))
end

local function in_workspace(path)
	path = vim.fs.normalize(path)
	local root = cp_root()

	local function under(directory)
		return path == directory or vim.startswith(path, directory .. "/")
	end

	-- getcwd() resolves symlinks, while imported buffer names may retain them.
	return under(root) or under(vim.uv.fs_realpath(root) or root)
end

local function slug(value)
	local result = (value or ""):lower():gsub("[^%w_-]+", "-"):gsub("%-+", "-"):gsub("^%-+", ""):gsub("%-+$", "")
	return result ~= "" and result or "unknown"
end

-- URL IDs keep paths stable if a problem's display title changes.
local function problem_location(task)
	local host, path = (task.url or ""):match("^https?://([^/]+)(/[^?#]*)")

	if host and (host == "codeforces.com" or host:match("%.codeforces%.com$")) then
		local contest, index = path:match("^/contest/(%d+)/problem/([%w]+)")
		if not contest then
			contest, index = path:match("^/problemset/problem/(%d+)/([%w]+)")
		end
		if not contest then
			contest, index = path:match("^/gym/(%d+)/problem/([%w]+)")
		end
		if not contest then
			contest, index = path:match("^/problemset/gymProblem/(%d+)/([%w]+)")
		end
		if contest then
			return cp_root() .. "/codeforces/" .. contest, index
		end
	end

	local judge, contest = (task.group or ""):match("^(.-) %- (.+)$")
	return cp_root() .. "/" .. slug(judge or host or task.group) .. "/" .. slug(contest), slug(task.name)
end

local function cache_root()
	return vim.fn.stdpath("cache") .. "/competitest"
end

local function receive(mode)
	require("competitest.receive").stop_receiving()
	require("competitest.commands").receive(mode)
end

return {
	"xeluxee/competitest.nvim",
	dependencies = { "MunifTanjim/nui.nvim" },
	cmd = "CompetiTest",

	keys = {
		{
			"<leader>cpi",
			function()
				receive("problem")
			end,
			desc = "CP: receive problem",
		},

		{
			"<leader>cpc",
			function()
				receive("contest")
			end,
			desc = "CP: receive contest",
		},

		{ "<leader>cpa", "<cmd>CompetiTest add_testcase<CR>", desc = "CP: add testcase" },
		{ "<leader>cpe", "<cmd>CompetiTest edit_testcase<CR>", desc = "CP: edit testcase" },
	},

	init = function()
		local receiver_started = false

		local function setup_buffer(bufnr)
			local path = vim.api.nvim_buf_get_name(bufnr)

			if in_workspace(path) or in_workspace(vim.fn.getcwd()) then
				require("lazy").load({ plugins = { "competitest.nvim" } })

				if not receiver_started then
					receiver_started = true
					receive("problem")
				end
			end

			if vim.bo[bufnr].filetype ~= "cpp" or not in_workspace(path) then
				return
			end

			vim.keymap.set("n", "<F6>", function()
				-- Mirror the source path in the cache so two contests can both have A.cpp.
				vim.fn.mkdir(cache_root() .. vim.fs.dirname(vim.api.nvim_buf_get_name(0)), "p")
				vim.cmd("CompetiTest run")
			end, { buffer = bufnr, desc = "CP: compile and run samples" })
		end

		vim.api.nvim_create_autocmd({ "BufEnter", "FileType", "VimEnter", "DirChanged" }, {
			group = vim.api.nvim_create_augroup("custom-competitest", { clear = true }),

			callback = function()
				setup_buffer(vim.api.nvim_get_current_buf())
			end,
		})
	end,

	opts = function()
		local binary = cache_root() .. "$(ABSDIR)/$(FNOEXT)"

		return {
			companion_port = 27121,
			template_file = { cpp = "~/dev/cp/cf-template.cpp" },
			evaluate_template_modifiers = false, -- copy the template byte for byte
			received_files_extension = "cpp",

			received_problems_path = function(task, extension)
				local directory, name = problem_location(task)
				return directory .. "/" .. name .. "." .. extension
			end,

			received_contests_directory = function(task)
				return problem_location(task)
			end,

			received_contests_problems_path = function(task, extension)
				local _, name = problem_location(task)
				return name .. "." .. extension
			end,

			received_problems_prompt_path = false,
			received_contests_prompt_directory = false,
			received_contests_prompt_extension = false,
			open_received_problems = true,
			open_received_contests = true,

			-- Keep existing samples when importing the same problem again.
			replace_received_testcases = false,
			testcases_use_single_file = false,
			testcases_directory = "tests",

			-- Compile into the cache so generated binaries stay outside the project.
			compile_command = {
				cpp = { exec = "g++", args = { "-std=c++20", "-O2", "-Wall", "-Wextra", "$(FNAME)", "-o", binary } },
			},

			run_command = { cpp = { exec = binary } },
			save_current_file = true,
			multiple_testing = 1,
			maximum_time = 5000,
			output_compare_method = "squish",
			runner_ui = { viewer = { open_when_compilation_fails = true } },
		}
	end,

	config = function(_, opts)
		require("competitest").setup(opts)
	end,
}
