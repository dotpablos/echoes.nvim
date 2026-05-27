local M = {}

M.defaults = {
  root_note_filepath = '~/.local/share/echoes.nvim',
  auto_toggle_echo_marks = true,
  disable_opened_note_line_highlight = false,
  note_window_offsetX = 3,
  note_window_offsetY = 2,
  persist_notes_after_session = true,
  placeholder_text = '# Title: ',
}

M.options = {}

function M.merge_config(opts)
  local user_opts = {}

  if opts ~= nil then
    user_opts = opts
  end

  M.options = vim.tbl_deep_extend('force', {}, M.defaults, user_opts)
  return M.options
end

return M
