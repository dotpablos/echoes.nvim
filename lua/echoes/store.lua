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

M.ns = nil
M.per_file_notes = {}

local function project_notes(project_root)
  if M.per_file_notes[project_root] == nil then
    M.per_file_notes[project_root] = {}
  end

  return M.per_file_notes[project_root]
end

local function file_notes(filename)
  local notes = project_notes(M.find_project_root(filename))
  if notes[filename] == nil then
    notes[filename] = {}
  end

  return notes[filename]
end

local function note_index(notes, target_note)
  for index, note in ipairs(notes) do
    if note == target_note or (note.row == target_note.row and note.content == target_note.content) then
      return index
    end
  end

  return nil
end

function M.find_project_root(path)
  if path == '' then
    return vim.loop.cwd()
  end

  local start_dir = vim.fs.dirname(vim.fs.normalize(path))
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

function M.get_notes_file_path(filename)
  local project_root = vim.fs.normalize(M.find_project_root(filename))
  local normalized_filename = vim.fs.normalize(filename)
  local relative_path = normalized_filename:sub(#project_root + 2)
  local project_dir = vim.fs.joinpath(
    vim.fs.normalize(vim.fn.expand(config.options.root_note_filepath)),
    vim.fs.basename(project_root)
  )

  return vim.fs.joinpath(project_dir, relative_path .. '.json')
end

M.load_file_notes = function(filename)
  if filename == '' then
    return {}
  end

  local path = M.get_notes_file_path(filename)
  local file = io.open(path, 'r')
  local notes = {}

  if file then
    notes = json.decode(file:read('*a'))
    file:close()
  end

  project_notes(M.find_project_root(filename))[filename] = notes
  return notes
end

M.unload_file_notes = function(filename)
  if filename == '' then
    return
  end

  local path = M.get_notes_file_path(filename)
  vim.fn.mkdir(vim.fs.dirname(path), 'p')

  local file = assert(io.open(path, 'w'))
  file:write(json.encode(file_notes(filename)))
  file:close()
end

M.add_note = function(filename, note)
  table.insert(file_notes(filename), note)
end

M.get_file_notes = function(filename)
  if filename == '' then
    return {}
  end

  local notes = project_notes(M.find_project_root(filename))[filename]
  if notes == nil then
    return {}
  end

  return notes
end

M.remove_note = function(filename, note)
  local notes = file_notes(filename)
  local index = note_index(notes, note)

  if index == nil then
    return false
  end

  table.remove(notes, index)
  return true
end

M.edit_note = function(filename, old_note, new_note)
  local notes = file_notes(filename)
  local index = note_index(notes, old_note)

  if index == nil then
    return false
  end

  notes[index] = new_note
  return true
end

return M
