local function add_file()
	require("harpoon"):list():add()
end

local function open_menu()
	local harpoon = require("harpoon")
	harpoon.ui:toggle_quick_menu(harpoon:list())
end

local function select_file(index)
	return function()
		require("harpoon"):list():select(index)
	end
end

local keys = {
	{ "<leader>a", add_file, desc = "Bookmarks: add current file" },
	{ "<leader>e", open_menu, desc = "Bookmarks: show menu" },
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
		branch = "harpoon2",
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = keys,

		config = function()
			local bookmarks = require("integrations.bookmarks")
			bookmarks.import()
			vim.api.nvim_create_autocmd("DirChanged", { callback = bookmarks.import })
			vim.o.showtabline = 2
			vim.o.tabline = "%!v:lua.require'integrations.bookmarks'.tabline()"
			for _, group in ipairs({
				"HarpoonInactive",
				"HarpoonActive",
				"HarpoonNumberActive",
				"HarpoonNumberInactive",
			}) do
				vim.api.nvim_set_hl(
					0,
					group,
					{ default = true, link = group:find("Inactive") and "TabLine" or "TabLineSel" }
				)
			end
		end,
	},
}
