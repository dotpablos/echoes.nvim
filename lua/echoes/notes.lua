local M = {}

local ui = require('echoes.ui')
local config = require('echoes.config')
local store = require('echoes.store')

M.current_open_note = nil

local function refresh_file_markers(filename)
  local file_notes = store.get_file_notes(filename)

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.api.nvim_buf_get_name(buf) == filename then
      vim.api.nvim_buf_clear_namespace(buf, store.ns, 0, -1)
      if ui.show_echo_marks then
        ui.generate_markers_for_file(buf, file_notes)
      end
    end
  end
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
    ui.create_note_marker(current_buf, cursor_pos_row - 1)
    active_note = { row = cursor_pos_row, content = '', title = '' }
    store.add_note(current_file, active_note)
  end

  -- Create buffer with the content
  local note_buf = vim.api.nvim_create_buf(false, false)
  vim.bo[note_buf].buftype = 'acwrite'
  vim.bo[note_buf].bufhidden = 'wipe'
  vim.bo[note_buf].swapfile = false
  vim.bo[note_buf].filetype = 'markdown'
  vim.api.nvim_buf_set_name(
    note_buf,
    string.format('echoes://%s:%d:%d', vim.fs.basename(current_file), active_note.row, note_buf)
  )
  vim.api.nvim_create_autocmd('BufWriteCmd', {
    buffer = note_buf,
    callback = function(args)
      if M.current_open_note == nil then
        return
      end
      local buf_content = vim.api.nvim_buf_get_lines(args.buf, 0, -1, false)
      local first_line = buf_content[1]
      local content_str = table.concat(buf_content, '\n')
      -- Don't save the file if content_str is placeholder or empty
      if
        M.current_open_note.note.content_str == ''
        and (vim.trim(content_str) == '' or content_str == config.options.placeholder_text)
      then
        store.remove_note(M.current_open_note.filename, M.current_open_note.note)
        store.unload_file_notes(M.current_open_note.filename)
        refresh_file_markers(M.current_open_note.filename)
        M.current_open_note = nil
        vim.bo[args.buf].modified = false
        return
      end

      M.current_open_note.note.content_str = content_str
      M.current_open_note.note.title = first_line
      store.unload_file_notes(M.current_open_note.filename)
      refresh_file_markers(M.current_open_note.filename)
      vim.bo[args.buf].modified = false
    end,
  })

  local initial_content = active_note.content
  if initial_content == '' then
    initial_content = config.options.placeholder_text
  end

  vim.api.nvim_buf_set_lines(note_buf, 0, -1, false, { initial_content })

  -- Set to open on OG buffer
  if config.options.disable_opened_note_line_highlight then
    vim.api.nvim_buf_set_extmark(current_buf, store.ns, cursor_pos_row - 1, 0, {
      end_row = 0 + 1,
      hl_group = '@comment.note',
      hl_eol = true,
    })
  end
  local windowID = ui.open_note(note_buf)
  M.current_open_note = {
    note = active_note,
    filename = current_file,
    active_window_id = windowID,
    note_buf_id = note_buf,
  }
end

M.delete_echo_note_on_cursor = function()
  local current_buf = vim.api.nvim_get_current_buf()
  local current_file = vim.api.nvim_buf_get_name(current_buf)
  local file_notes = store.get_file_notes(current_file)
  local cursor_pos_row = vim.api.nvim_win_get_cursor(0)[1]
  local note_under_cursor = nil

  for _, note in ipairs(file_notes) do
    if note.row == cursor_pos_row then
      note_under_cursor = note
      break
    end
  end
  if note_under_cursor == nil then
    vim.notify('ECHO ERR: No note found on cursor', vim.log.levels.ERROR)
    return
  end
  store.remove_note(current_file, note_under_cursor)
  store.unload_file_notes(current_file)
  refresh_file_markers(current_file)
end

return M
