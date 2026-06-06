# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a personalized Neovim configuration written primarily in Lua. It uses **lazy.nvim** as the plugin manager and follows a modular structure for maintainability.

## Conventions

### Commit Messages

This repository uses **[Conventional Commits](https://www.conventionalcommits.org/)** for every commit.

Format: `<type>(<scope>)<!>: <subject>`, optionally followed by a body and footers.

Common types in this repo:

| Type | Use for |
|------|---------|
| `feat` | New user-facing functionality (new keymap, new plugin, new command) |
| `fix` | Bug fix in config behaviour |
| `refactor` | Restructuring without behaviour change |
| `perf` | Performance improvement |
| `chore` | Tooling, build, lockfile, Makefile, CI |
| `docs` | README, AGENTS.md, prompts, comments, help notes |
| `style` | Formatting only |
| `test` | Tests |

Common scopes: `lazy`, `lsp`, `cmp`, `telescope`, `treesitter`, `keymap`, `theme`, `dap`, `ai` (CodeCompanion), `prompts`, or a per-plugin name (`gitsigns`, `neo-tree`, …) when a change is single-plugin.

Breaking changes get either a `!` after the type/scope (e.g. `feat(lsp)!: …`) or a `BREAKING CHANGE:` footer in the body.

Always use `git commit -e -m "<draft subject>" -m "<draft body>"` so the message opens in an editor tab for the user to review and edit before saving.
This applies whether you author the message yourself or are committing on the user's behalf.

### Markdown Formatting

Write Markdown with **semantic newlines only** — never insert a line break just because a line is "too long".
Soft-wrapping is the UI's job (Neovim's `wrap`, `linebreak`, the viewer's word-wrap).
Hard line breaks in source carry meaning and reviewers read them as such; mid-paragraph wraps create noisy diffs whenever a sentence is edited.

Put a newline:

- After every heading.
- Between paragraphs.
- Around tables, code blocks, and block quotes.
- Between list items (one item per line).
- Optionally between sentences within a paragraph if they express distinct thoughts (semantic break, not formatting).

Do **not** insert a newline:

- Inside a single sentence to fit a column budget.
- Inside a list item to wrap its body.
- Inside a table cell.

This rule covers all `.md` files in this repo, including `AGENTS.md`, `README*`, `.prompts/*.md`, and any working notes.

## Project Structure

```
.
├── init.lua                 # Entry point - bootstraps lazy.nvim and loads modules
├── lua/
│   ├── config.lua           # Global Neovim options and settings
│   ├── keymap.lua           # Key mappings
│   ├── lsp.lua              # LSP configuration
│   ├── autocmd.lua          # Autocommands
│   ├── functions.lua        # Custom utility functions
│   ├── utils.lua            # Helper utilities
│   ├── theme.lua            # Theme/colorscheme settings
│   ├── neovide.lua          # Neovide GUI-specific settings
│   └── plugins/             # Plugin specifications (lazy.nvim format)
│       ├── ai.lua           # AI/CodeCompanion configuration
│       ├── lsp.lua          # LSP-related plugins
│       ├── telescope.lua    # Fuzzy finder
│       ├── treesitter.lua   # Syntax highlighting
│       └── ...              # Other plugin configs
├── ftdetect/                # Filetype detection
├── ftplugin/                # Filetype-specific settings
├── after/ftplugin/          # After-load filetype settings
├── syntax/                  # Custom syntax definitions
├── indent/                  # Custom indentation rules
```

## Key Conventions

### Plugin Configuration
- Plugins are defined in `lua/plugins/*.lua` using lazy.nvim spec format
- Each plugin file returns a table (or list of tables) with plugin specs
- Use `lazy = true` for plugins that should be lazy-loaded

### Reading Plugin Documentation
When working on plugin configurations, **always read the plugin's help documentation** to understand available options, commands, and APIs:

```lua
-- Read help for a plugin (e.g., codecompanion)
vim.cmd('help codecompanion')
local buf = vim.api.nvim_get_current_buf()
local cursor = vim.api.nvim_win_get_cursor(0)[1]
local lines = vim.api.nvim_buf_get_lines(buf, cursor - 3, cursor + 40, false)
vim.cmd('helpclose')
print(table.concat(lines, '\n'))
```

Common plugin help topics:
- `:help lazy.nvim` - Plugin manager
- `:help codecompanion` - AI assistant
- `:help telescope` - Fuzzy finder
- `:help nvim-treesitter` - Syntax highlighting
- `:help nvim-lspconfig` - LSP configuration
- `:help which-key` - Key mapping display

Use `:help <plugin>-configuration` or `:help <plugin>-setup` for setup options.

### CodeCompanion
- Configuration file: `lua/plugins/ai.lua`
- In-editor help: `:help codecompanion`
- Online documentation: https://codecompanion.olimorris.dev/

### Lua Style
- Maximum line width: 120 columns
- Use `require'module'` syntax (single quotes, no parentheses for simple requires)
- Prefer `vim.api.*` methods over legacy Vimscript where possible
- Use `which-key` plugin (`wk.add{}`) for key mappings, fall back to `vim.keymap.set()` when unavailable
- Check plugin availability with `pcall`: `local has_wk, wk = pcall(require, 'which-key')`
- Configuration modules expose a `.setup()` function

### Key Mapping Conventions
- Leader key: `<space>`
- `<space>f*` - File/find operations (Telescope)
- `<space><space>` - Window picker
- `<space>fb` - Buffer picker

## Common Commands

### Installation
```bash
make install    # Copies configuration files to ~/.config/nvim
```

The Makefile detects the OS (Linux/macOS) and runs the appropriate install target:
- Removes any existing `~/.config/nvim` directory
- Copies `init.lua`, `lua/`, `after/`, `ftdetect/`, `ftplugin/`, `indent/`, `syntax/`, `assets/`, and `prompts/` to `~/.config/nvim/`
- Installs the `nvimdiff` wrapper script to `~/.local/bin/`

### Development

> **⚠️ CRITICAL: Always edit files in this repository (the CWD), NOT in `~/.config/nvim/`.**
>
> The `~/.config/nvim/` directory is the **deployment target** — it is overwritten entirely by `make install`. Any edits made directly in `~/.config/nvim/` will be **lost** on the next install.
>
> The correct workflow is:
> 1. Edit files in this repo (e.g. `lua/plugins/ai.lua`)
> 2. Run `make install` to deploy to `~/.config/nvim/`
> 3. Restart Neovim (or `:source %` for simple changes)
>
> When using tools that accept file paths, always use **relative paths** (e.g. `lua/plugins/ai.lua`) to ensure edits land in the repo, not the deployed copy.

- Use `:Lazy` to manage plugins
- Use `:checkhealth` to diagnose issues

## LSP Setup

LSP servers are configured in `lua/lsp.lua`. Server-specific settings may be in `servers.json`. The setup uses nvim-lspconfig with custom handlers.

## Related Projects

### nvu.nvim
We own the **nvu.nvim** library, a collection of Neovim utilities used by this configuration. It is typically located at:
```
~/.local/share/nvim/lazy/nvu.nvim/
```

The library provides:
- **CodeCompanion extensions**: `neovim_context` tool and `#neovim_context` variable (in `lua/codecompanion/_extensions/`)
- **Telescope extensions**: Adaptive pickers with path shortening (in `lua/telescope/_extensions/`)
- **Core utilities**: Editor context, buffer info, path manipulation, highlighting helpers (in `lua/nvu/`)

When making changes to CodeCompanion tools/variables or Telescope utilities, check if they belong in the nvu library rather than this repository.

## Important Notes

- This config targets **Neovim 0.11+**
- Uses `night-owl.nvim` as the primary colorscheme
- Supports project-specific configuration via `.nvim.lua` files in project roots
- Terminal integration via toggleterm with numbered terminals
- Async build support via asyncrun.vim (status shown in statusline)
