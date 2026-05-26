local M = {
  note_buf_ID = 0,
  note_win_ID = 0,

  ns_id = vim.api.nvim_create_namespace('echoes'),
}

local function set_window_with_format(buf_ID)
  local offsetY = 2
  local offsetX = 3

  local win_width = vim.api.nvim_win_get_width(0)
  local win_height = vim.api.nvim_win_get_height(0)
  local width = math.max(1, math.floor(win_width * 0.4))
  local height = math.max(1, math.floor(win_height * 0.4))
  local row = offsetY
  local col = math.max(0, win_width - width) - offsetX

  M.note_win_ID = vim.api.nvim_open_win(buf_ID, true, {
    relative = 'win',
    anchor = 'NW',
    row = row,
    col = col,
    width = width,
    height = height,
    border = { '╔', '═', '╗', '║', '╝', '═', '╚', '║' },
    title = 'Note',
  })
end

M.open_echo_note = function()
  --// Make these opts
  local dbPath = '~/.local/share/echoes.nvim/notes.db'
  -- end
  if M.note_win_ID ~= 0 and vim.api.nvim_win_is_valid(M.note_win_ID) then
    vim.api.nvim_set_current_win(M.note_win_ID)
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = 'markdown'
  M.note_buf_ID = buf
  vim.api.nvim_buf_set_extmark(vim.api.nvim_get_current_buf(), M.ns_id, 0, 0, {
    end_row = 0 + 1,
    hl_group = '@comment.note',
    hl_eol = true,
  })
  set_window_with_format(buf)
end

return M
