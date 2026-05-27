local M = {}

local json = require('echoes.json')
local config = require('echoes.config')

local project_root_markers = {
  '.git',
  'package.json',
  'Cargo.toml',
  'go.mod',
  'pyproject.toml',
}

M.per_file_notes = {}

local function strip_filename(path)
  return vim.fs.basename(path)
end

local function serialize_note(note)
  return {
    row = note.row,
    filename = strip_filename(note.filename),
    content = note.content,
  }
end

local function hydrate_note(filename, note)
  return {
    row = note.row,
    filename = filename,
    content = note.content,
  }
end

local function get_storage_root()
  local root = config.options.root_note_filepath or '~/.local/share/echoes.nvim'
  return vim.fs.normalize(vim.fn.expand(root))
end

local function get_project_dir(project_root)
  return vim.fs.joinpath(get_storage_root(), strip_filename(project_root))
end

local function get_notes_file_path(filename)
  local project_root = M.find_project_root(filename)
  local project_dir = get_project_dir(project_root)
  local file_name = strip_filename(filename) .. '.json'
  return project_dir, vim.fs.joinpath(project_dir, file_name)
end

local function ensure_project_notes(project_root)
  if M.per_file_notes[project_root] == nil then
    M.per_file_notes[project_root] = {}
  end

  return M.per_file_notes[project_root]
end

local function ensure_file_notes(filename)
  local project_root = M.find_project_root(filename)
  local project_notes = ensure_project_notes(project_root)

  if project_notes[filename] == nil then
    project_notes[filename] = {}
  end

  return project_notes[filename]
end

local function notes_match(left, right)
  if left == right then
    return true
  end

  if left == nil or right == nil then
    return false
  end

  return left.row == right.row and left.filename == right.filename and left.content == right.content
end

local function find_note_index(file_notes, target_note)
  for index, note in ipairs(file_notes) do
    if notes_match(note, target_note) then
      return index
    end
  end

  return nil
end

function M.find_project_root(path)
  local target_path = path or vim.api.nvim_buf_get_name(0)
  if target_path == '' then
    return vim.loop.cwd()
  end

  local start_dir = vim.fs.dirname(vim.fs.normalize(target_path))
  local root_marker = vim.fs.find(project_root_markers, {
    path = start_dir,
    upward = true,
    stop = vim.loop.os_homedir(),
  })[1]

  if root_marker then
    return vim.fs.dirname(root_marker)
  end

  return start_dir
end

M.load_file_notes = function(filename)
  local target_filename = filename or vim.api.nvim_buf_get_name(0)
  if target_filename == '' then
    return {}
  end

  local project_root = M.find_project_root(target_filename)
  local _, file_path = get_notes_file_path(target_filename)
  local file = io.open(file_path, 'r')
  local decoded_notes = {}

  if file then
    local content = file:read('*a')
    file:close()
    decoded_notes = json.decode(content)
  end

  local hydrated_notes = {}
  for _, note in ipairs(decoded_notes or {}) do
    table.insert(hydrated_notes, hydrate_note(target_filename, note))
  end

  local project_notes = ensure_project_notes(project_root)
  project_notes[target_filename] = hydrated_notes

  return hydrated_notes
end

M.unload_file_notes = function(filename)
  local target_filename = filename or vim.api.nvim_buf_get_name(0)
  if target_filename == '' then
    return
  end

  local project_root = M.find_project_root(target_filename)
  local project_notes = ensure_project_notes(project_root)
  local file_notes = {}

  for _, note in ipairs(project_notes[target_filename] or {}) do
    table.insert(file_notes, serialize_note(note))
  end

  local project_dir, file_path = get_notes_file_path(target_filename)
  vim.fn.mkdir(project_dir, 'p')

  local file = assert(io.open(file_path, 'w'))
  file:write(json.encode(file_notes))
  file:close()
end

M.add_note = function(filename, note)
  local note_to_add = note or filename
  local source_filename = note and filename or note_to_add.filename
  local project_root = M.find_project_root(source_filename)
  local project_notes = ensure_project_notes(project_root)

  if project_notes[source_filename] == nil then
    project_notes[source_filename] = {}
  end

  table.insert(project_notes[source_filename], note_to_add)
end

M.get_file_notes = function(filename)
  local target_filename = filename or vim.api.nvim_buf_get_name(0)
  if target_filename == '' then
    return {}
  end

  local project_root = M.find_project_root(target_filename)
  local project_notes = ensure_project_notes(project_root)

  return project_notes[target_filename] or {}
end

M.remove_note = function(filename, note)
  local target_filename = note and filename or filename.filename
  if target_filename == nil or target_filename == '' then
    return false
  end

  local file_notes = ensure_file_notes(target_filename)
  local note_index = find_note_index(file_notes, note)

  if note_index == nil then
    return false
  end

  table.remove(file_notes, note_index)
  return true
end

M.edit_note = function(filename, old_note, new_note)
  local target_filename = new_note and filename or filename.filename
  if target_filename == nil or target_filename == '' then
    return false
  end

  local file_notes = ensure_file_notes(target_filename)
  local note_index = find_note_index(file_notes, old_note)

  if note_index == nil then
    return false
  end

  file_notes[note_index] = new_note
  return true
end

return M
