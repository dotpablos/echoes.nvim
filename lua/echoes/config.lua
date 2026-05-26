local M = {}

local DEFAULTS = {
  root_note_filepath = '~/.local/share/echoes.nvim',
  auto_toggle_echo_marks = true,
  disable_opened_note_line_highlight = false,
  note_window_offsetX = 3,
  note_window_offsetY = 2,
  persist_notes_after_session = true,
}

M.defaults = vim.deepcopy(DEFAULTS)
M.options = {}

function M.merge_config(opts)
  local defaults = type(M.defaults) == 'table' and M.defaults or DEFAULTS
  local user_opts = type(opts) == 'table' and opts or {}

  M.options = vim.tbl_deep_extend('force', {}, defaults, user_opts)
  return M.options
end

return M
