local notes = require('echoes.notes')

local M = {}

M.setup = function()
  print('setup')
  vim.api.nvim_create_user_command('OpenEchoNote', notes.open_echo_note, {})
end

M.open_echo_note = notes.open_echo_note
M.create_note_window = notes.open_echo_note

return M
