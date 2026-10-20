local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

local yank_group = augroup("custom-highlight-yank", { clear = true })

autocmd("TextYankPost", {
	group = yank_group,
	desc = "Highlight yanked text",

	callback = function()
		vim.hl.on_yank()
	end,
})

local transparent_groups = {
	"Normal",
	"NormalNC",
	"NormalFloat",
	"Float",
	"FloatBorder",
	"SignColumn",
	"GitSignsAdd",
	"GitSignsChange",
	"GitSignsDelete",
	"Pmenu",
	"PmenuSel",
	"WinSeparator",
	"TelescopeNormal",
	"TelescopeBorder",
	"TelescopeSelection",
	"TelescopePreviewNormal",
	"WhichKeyFloat",
	"NotifyNormal",
	"NotifyINFOBody",
	"LineNr",
	"LineNrBelow",
	"LineNrAbove",
}

autocmd("Colorscheme", {
	desc = "Keep selected highlight groups transparent",

	callback = function()
		for _, group in ipairs(transparent_groups) do
			vim.cmd("hi " .. group .. " ctermbg=None guibg=NONE")
		end
	end,
})

-- Keep prose readable without changing window options for source code.
autocmd("FileType", {
	pattern = "markdown",
	desc = "Comfortable Markdown reading and editing",

	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.linebreak = true
		vim.opt_local.breakindent = true
		vim.opt_local.list = false
		vim.opt_local.relativenumber = false
		vim.opt_local.colorcolumn = ""
	end,
})

local focus_group = augroup("custom-window-focus", { clear = true })

autocmd({ "BufEnter", "WinEnter" }, {
	group = focus_group,
	desc = "Emphasize the active window",

	callback = function()
		vim.wo.cursorline = true
		vim.wo.colorcolumn = ""
	end,
})

autocmd("WinLeave", {
	group = focus_group,
	desc = "De-emphasize inactive windows",

	callback = function()
		vim.wo.cursorline = false
	end,
})
