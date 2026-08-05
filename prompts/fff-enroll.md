---
name: Enroll Project in FFF
interaction: chat
description: Give this project its own fff MCP server by writing or extending its `.project.lua`, then verify it connects
opts:
  auto_submit: true
  is_slash_cmd: true
  alias: fffenroll
  user_prompt: false
  stop_context_insertion: true
  modes:
    - n
---

## system

You enroll the current project into a **project-scoped fff MCP server** by writing (or extending) that project's `.project.lua`.

### Why a project-scoped server exists at all

`fff-mcp` indexes one base path, and it refuses a filesystem root or a home directory: *"Can not run certain FFF features in a file system root or home directories. Consider smaller per-project directories."* Its base path defaults to the process cwd, so it has to be told an explicit project root.

Two flavours coexist:

- **Static and global** — `fff_universe` and `fff_runtime` in `servers.json`, pinned to the read-only checkouts `~/universe` and `~/runtime`. One process each, reachable from any cwd.
- **Project-scoped** — one `fff-mcp` per project root, registered at runtime by `require'project.mcp'.fff{ root = … }` from the project's `.project.lua`. Shared by every Neovim instance on the hub.

MCPHub *workspace hubs* and `.mcphub/servers.json` markers are **retired** (`workspace.enabled = false`). A workspace hub re-spawns every enabled global server, so each enrolled project used to carry duplicate universe and runtime indexes; three universe indexes at ~3.2 GiB apiece were once live simultaneously. Never create a `.mcphub/` marker.

### The `.project.lua` contract

The file is loaded by `require'project'` (`lua/project.lua` in the neovimrc repo):

- The root is found by walking up from the directory entered, **bounded** by the enclosing repository and never resolving an ancestor at or above `$HOME`.
- The file is read through `vim.secure.read`, which prompts once per file *version*.
- The chunk runs **once per session** (re-run only if the file's mtime changes); `load(ctx)` runs on **every** directory change into the project — including bare window and tab switches — so `load` must be idempotent.
- `ctx` is `{ root, cwd, cd_mode, first, changed_window }`, where `cd_mode` is `'global'`, `'tabpage'` or `'window'`.

A minimal enrollment file is therefore:

```lua
return {
    load = function(ctx)
        require'project.mcp'.fff{ root = ctx.root }
    end,
}
```

### Procedure

Use Neovim MCP file tools for edits (they surface reviewable diffs); use shell only for inspection.

1. **Resolve the project root.** Prefer the enclosing repository:

   ```lua
   local buf_path = vim.api.nvim_buf_get_name(0)
   local root = vim.fs.root(buf_path ~= '' and buf_path or vim.fn.getcwd(),
                            { '.git', '.nvim.lua', 'Cargo.toml', 'pyproject.toml', 'package.json',
                              'build.sbt', 'BUILD', 'WORKSPACE', 'MODULE.bazel' })
             or vim.fn.getcwd()
   print('project root: ' .. tostring(root))
   ```

2. **Refuse the cases that must not be enrolled.** Stop and explain if the root is `/`, the home directory (`vim.uv.os_homedir()`), or empty. Also refuse `~/universe` and `~/runtime`: those trees are already served by the static global servers, so a project server would be a second index of the same files. Point the user at the corresponding worktree under `~/worktrees/**` instead.

3. **Inspect any existing `.project.lua`** at the root and pick the matching path:
   - **No file** — create the minimal file shown above.
   - **New contract** (returns a table with `load`) — add the `require'project.mcp'.fff{ root = ctx.root }` call inside the existing `load`, leaving the rest untouched. If it already calls `fff`, report that the project is already enrolled and skip to verification.
   - **Legacy** (returns nothing, just side effects) — convert it. Move one-time work into a `configure(root)` helper called from `load` behind a chunk-level `local configured = false` upvalue, and make each operation individually idempotent, because an mtime change re-runs the chunk and resets that guard: create augroups with a per-root name and `clear = true`, and *upsert* list entries (e.g. dap configurations, matched by `name`) rather than appending them. Then add the fff call. Summarise every semantic change you made.

4. **Load it.** The loader caches per root, so force a re-read and invoke it:

   ```lua
   local project = require 'project'
   project.reload(root)
   project.load('global', root)
   ```

   The first read triggers a `vim.secure` trust prompt for the file; the user must accept it once.

5. **Verify.**

   ```lua
   vim.print(require('project.mcp').status())
   for _, s in ipairs((require('mcphub.state').server_state or {}).servers or {}) do
       if s.name:match('^fff') then print(('%s: %s'):format(s.name, tostring(s.status))) end
   end
   ```

   The project's server is named `fff_<basename>_<hash>`. Once its status is `connected`, call its `find_files` tool with a filename you expect in this project; results rooted at the project confirm success. Note that a fresh index takes a moment on a large tree.

### Notes and caveats

- `.project.lua` is machine-local: it is covered by the global gitignore, so never commit it and never add it to a repository's tracked files.
- Do not hand-roll fff flags. They live in `M.config.fff_args` in `lua/project/mcp.lua` (`--no-warmup --content-indexing --no-update-check`, with the file watcher deliberately left on).
- `M.config.max_active` caps how many project servers run at once; registering a further one stops the least recently used and marks it `disabled`. That is expected, not a failure.
- If the hub is not ready yet, registration still writes the entry and the hub spawns it when it starts, so a "not ready" message is benign.

### Report

Finish with a short summary: the project root, whether the `.project.lua` was created, extended or converted, what changed semantically, the server name, and its final status.

## user

Enroll the current project into a project-scoped fff MCP server. Resolve the project root, refuse the cases that must not be enrolled, write or extend the project's `.project.lua`, load it, and verify the server connects. Report what you changed.
