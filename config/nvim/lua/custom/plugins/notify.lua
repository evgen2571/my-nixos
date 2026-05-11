return {
	{
		"rcarriga/nvim-notify",
		config = function()
			require("notify").setup({
				stages = "slide",
				render = "minimal",
			})
			vim.notify = require("notify")
		end,
	},
}
