local opt = vim.opt
local o = vim.o

-- UI
o.number = true
o.relativenumber = true
o.mouse = "a"
o.showmode = false
o.signcolumn = "yes"
o.termguicolors = true
o.laststatus = 3
o.showtabline = 1
o.pumblend = 10
o.winblend = 5
o.list = true
opt.listchars = { tab = "│ ", trail = "·", nbsp = "␣" }
opt.fillchars = {
	eob = " ",
	fold = " ",
	foldopen = "▾",
	foldsep = " ",
	foldclose = "▸",
	diff = "╱",
}
o.cursorline = true
o.cursorlineopt = "number,line"
o.scrolloff = 10
o.sidescrolloff = 8
o.smoothscroll = true

-- Editing
o.breakindent = true
o.undofile = true
o.confirm = true
o.tabstop = 4
o.shiftwidth = 4

-- Search
o.ignorecase = true
o.smartcase = true
o.hlsearch = false
o.incsearch = true
o.inccommand = "split"

-- Responsiveness
o.updatetime = 50
o.timeoutlen = 300

-- Splits
o.splitright = true
o.splitbelow = true

-- Sync clipboard after UI startup to avoid slowing startup.
vim.schedule(function()
	o.clipboard = "unnamedplus"
end)
