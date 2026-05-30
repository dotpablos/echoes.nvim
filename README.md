# echoes.nvim

Project specific and markdown notes for specific lines in Neovim.

`echoes.nvim` lets you drop a note on the line you are thinking about, edit it in a small floating window, and come back later without losing the context. Its meant for notes like "why is this here?", "finish this later", and "how does this function fit into the codebase" moments that aren't worth cluttering a file with comments.

<p align="center">
  <!-- TODO: Replace this with your demo GIF. Suggested path: assets/echoes-demo.gif -->
  <strong>Demo GIF goes here</strong>
</p>

## Requirements

- Neovim 0.8+
- A font that can render the default note marker icon, nerd fonts works fine. 

## Installation

Use whatever plugin manager you like. With `lazy.nvim`:

```lua
{
  "dotpablos/echoes.nvim",
  opts = {},
}
```

Or call setup yourself:

```lua
require("echoes").setup()
```

## Usage

`echoes.nvim` does not set keymaps for you yet, so wire the commands into keys that feel natural in your config.

```lua
vim.keymap.set("n", "<leader>en", "<cmd>OpenEchoNote<cr>", { desc = "Open echo note" })
vim.keymap.set("n", "<leader>et", "<cmd>ToggleEchoMarks<cr>", { desc = "Toggle echo marks" })
vim.keymap.set("n", "<leader>ed", "<cmd>DeleteEchoOnCursor<cr>", { desc = "Delete echo note" })
vim.keymap.set("n", "<leader>ep", "<cmd>PickupEchoOnCursor<cr>", { desc = "Pick up echo note" })
vim.keymap.set("n", "<leader>eP", "<cmd>DropEchoOnCursor<cr>", { desc = "Drop echo note" })
```

### Commands

| Command | What it does |
| --- | --- |
| `:OpenEchoNote` | Opens the note for the current line, creating one if needed. |
| `:ToggleEchoMarks` | Shows or hides inline echo markers in open windows. |
| `:DeleteEchoOnCursor` | Deletes the note attached to the current line. |
| `:PickupEchoOnCursor` | Picks up the note on the current line so it can be moved. |
| `:DropEchoOnCursor` | Drops the picked-up note onto the current line. |

## Options

Pass any of these into `setup()`.

```lua
require("echoes").setup({
  root_note_filepath = "~/.local/share/echoes.nvim",
  auto_toggle_echo_marks = true,
  disable_opened_note_line_highlight = false,
  note_window_offsetX = 3,
  note_window_offsetY = 2,
  persist_notes_after_session = true,
  placeholder_text = "# Title: ",
})
```

| Option | Default | Notes |
| --- | --- | --- |
| `root_note_filepath` | `"~/.local/share/echoes.nvim"` | Where note JSON files are stored. |
| `auto_toggle_echo_marks` | `true` | Default marker visibility setting. |
| `disable_opened_note_line_highlight` | `false` | Toggles the extra highlight on the line with an open note. |
| `note_window_offsetX` | `3` | Horizontal offset for the floating note window. |
| `note_window_offsetY` | `2` | Vertical offset for the floating note window. |
| `persist_notes_after_session` | `true` | Keeps notes on disk between Neovim sessions. |
| `placeholder_text` | `"# Title: "` | First text shown when a new note opens. |

## Storage

Notes are saved as JSON outside your project. By default, they land under:

```text
~/.local/share/echoes.nvim/<project-name>/<relative-file-path>.json
```

The project root is guessed from common markers like `.git`, `package.json`, `Cargo.toml`, `go.mod`, and `pyproject.toml`. If none of those are found, `echoes.nvim` falls back to the file's directory.

## TODO

- [ ] <!-- TODO: Add feature --> Add easy file referencing to allow AI note generation
- [ ] <!-- TODO: Add feature --> Add telescope support for viewing files for different file scopes
- [ ] <!-- TODO: Add feature --> Add different resizing options for the window

## License

Idk do what ever you feel like man its your life
