return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	lazy = false, -- The rewritten plugin does not support lazy loading.
	build = ":TSUpdate",
	config = function()
		local ts = require("nvim-treesitter")
		ts.setup({})
		ts.install({
			"bash",
			"c",
			"cmake",
			"cpp",
			"c_sharp",
			"diff",
			"gdscript",
			"html",
			"java",
			"lua",
			"luadoc",
			"markdown",
			"markdown_inline",
			"nix",
			"python",
			"query",
			"rust",
			"toml",
			"vim",
			"vimdoc",
		})
		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("research-treesitter", { clear = true }),
			callback = function(ev)
				-- Unsupported filetypes and parsers still downloading use syntax fallback.
				pcall(vim.treesitter.start, ev.buf)
			end,
		})
	end,
}
