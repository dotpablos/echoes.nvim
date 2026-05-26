local notes = require('echoes.notes')
local config = require('echoes.config')
local ui = require('echoes.ui')

local M = {}

M.config = {}

M.setup = function(opts)
  print('setup')

  config.merge_config(opts)

  M.ns = vim.api.nvim_create_namespace('Echoes.nvim')
  notes.ns_id = M.ns
  local group = vim.api.nvim_create_augroup('Echoes', { clear = true })

  vim.api.nvim_create_user_command('OpenEchoNote', notes.open_echo_note, {})

  -- vim.api.nvim_create_autocmd('BufEnter', {
  --   callback = function(args)
  --     local file = vim.api.nvim_buf_get_name(args.buf)
  --     vim.api.nvim_buf_clear_namespace(args.buf, M.ns, 0, -1)
  --     for _, echo in ipairs(notes.session_notes) do
  --       if echo.name == file then
  --         ui.create_note_marker(args.buf, M.ns, echo.row)
  --       end
  --     end
  --   end,
  -- })
  --
  -- vim.api.nvim_create_autocmd('BufWritePost', {
  --   callback = function(args)
  --     local file = vim.api.nvim_buf_get_name(args.buf)
  --     if string.match(file, 'echoes/') then
  --       notes.save_note(file)
  --     end
  --   end,
  -- })
  --
end

M.create_note = notes.create_note_on_cursor
M.create_note_window = notes.create_note_on_cursor

return M
