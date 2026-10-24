local M = {}

function M.setup()
	package.loaded.matugen = nil
	-- dofile picks up palettes generated after Neovim starts.
	local ok, theme = pcall(dofile, vim.fn.stdpath("config") .. "/lua/matugen.lua")
	ok = ok and type(theme) == "table" and type(theme.setup) == "function"

	if ok then
		package.loaded.matugen = theme
		ok = pcall(theme.setup)
	end

	if not ok then
		vim.cmd.colorscheme("base16-default-dark")
	end
end

function M.watch()
	if M.signal then
		return
	end
	M.signal = vim.uv.new_signal()
	M.signal:start("sigusr1", vim.schedule_wrap(M.setup))

	vim.api.nvim_create_autocmd("VimLeavePre", {
		once = true,

		callback = function()
			M.signal:stop()
			M.signal:close()
		end,
	})
end

return M
