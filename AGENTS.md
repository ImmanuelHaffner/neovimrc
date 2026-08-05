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
│   ├── project.lua          # `.project.lua` loader (project-local config, bounded root search)
│   ├── project/
│   │   ├── databricks.lua   # Shared config for the Databricks Scala repos and worktrees
│   │   └── mcp.lua          # Project-scoped MCP servers (dynamic fff registration)
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

### Inspecting Plugin Runtime State

When verifying that a plugin's `setup(opts)` took effect — particularly after adopting new options — be aware of a common pattern that traps naive inspection.

Many plugins structure their setup like this:

```lua
-- plugin/config.lua
local M = { config = { <defaults> } }
return M

-- plugin/setup.lua  (or plugin/init.lua)
local M = {}
M.config = require('plugin.config').config            -- reference to the defaults
M.setup = function(opts)
    M.config = vim.tbl_deep_extend('force', M.config, opts or {})  -- NEW table
end
return M
```

`vim.tbl_deep_extend` returns a **new** table and reassigns `M.config` in the setup module.
The defaults module's `config` reference is now stale — it still points to the un-mutated original.
If you inspect `require('plugin.config').config` you will see only the un-modified defaults and may falsely conclude that `setup(opts)` did nothing.

Diagnostic recipe when an adopted option appears not to have taken effect:

1. List the keys of the candidate config module: `vim.tbl_keys(require('plugin.config'))`.
   If you only see `{'config'}` and the nested table matches the documented defaults exactly, you're looking at the wrong module.
2. Try the setup module instead: `require('plugin.setup').config` or `require('plugin').config` (entry point varies).
3. Last resort: grep the plugin source for `M.config = vim.tbl_deep_extend` — wherever it lives, *that* `M` is the module to require.

Hit during the lazy-upgrade campaign while verifying the dap-view adoption commit (`db9c2cc`): `require('dap-view.config').config` showed only defaults; the live config was in `require('dap-view.setup').config`.
The adoption *had* taken effect; the inspection was looking at the wrong table.

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

## MCP Servers (MCPHub)

MCP servers live in `servers.json` at the repo root — this is the **global MCPHub config**, not an LSP file.
`make install` deploys it to `~/.config/mcphub/servers.json`; never edit the deployed copy, because MCPHub UI toggles written there are lost on the next install.

The file must be **strict JSON**: mcphub.nvim parses it with `vim.json.decode`, so despite mcp-hub's own JSON5 support, comments and trailing commas break the entire config.
Document non-obvious entries here rather than inline.

mcp-hub honours these per-server keys: `command`, `args`, `env`, `cwd`, `disabled`, `url`, `headers`, `dev`, `name`.
String values expand `${VAR}` / `${env:VAR}`, `${cmd: …}`, `${workspaceFolder}` and `${userHome}`, but `disabled` is compared with a strict `=== true` and therefore cannot be driven by a placeholder.
mcphub.nvim adds two client-side keys: `autoApprove` (tools that skip confirmation) and `custom_instructions.text`, which is injected into the model's context as that server's tool-group system prompt — use it to explain what a server is for when several similar servers coexist.

### Workspace hubs (retired)

Workspace hubs are **off** — `workspace = { enabled = false }` in `lua/plugins/ai.lua`.
There is exactly one `mcp-hub` process, on the pinned port `27373`, shared by every Neovim instance; project-scoped servers come from `.project.lua` instead (see **Project-Local Configuration** below).

Why they were abandoned: a workspace hub merges the project config over the global one and therefore **re-spawns every enabled global server**, so each enrolled project carried its own duplicate `fff_universe` and `fff_runtime`.
Three universe indexes at ~3.2 GiB apiece were once live simultaneously — with `Pss` equal to `Rss`, so nothing was shared — on top of ~2.6 GiB per hub for the duplicated Databricks fleet.

Two hard-won details, kept in case markers ever return:

- The merge is a **wholesale replace per server key, not a deep merge**: mcp-hub loads each `--config` in order and assigns `mcpServers[name] = { ...projectEntry }`, so a project entry inherits nothing from the global entry of the same name.
- Validation runs over *every* server, disabled ones included, and throws `Server '<name>' must include either …` when neither `command` nor `url` is present, so a bare `{"disabled": true}` stub breaks the entire hub config. The working opt-out stub is `{"command": "true", "disabled": true}`: it passes validation, logs `Skipping disabled MCP server`, never spawns anything, and adds no tools (only `connected && !disabled` servers are registered).

Retired along with them: the `workspace.look_for` pin.
MCPHub's default `look_for` also accepts `.vscode/mcp.json` and `.cursor/mcp.json` and searches upward without ever stopping at `$HOME`, so with Databricks tooling maintaining `~/.cursor/mcp.json`, every unmarked directory under `$HOME` used to resolve to a `$HOME`-rooted hub that merged Cursor's ~17 duplicate Databricks servers over ours.
With workspaces disabled the question no longer arises.

### fff servers

fff comes in two flavours, and the invariant between them is **one fff index per repository**.

**Static and global.**
`servers.json` defines `fff_universe` and `fff_runtime`, pinned to the read-only checkouts `~/universe` and `~/runtime` so their source is searchable from any cwd.
Both wrap `fff-mcp` in a `sh -c` guard that checks the checkout exists and otherwise exits with an explanatory message, so a machine without those repos shows one failed server instead of a broken config.
Use bare `$HOME` (not `${HOME}`) in such guards so mcp-hub's placeholder pass leaves them alone.

**Project-scoped.**
One `fff-mcp` per project root, registered at runtime by `require'project.mcp'.fff{ root = ctx.root }` from that project's `.project.lua`, and shared by every Neovim instance on the hub.
Never give `~/universe` or `~/runtime` a project-scoped server: the static pair already covers them, and a second server would index the same tree twice.
The `/fffenroll` prompt (`prompts/fff-enroll.md`) automates enrolling a project.

The flags, which are easy to misread:

- `--no-warmup` skips only the *eager mmap warmup*. That warmup, run concurrently by several instances, is what once drove fff to a measured **178 GiB resident** on this machine.
- `--content-indexing` keeps the bigram content index that makes `grep` fast, which `--no-warmup` would otherwise drop. The two are a pair, not alternatives.
- `--no-update-check` suppresses fff-mcp's check for a newer release *of itself*. It has nothing to do with index freshness — that is `--no-watch`.
- `--max-cached-files` (default 30 000, also `FFF_MAX_CACHED_FILES`) governs steady state. Measured with the flags above: universe reads ~3.2 GiB right after the index build and settles near ~2.2 GiB once clean pages are reclaimed, runtime ~310 MiB; peak resident during scan and build is roughly 1.5× the settled figure, so provision for the peak rather than the plateau. Lower the cap only if RAM matters more than grep latency, since files beyond the limit stay searchable through temporary mmaps released after each grep.
- `--no-watch` is passed to the static pair only. It trades a live index for ~394k inotify watches per instance on universe; those checkouts stay on `master` and change less than daily, so a spawn-time snapshot is acceptable, and refreshing a stale index means restarting the server (`fff-mcp` exposes no rescan tool).

Project servers deliberately keep the watcher, so edits are searchable immediately; inotify headroom is ample (`fs.inotify.max_user_watches` is 8388608 here).

## Project-Local Configuration (`.project.lua`)

A directory becomes a *project* by containing `.project.lua` (the legacy `.project.vim` still works).
`lua/project.lua` loads it, and `init.lua` installs the `DirChanged` handler through `require'project'.setup()`.
The file returns a table with a `load` function:

```lua
return {
    load = function(ctx)
        -- ctx = { root, cwd, cd_mode, first, changed_window }; cd_mode is 'global' | 'tabpage' | 'window'
        require'project.mcp'.fff{ root = ctx.root }
    end,
}
```

Semantics worth knowing before editing one:

- The **chunk runs once per session**, while `load` runs on **every** directory change into the project — including bare window and tab switches — so `load` must be idempotent.
- The cache is keyed on **mtime**, so editing the file re-runs the chunk. That resets any `configured`-style upvalue guard, which is why one-time work must *also* be intrinsically idempotent: per-root augroups with `clear = true`, and upserts rather than appends (a shared `Databricks` augroup with `clear = true` used to make each project wipe the previous one's autocmds, and an appended dap configuration accumulated duplicates).
- The upward search for the root is **bounded**: it never leaves the enclosing repository and never resolves an ancestor at or above `$HOME` (`M.config.boundary_markers`, `M.config.stop_at`). The starting directory itself always counts, so `~/.project.lua` applies while sitting in `~` but never governs `~/Documents/whatever`.
- Files are read through `vim.secure.read`, which prompts once per file *version*; a declined file is skipped for the rest of the session, with a `WARN` naming it, because silence there is indistinguishable from a project that has nothing to do. Recover with `:trust` in that file, then `require'project'.reload()`.
- `DirChanged` is watched for `global`, `tabpage`, `window` and `auto`, so `:lcd` and `:tcd` count too. With `:lcd`, several projects can be active at once.
- Returning a table *without* `load` is legitimate (top-level setup, nothing to do per directory change). Returning something that is not a table is the legacy form: side effects run once per session, plus a warning.
- These files are machine-local and covered by the global gitignore; never commit one — the sole exception is this repo's own `.project.lua`, tracked deliberately as the worked example, which therefore re-prompts `vim.secure.read` after every edit.

`lua/project/mcp.lua` registers project-scoped MCP servers from those hooks.
`mcp.fff{ root = … }` upserts an `fff_<basename>_<hash>` entry through mcphub's `ConfigManager` — always with `merge = false`, because a deep merge would splice the old `args` list element-wise into the new one — and starts it once `hub:is_ready()`.
`M.config.max_active` caps how many run at once, evicting the least recently used with `disable = true` so a later hub start does not resurrect it.
Because those names are dynamic they cannot appear in CodeCompanion's `default_tools`; instead `sync_fff_tools()` in `lua/plugins/ai.lua` rewrites the `fff*` entries of that live table from the hub's connected servers whenever MCPHub fires `servers_updated`, which works because CodeCompanion reads `default_tools` when a chat is created.

`lua/project/databricks.lua` holds the shared configuration for the Databricks Scala repositories — the canonical checkouts and every worktree under `~/worktrees/**` — so each of their `.project.lua` files is a three-line stub delegating to it.
Keeping that logic in one version-controlled module rather than copied into a dozen gitignored files means a fix costs one edit instead of a dozen, and adding a worktree costs three lines.

## LSP Setup

LSP servers are configured in `lua/lsp.lua`, which uses nvim-lspconfig with custom handlers.

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
- Supports project-local configuration via `.project.lua` files in project roots (see **Project-Local Configuration**)
- Terminal integration via toggleterm with numbered terminals
- Async build support via asyncrun.vim (status shown in statusline)
