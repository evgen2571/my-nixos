local M = {}

function M.show()
  vim.lsp.buf.hover({
    border = 'rounded',
    max_width = math.max(1, math.floor(vim.o.columns * 0.85) - 2),
    max_height = math.max(1, math.floor((vim.o.lines - vim.o.cmdheight) * 0.65) - 2),
    focusable = true,
    wrap = true,
  })
end

function M.setup()
  vim.keymap.set('n', 'K', M.show, { desc = 'Documentation: hover at cursor' })
end

return M
