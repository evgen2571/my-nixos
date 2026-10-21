local M = {}

-- Harpoon 2 has no built-in migration; never overwrite its data or the old files.
function M.import()
	local key = vim.fn.getcwd()
	local target = vim.fn.stdpath("data") .. "/harpoon/" .. vim.fn.sha256(key) .. ".json"
	local exists = vim.uv.fs_stat(target)
	local harpoon = require("harpoon")
	harpoon:setup({ settings = { sync_on_ui_close = true } })
	if exists then
		return
	end
	local projects = {}
	for _, root in ipairs({ vim.fn.stdpath("data"), vim.fn.stdpath("config") }) do
		local path = root .. "/harpoon.json"
		if vim.uv.fs_stat(path) then
			local ok, data = pcall(function()
				return vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
			end)
			if not ok or type(data) ~= "table" or type(data.projects) ~= "table" then
				vim.notify("Cannot import Harpoon marks from " .. path, vim.log.levels.WARN)
				return
			end
			projects = vim.tbl_deep_extend("force", projects, data.projects)
		end
	end
	local project = projects[key]
	if not project or not project.mark then
		return
	end
	local list = harpoon:list()
	for index, mark in ipairs(project.mark.marks or {}) do
		local file = type(mark) == "string" and mark or mark.filename
		if file and file ~= "" then
			list:replace_at(index, {
				value = file,
				context = {
					row = type(mark) == "table" and mark.row or 1,
					col = type(mark) == "table" and mark.col or 0,
				},
			})
		end
	end
	harpoon:sync()
end

function M.tabline()
	local list = require("harpoon"):list()
	local items = list.items
	local counts, labels = {}, {}
	for index = 1, list:length() do
		local item = items[index]
		if item then
			local name = vim.fn.fnamemodify(item.value, ":t")
			counts[name] = (counts[name] or 0) + 1
		end
	end
	local current = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":.")
	for i = 1, list:length() do
		local item = items[i]
		if item then
			local name = vim.fn.fnamemodify(item.value, ":t")
			local state = current == item.value and "Active" or "Inactive"
			labels[#labels + 1] = "%#HarpoonNumber"
				.. state
				.. "#   "
				.. i
				.. " %*%#Harpoon"
				.. state
				.. "#"
				.. (counts[name] == 1 and name or item.value):gsub("%%", "%%%%")
				.. "   %*"
		end
	end
	return table.concat(labels)
end

return M
