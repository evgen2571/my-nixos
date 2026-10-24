-- Noctalia renders this to lua/matugen.lua; edit the template, not the output.
local M = {}

function M.setup()
	require("base16-colorscheme").setup({
		-- Background tones
		base00 = "{{colors.surface.default.hex}}", -- Default Background
		base01 = "{{colors.surface_container.default.hex}}", -- Lighter Background (status bars)
		base02 = "{{colors.surface_container_high.default.hex}}", -- Selection Background
		base03 = "{{colors.outline.default.hex}}", -- Comments, Invisibles
		-- Foreground tones
		base04 = "{{colors.on_surface_variant.default.hex}}", -- Dark Foreground (status bars)
		base05 = "{{colors.on_surface.default.hex}}", -- Default Foreground
		base06 = "{{colors.on_surface.default.hex}}", -- Light Foreground
		base07 = "{{colors.on_background.default.hex}}", -- Lightest Foreground
		-- Accent colors
		base08 = "{{colors.error.default.hex}}", -- Variables, XML Tags, Errors
		base09 = "{{colors.tertiary.default.hex}}", -- Integers, Constants
		base0A = "{{colors.secondary.default.hex}}", -- Classes, Search Background
		base0B = "{{colors.primary.default.hex}}", -- Strings, Diff Inserted
		base0C = "{{colors.tertiary_fixed_dim.default.hex}}", -- Regex, Escape Chars
		base0D = "{{colors.primary_fixed_dim.default.hex}}", -- Functions, Methods
		base0E = "{{colors.secondary_fixed_dim.default.hex}}", -- Keywords, Storage
		base0F = "{{colors.error_container.default.hex}}", -- Deprecated, Embedded Tags
	})

	-- Active indent scope
	vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", {
		fg = "{{colors.primary.default.hex}}",
		nocombine = true,
	})

	-- Indent scopes that don't align with shiftwidth
	vim.api.nvim_set_hl(0, "MiniIndentscopeSymbolOff", {
		fg = "{{colors.outline.default.hex}}",
		nocombine = true,
	})

	-- Harpoon bookmarks in the tab line
	vim.api.nvim_set_hl(0, "HarpoonInactive", {
		bg = "NONE",
		fg = "{{colors.on_surface_variant.default.hex}}",
	})

	vim.api.nvim_set_hl(0, "HarpoonActive", {
		bg = "NONE",
		fg = "{{colors.on_surface.default.hex}}",
		bold = true,
	})

	vim.api.nvim_set_hl(0, "HarpoonNumberActive", {
		bg = "NONE",
		fg = "{{colors.primary.default.hex}}",
		bold = true,
	})

	vim.api.nvim_set_hl(0, "HarpoonNumberInactive", {
		bg = "NONE",
		fg = "{{colors.primary.default.hex}}",
	})

	vim.api.nvim_set_hl(0, "TabLineFill", {
		bg = "NONE",
		fg = "{{colors.on_surface.default.hex}}",
	})

	-- Keep Markdown code blocks neutral; generated error colors can be too bright.
	vim.api.nvim_set_hl(0, "RenderMarkdownCode", {
		bg = "{{colors.surface_container.default.hex}}",
	})

	vim.api.nvim_set_hl(0, "RenderMarkdownCodeInfo", {
		fg = "{{colors.primary.default.hex}}",
		bg = "{{colors.surface_container.default.hex}}",
	})

	vim.api.nvim_set_hl(0, "RenderMarkdownCodeBorder", {
		fg = "{{colors.surface_container_highest.default.hex}}",
		bg = "{{colors.surface_container.default.hex}}",
	})

	vim.api.nvim_set_hl(0, "RenderMarkdownCodeInline", {
		fg = "{{colors.on_surface.default.hex}}",
		bg = "{{colors.surface_container_high.default.hex}}",
	})
end

return M
