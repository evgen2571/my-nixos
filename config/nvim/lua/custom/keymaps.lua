local map = vim.keymap.set

local opts = { noremap = true, silent = true }

-- Search / diagnostics
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map("n", "<leader>dq", vim.diagnostic.setloclist, { desc = "Diagnostics: location list" })
map("n", "<leader>df", vim.diagnostic.open_float, { desc = "Diagnostics: floating message" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics: location list" }) -- Backward-compatible alias.

-- Editing ergonomics
map("n", "J", "mzJ`z", { desc = "Join line without moving cursor" })
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
map("x", "<leader>p", [["_dP]], { desc = "Paste without replacing register" })
map("i", "<C-c>", "<Esc>", opts)

-- Keep cursor centered for common jumps.
map("n", "<C-d>", "<C-d>zz", { desc = "Half-page down centered" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half-page up centered" })
map("n", "n", "nzzzv", { desc = "Next search result centered" })
map("n", "N", "Nzzzv", { desc = "Previous search result centered" })

-- Windows / splits
map("n", "<A-\\>", "<cmd>vsplit<CR><C-l>", { noremap = true, silent = true, desc = "Vertical split" })
map("n", "<A-x>", "<cmd>q<CR>", { noremap = true, silent = true, desc = "Close window" })
-- Terminal
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
