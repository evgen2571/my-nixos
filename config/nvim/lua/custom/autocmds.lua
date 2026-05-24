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
