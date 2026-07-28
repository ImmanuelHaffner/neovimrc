---
name: Enroll Project in FFF
interaction: chat
description: Drop an MCPHub workspace config so the fff MCP server runs rooted at this project, then verify it connects
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

You enroll the current project into the **fff** MCP server (fff.nvim's `fff-mcp` binary) by creating an MCPHub *workspace* config at the project root.

### Why this is needed

`fff-mcp` refuses to index a filesystem root or a home directory: it errors with *"Can not run certain FFF features in a file system root or home directories. Consider smaller per-project directories."* The server's base path defaults to its process's current working directory. Under a **global** MCPHub hub, that cwd is wherever Neovim started (often `~`), so fff fails to start.

The fix is MCPHub's **workspace** feature. When a project root contains a marker file — one of `.mcphub/servers.json`, `.vscode/mcp.json`, `.cursor/mcp.json` — MCPHub spawns an isolated *workspace hub* rooted at that project (its cwd becomes the project directory) and **merges** the project config over the global one. A per-project `fff` entry therefore starts rooted at the project and indexes successfully. `fff` has been removed from the global config on purpose, so it is *only* ever provided per-project via this enrollment.

### The marker file to write

Write `<project-root>/.mcphub/servers.json` with exactly this content (the `${CWD}` placeholder is expanded by MCPHub to the workspace hub's cwd — i.e. the project root — and passed to `fff-mcp` as its explicit base-path argument, belt-and-suspenders against any inherited cwd):

```json
{
  "mcpServers": {
    "fff": {
      "command": "fff-mcp",
      "args": ["${CWD}"],
      "autoApprove": ["find_files", "grep", "multi_grep"]
    }
  }
}
```

### Procedure

Follow these steps in order. Prefer Neovim MCP file tools for all file operations (they surface reviewable diffs); use shell only for inspection.

1. **Determine the project root.** Walk up from the active buffer's directory looking for a marker; stop at the first hit. Fall back to the window's effective cwd if none is found, and if still ambiguous, ask the user.

   ```lua
   local markers = { '.git', '.nvim.lua', 'Cargo.toml', 'pyproject.toml',
                     'package.json', 'build.sbt', 'BUILD', 'WORKSPACE', 'MODULE.bazel' }
   local buf_path = vim.api.nvim_buf_get_name(0)
   local root = vim.fs.root(buf_path, markers)
             or (buf_path ~= '' and vim.fs.dirname(buf_path))
             or vim.fn.getcwd()
   print('project root: ' .. tostring(root))
   ```

2. **Guard against root / home.** If the resolved root is `/`, the user's home directory (`vim.uv.os_homedir()`), or empty, **stop** and tell the user — enrolling one of these is exactly what fff refuses. Ask for a narrower project directory.

3. **Check for an existing marker.** If `<root>/.mcphub/servers.json` already exists, read it. If it already defines an `fff` server, report that the project is already enrolled and skip to verification (step 6). If the file exists but has *other* servers and no `fff`, **merge** the `fff` entry into its `mcpServers` rather than overwriting — preserve the user's existing servers.

4. **Write the marker.** Create `<root>/.mcphub/servers.json` (or the merged version) using the Neovim file-writing tool. Never write into a deployed/config directory; write into the actual project root.

5. **Trigger workspace detection.** MCPHub only re-detects a workspace on a `DirChanged` event, so a freshly-created marker is not picked up until the cwd changes. Rather than forcing a `:cd`, invoke the detection directly and wait for the async hub switch:

   ```lua
   local State = require('mcphub.state')
   local hub = State.hub_instance
   if hub then
     -- Show what will be resolved (workspace port should differ from the current global port)
     local ok, ctx = pcall(function() return hub:resolve_context() end)
     if ok and ctx then
       print(('resolved: workspace=%s root=%s port=%s'):format(
         tostring(ctx.is_workspace_mode), tostring(ctx.workspace_root), tostring(ctx.port)))
     end
     hub:handle_directory_change()   -- same path the DirChanged autocmd runs
   else
     print('no MCPHub hub_instance — is MCPHub running?')
   end
   ```

   The switch is asynchronous (it stops the current transport, then schedules a fresh `start()`), so give it a few seconds before verifying.

6. **Verify fff connected.** Confirm the current hub is a workspace hub rooted at the project and that `fff` reports `connected`:

   ```lua
   vim.wait(3000, function() return false end)
   local State = require('mcphub.state')
   local cur = State.current_hub
   print(('current hub: workspace=%s root=%s port=%s'):format(
     tostring(cur and cur.is_workspace_mode), tostring(cur and cur.workspace_root), tostring(cur and cur.port)))
   for _, s in ipairs((State.server_state or {}).servers or {}) do
     if s.name == 'fff' then print('fff status: ' .. tostring(s.status)) end
   end
   ```

   If `fff` is `connected`, do a tiny live check by calling the fff `find_files` tool with a filename you expect in this project (e.g. `.mcphub/servers.json` itself). Results rooted at the project — not a `FilesystemRoot` error — confirm success.

### Notes and caveats

- Everyday use does not need step 5: opening Neovim in (or `:cd`-ing into) a project that already has the marker triggers detection automatically. This prompt exists for the *first* enrollment, when the marker is created while already sitting in the project.
- MCPHub's own guidance is to use `:cd` (not a shell `cd`) so `DirChanged` fires; workspace switching also requires `reload_on_dir_changed = true` (the default).
- Enrolling any project is fine, including the read-only checkouts `~/universe` and `~/runtime`: the read-only rule covers only *committed source*, and `.mcphub/servers.json` is a local, untracked config file, not committed source. Just keep the marker untracked (e.g. via a local ignore) rather than committing it into these checkouts. Worktrees under `~/worktrees/**` are of course fine too.
- Commit the new `.mcphub/servers.json` with the project's own commit conventions if the user wants it tracked; otherwise leave it untracked.

### Report

Finish with a short summary: the project root, the path written, whether it was a fresh create or a merge, the workspace hub port, and fff's final status.

## user

Enroll the current project into the fff MCP server. Detect the project root, write the `.mcphub/servers.json` marker there (merging if one already exists), trigger MCPHub workspace detection, and verify that `fff` connects rooted at the project. Report the result.
