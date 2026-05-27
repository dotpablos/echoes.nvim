local notes = require('echoes.notes')
local config = require('echoes.config')
local ui = require('echoes.ui')
local store = require('echoes.store')

local M = {}

M.config = {}

M.setup = function(opts)
  config.merge_config(opts)

  store.ns = vim.api.nvim_create_namespace('Echoes.nvim')
  local group = vim.api.nvim_create_augroup('Echoes', { clear = true })

  vim.api.nvim_create_user_command('OpenEchoNote', notes.open_echo_note, {})

  vim.api.nvim_create_user_command('ToggleEchoMarks', ui.toggle_echo_marks, {})

  vim.api.nvim_create_autocmd('BufEnter', {
    group = group,
    callback = function(args)
      local file = vim.api.nvim_buf_get_name(args.buf)
      if file == '' then
        return
      end

      local file_notes = store.load_file_notes(file)
      vim.api.nvim_buf_clear_namespace(args.buf, store.ns, 0, -1)

      if ui.show_echo_marks then
        ui.generate_markers_for_file(args.buf, file_notes)
      end
    end,
  })

  vim.api.nvim_create_autocmd('BufWritePost', {
    group = group,
    callback = function(args)
      local file = vim.api.nvim_buf_get_name(args.buf)
      if file ~= '' then
        store.unload_file_notes(file)
      end
    end,
  })

  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = group,
    callback = function()
      for _, project_notes in pairs(store.per_file_notes) do
        for file in pairs(project_notes) do
          store.unload_file_notes(file)
        end
      end
    end,
  })
end

M.create_note = notes.create_note_on_cursor
M.create_note_window = notes.create_note_on_cursor

return M
