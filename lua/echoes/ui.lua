local M = {}

local config = require('echoes.config')
local store = require('echoes.store')

M.open_note = function(buf_ID)
  local opts = config.options
  local win_width = vim.api.nvim_win_get_width(0)
  local win_height = vim.api.nvim_win_get_height(0)
  local width = math.max(1, math.floor(win_width * 0.4))
  local height = math.max(1, math.floor(win_height * 0.4))
  local row = opts.note_window_offsetY
  local col = math.max(0, win_width - width) - opts.note_window_offsetX

  return vim.api.nvim_open_win(buf_ID, true, {
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

M.create_note_marker = function(buf, row)
  vim.api.nvim_buf_set_extmark(buf, store.ns, row, 0, {
    virt_text = { { ' 󰎚 echo', 'Comment' } },
    virt_text_pos = 'eol',
  })
end

M.generate_markers_for_file = function(buf, notes)
  for _, note in ipairs(notes) do
    M.create_note_marker(buf, note.row - 1)
  end
end

M.show_echo_marks = true
M.toggle_echo_marks = function()
  M.show_echo_marks = not M.show_echo_marks
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(buf, store.ns, 0, -1)
  if M.show_echo_marks then
    M.generate_markers_for_file(buf, {})
  end
end

return M
