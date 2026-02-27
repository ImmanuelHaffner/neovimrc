# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a personalized Neovim configuration written primarily in Lua. It uses **lazy.nvim** as the plugin manager and follows a modular structure for maintainability.

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
└── lua/codecompanion/       # CodeCompanion custom tools/variables
```

## Key Conventions

### Plugin Configuration
- Plugins are defined in `lua/plugins/*.lua` using lazy.nvim spec format
- Each plugin file returns a table (or list of tables) with plugin specs
- Use `lazy = true` for plugins that should be lazy-loaded

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
- After making changes, run `make install` to deploy updates to `~/.config/nvim`
- Alternatively, edit files directly in `~/.config/nvim` for quick iteration, then copy changes back
- Changes to Lua files take effect after restarting Neovim or using `:source %`
- Use `:Lazy` to manage plugins
- Use `:checkhealth` to diagnose issues

## LSP Setup

LSP servers are configured in `lua/lsp.lua`. Server-specific settings may be in `servers.json`. The setup uses nvim-lspconfig with custom handlers.

## Important Notes

- This config targets **Neovim 0.11+**
- Uses `night-owl.nvim` as the primary colorscheme
- Supports project-specific configuration via `.nvim.lua` files in project roots
- Terminal integration via toggleterm with numbered terminals
- Async build support via asyncrun.vim (status shown in statusline)
