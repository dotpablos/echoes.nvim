local M = {}

local ui = require('echoes.ui')
local config = require('echoes.config')
local store = require('echoes.store')

M.current_open_note = nil

local function save_open_note(buf)
  if M.current_open_note == nil then
    return
  end

  local content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n')
  M.current_open_note.content = content
  store.unload_file_notes(M.current_open_note.filename)
  vim.bo[buf].modified = false
end

local function configure_note_buffer(buf, note)
  vim.bo[buf].buftype = 'acwrite'
  vim.bo[buf].bufhidden = 'hide'
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = 'markdown'
  vim.api.nvim_buf_set_name(buf, string.format('echoes://%s:%d:%d', vim.fs.basename(note.filename), note.row, buf))

  vim.api.nvim_create_autocmd('BufWriteCmd', {
    buffer = buf,
    callback = function(args)
      save_open_note(args.buf)
    end,
  })
end

local function merge(dst, ...)
  for _, src in ipairs({ ... }) do
    for k, v in pairs(src) do
      dst[k] = v
    end
  end
  return dst
end

local create_note_on_cursor = function(current_buf)
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local project_path = vim.api.nvim_buf_get_name(0)

  ui.create_note_marker(current_buf, M.ns_id, cursor_pos[1] - 1)

  local new_note = { row = cursor_pos[1], filename = project_path, content = '' }
  store.add_note(new_note)
  return new_note
end

M.open_echo_note = function()
  -- Forbid recurvsively opening notes within notes
  local current_buf = vim.api.nvim_get_current_buf()
  local current_win = vim.api.nvim_get_current_win()
  if
    M.current_open_note ~= nil
    and M.current_open_note.active_window_id == current_win
    and vim.api.nvim_win_is_valid(current_win)
  then
    vim.notify(
      'ECHO ERR: Trying to open a note within a note, did you mean to do this?',
      vim.log.levels.ERROR
    )
    return
  end

  local current_file = vim.api.nvim_buf_get_name(current_buf)
  local file_notes = store.get_file_notes(current_file)

  -- See if a note already exists on cursor
  local cursor_pos_row = vim.api.nvim_win_get_cursor(0)[1]
  local active_note = nil
  for _, note in ipairs(file_notes) do
    if note.row == cursor_pos_row then
      active_note = note
      break
    end
  end
  if active_note == nil then
    active_note = create_note_on_cursor(current_buf)
  end

  -- Create buffer with the content
  local note_buf = vim.api.nvim_create_buf(false, false)
  configure_note_buffer(note_buf, active_note)
  vim.api.nvim_buf_set_lines(note_buf, 0, -1, false, { active_note.content })

  -- Set to open on OG buffer
  if config.options.disable_opened_note_line_highlight then
    vim.api.nvim_buf_set_extmark(current_buf, M.ns_id, cursor_pos_row - 1, 0, {
      end_row = 0 + 1,
      hl_group = '@comment.note',
      hl_eol = true,
    })
  end
  local windowID = ui.open_note(note_buf)
  M.current_open_note = merge(active_note, { active_window_id = windowID, note_buf_id = note_buf })
end
return M
