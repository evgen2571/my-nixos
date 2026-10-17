return {
	"nvim-java/nvim-java",
	ft = "java",
	cond = function()
		return vim.env.JAVA_HOME ~= nil and vim.env.JDTLS_HOME ~= nil
	end,

	config = function()
		require("java").setup({
			jdk = {
				auto_install = false,
				path = vim.env.JAVA_HOME,
			},
			jdtls = {
				auto_install = false,
				path = vim.env.JDTLS_HOME,
			},
			lombok = {
				enable = false,
			},
			java_test = {
				enable = false,
			},
			java_debug_adapter = {
				enable = false,
			},
			spring_boot_tools = {
				enable = false,
			},
		})

		vim.lsp.config("jdtls", {
			capabilities = require("blink.cmp").get_lsp_capabilities(),
		})
		vim.lsp.enable("jdtls")
	end,
}
