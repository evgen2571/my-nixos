local M = {}

local api = vim.api
local util = vim.lsp.util

M.preview_options = {
  border = "rounded",
  max_width = 60,
  max_height = 12,
  focusable = true,
  focus_id = "textDocument/hover",
}

-- Remove decorative Markdown rules and excessive whitespace from LSP hovers.
-- Keep fenced code and links intact; only compact the hover display.
function M.compact(lines)
  local out = {}
  local fenced = false
  local blank = false

  for _, line in ipairs(lines) do
    if line:match("^%s*```") then
      if blank and #out > 0 then
        out[#out + 1] = ""
      end
      blank = false
      fenced = not fenced
      out[#out + 1] = line
    elseif not fenced and line:match("^%s*%-%-%-+%s*$") then
      blank = false
      while out[#out] == "" do
        out[#out] = nil
      end
    elseif not fenced and line:match("^%s*$") then
      blank = true
    else
      if blank and #out > 0 then
        out[#out + 1] = ""
      end
      blank = false
      out[#out + 1] = line
    end
  end

  return out
end

function M.show()
  local bufnr = api.nvim_get_current_buf()
  local winid = api.nvim_get_current_win()
  local cursor = api.nvim_win_get_cursor(winid)

  if #vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/hover" }) == 0 then
    vim.notify("No documentation server attached; check :LspInfo", vim.log.levels.INFO)
    return
  end

  vim.lsp.buf_request_all(bufnr, "textDocument/hover", function(client)
    return util.make_position_params(winid, client.offset_encoding)
  end, function(responses)
    if not api.nvim_win_is_valid(winid)
      or api.nvim_get_current_win() ~= winid
      or api.nvim_get_current_buf() ~= bufnr
      or not vim.deep_equal(api.nvim_win_get_cursor(winid), cursor)
    then
      return
    end

    local chunks = {}
    for id, response in pairs(responses) do
      if not response.err and response.result and response.result.contents then
        local content = response.result.contents
        local plain = type(content) == "table" and content.kind == "plaintext"
        local lines = plain and vim.split(content.value or "", "\n", { trimempty = true })
          or M.compact(util.convert_input_to_markdown_lines(content))

        if #lines > 0 then
          chunks[#chunks + 1] = { id = id, lines = lines, plain = plain }
        end
      end
    end

    if #chunks == 0 then
      vim.notify("No information available", vim.log.levels.INFO)
      return
    end

    table.sort(chunks, function(a, b)
      return a.id < b.id
    end)
    local markdown = #chunks > 1 or not chunks[1].plain
    local lines = {}
    for _, chunk in ipairs(chunks) do
      if #lines > 0 then
        lines[#lines + 1] = ""
      end
      if #chunks > 1 then
        local client = vim.lsp.get_client_by_id(chunk.id)
        lines[#lines + 1] = "**" .. (client and client.name or "LSP") .. "**"
      end
      if #chunks > 1 and chunk.plain then
        lines[#lines + 1] = "```text"
      end
      vim.list_extend(lines, chunk.lines)
      if #chunks > 1 and chunk.plain then
        lines[#lines + 1] = "```"
      end
    end

    util.open_floating_preview(lines, markdown and "markdown" or "plaintext", M.preview_options)
  end)
end

function M.setup()
  vim.keymap.set("n", "K", M.show, { desc = "Documentation: hover at cursor" })
end

return M
