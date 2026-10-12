return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		local lint = require("lint")

		local function executable(command)
			return vim.fn.executable(command) == 1
		end

		local function append(filetype, linter)
			lint.linters_by_ft[filetype] = lint.linters_by_ft[filetype] or {}
			table.insert(lint.linters_by_ft[filetype], linter)
		end

		lint.linters_by_ft = {}

		if executable("statix") then
			append("nix", "statix")
		end

		if executable("deadnix") then
			append("nix", "deadnix")
		end

		if executable("shellcheck") then
			append("sh", "shellcheck")
			append("bash", "shellcheck")
		end

		vim.api.nvim_create_autocmd({ "BufWritePost" }, {
			group = vim.api.nvim_create_augroup("custom-lint", { clear = true }),
			callback = function()
				lint.try_lint()
			end,
		})
	end,
}
