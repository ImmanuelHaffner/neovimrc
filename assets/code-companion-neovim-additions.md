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
