local function add_file()
	require("harpoon.mark").add_file()
end

local function open_menu()
	require("harpoon.ui").toggle_quick_menu()
end

local function select_file(index)
	return function()
		require("harpoon.ui").nav_file(index)
	end
end

local keys = {
	{ "<leader>ba", add_file, desc = "Bookmarks: add current file" },
	{ "<leader>bm", open_menu, desc = "Bookmarks: show menu" },
	-- Keep existing bindings for muscle memory.
	{ "<leader>a", add_file, desc = "Bookmarks: add file (legacy)" },
	{ "<leader>e", open_menu, desc = "Bookmarks: menu (legacy)" },
}

for index, alt in ipairs({ "<M-a>", "<M-s>", "<M-d>", "<M-f>" }) do
	keys[#keys + 1] = {
		"<leader>b" .. index,
		select_file(index),
		desc = "Bookmarks: jump to file " .. index,
	}
	keys[#keys + 1] = {
		alt,
		select_file(index),
		desc = "Bookmarks: jump to file " .. index,
	}
end

return {
	{
		"ThePrimeagen/harpoon",
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = keys,
		config = function()
			require("harpoon").setup({
				tabline = {
					enabled = true,
					show_icons = true,
				},
			})
		end,
	},
}
