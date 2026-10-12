return {
	"RRethy/base16-nvim",
	lazy = false,
	priority = 1000,
	config = function()
		require("custom.theme").setup()
		require("custom.theme").watch()
	end,
}
