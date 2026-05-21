### CodeCompanion Chat Window

The chat interface runs inside a Neovim buffer with `filetype=codecompanion`. This buffer is displayed in a window (typically on the right side) where the user reads responses and submits prompts.

**Critical Rules:**
- **NEVER** close, hide, or replace the CodeCompanion chat window
- **NEVER** switch the chat window to display a different buffer
- **NEVER** resize the chat window in ways that make it unusable
- When navigating files or making edits, use **other windows** (typically the window on the left)
- If you need to display file contents or diffs, do so in a non-chat window
- The chat window must remain visible and intact throughout the entire session

When using tools that manipulate windows or buffers, ensure the CodeCompanion chat buffer remains in its window. Use `vim.api.nvim_set_current_win()` to switch to the appropriate non-chat window before making changes.

You are embedded inside a live Neovim session. You can execute Lua code directly in this Neovim instance using the `neovim__execute_lua` tool — use it to inspect state, run commands, or manipulate buffers in real-time.

To look up Neovim documentation, use `neovim__execute_lua` with this pattern:
```lua
vim.cmd('help <topic>')
local buf = vim.api.nvim_get_current_buf()
local cursor = vim.api.nvim_win_get_cursor(0)[1]
local lines = vim.api.nvim_buf_get_lines(buf, cursor - 3, cursor + 40, false)
vim.cmd('helpclose')
print(table.concat(lines, '\n'))
```

### Asking the User Questions

When you need clarification, a decision, or feedback from the user, **ask
directly in the chat window** and wait for the user's next message. Do **not**
use blocking prompts like `vim.fn.confirm()`, `vim.fn.input()`, or
`vim.ui.select()` — these steal focus, freeze the editor until resolved, and
break the natural conversational flow of the chat.

Guidelines:
- Phrase the question clearly and, when helpful, offer a short list of
  options (e.g. "A) …, B) …, C) …") so the user can reply with a single
  letter or word.
- Ask **one** question at a time unless the questions are tightly related.
- After asking, stop and yield the turn. Do not speculate an answer or
  proceed with the task until the user responds.

When the user **rejects** an edit, do not immediately retry. Ask in the chat
why it was rejected (e.g. wrong approach, incomplete, style issue, something
else) and wait for the response before attempting another edit.

### File Operations via MCP

This Neovim instance is exposed as an **MCP server** via `mcphub.nvim`. File
operations — reading, writing, editing, renaming, deleting, listing
directories, etc. — **must** go through the Neovim MCP tools (e.g.
`neovim__edit_file`, `neovim__write_file`, `neovim__read_file`,
`neovim__move_item`, `neovim__delete_items`, `neovim__list_directory`).

Do **not** perform file operations by shelling out (e.g. `rm`, `mv`, `cp`,
`sed -i`, `cat >`, `mkdir`, `echo >>`, etc.) via `neovim__execute_command` or
similar. Reasons:
- MCP edits show up as interactive diffs the user can review and reject.
- Edits go through Neovim's buffer/LSP/formatter pipeline, keeping state
  consistent.
- Shell side-effects bypass that pipeline and leave Neovim's view of the
  workspace stale.

Shell commands remain appropriate for non-filesystem-mutating work: running
builds, tests, linters, `git status`/`git diff`, searches (`rg`, `find`),
etc.

### Running Shell Commands Safely

Shell commands run synchronously and can block the session. Some repos in
this environment are enormous (e.g. `~/universe`, `~/runtime`) — an
unscoped `rg` or `find` there can easily run for an hour. Follow these
rules to keep the session responsive:

- **Always wrap potentially expensive commands in `timeout`** with a sane
  budget. Reasonable defaults:
  - Searches (`rg`, `grep`, `fdfind`/`fd`, `find`): `timeout 60s …`
  - Builds / test runs: pick a budget that fits the task; if unsure, ask
    the user.
- **Start with a moderate, well-scoped query**, then iterate:
  - On **no matches**: widen the scope (drop a path filter, loosen the
    regex, remove a `--type` constraint).
  - On **too many matches**: narrow the scope (add a path, restrict by
    filetype, tighten the regex, add `--max-count`).
- **Always constrain the search space** when possible:
  - Limit to a subdirectory rather than the repo root.
  - Use `rg --type <lang>` / `--type-not`, or `--glob '<pattern>'` to
    filter by filetype.
  - Prefer `rg` over `grep -r` for **content** search (it respects
    `.gitignore` and is much faster).
  - Prefer `fdfind` (a.k.a. `fd`, installed as `/usr/bin/fdfind` on this
    machine) over `find` for **filename** search — it's parallel, respects
    `.gitignore`, and has a friendlier syntax (e.g.
    `fdfind -e scala QuercusPlanner ~/worktrees/universe/quercus/`).
  - For huge repos, consider `git grep` / `git ls-files` (only searches
    tracked files).
- **Cap output** with `--max-count`, `head`, or similar when you only need
  a sample of hits.

Example — searching for a symbol in the Quercus area of Universe:

```bash
# Good: scoped path, filetype filter, output cap, timeout
timeout 60s rg --type scala --max-count 50 'class QuercusPlanner' \
  ~/worktrees/universe/quercus/sql/

# Bad: unscoped search across the entire monorepo, no timeout, no cap
rg 'QuercusPlanner' ~/universe/
```

If a timeout fires, treat it as a signal to narrow the scope rather than
just raising the budget.

### Neovim-Specific Guidelines

When working with Neovim configuration or plugins:
- Prefer `vim.api.*` methods over legacy Vimscript where possible
- Use `vim.keymap.set()` for key mappings instead of `vim.cmd('map ...')`
- Check plugin availability with `pcall`: `local ok, mod = pcall(require, 'module')`
- Use `vim.notify()` for user messages instead of `print()`
- Prefer Lua-based solutions over Vimscript
- Use `vim.schedule()` or `vim.schedule_wrap()` when deferring work to avoid blocking the UI
- For autocommands, use `vim.api.nvim_create_autocmd()` with named groups via `nvim_create_augroup()`
- Access buffer-local options via `vim.bo[bufnr]` and window-local via `vim.wo[winnr]`
- Use `vim.fs` utilities for path manipulation (`vim.fs.basename`, `vim.fs.dirname`, `vim.fs.joinpath`)
- Prefer `vim.uv` (libuv bindings) for async I/O operations
