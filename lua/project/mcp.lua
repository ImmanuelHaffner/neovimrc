--- Project-scoped MCP servers, driven from `.project.lua`.
---
--- A project config asks for an fff server indexing its own root:
---
--- ```lua
--- local mcp = require 'project.mcp'
---
--- return {
---     load = function(ctx) mcp.fff{ root = ctx.root } end,
--- }
--- ```
---
--- `load` fires on *every* directory change into the project, so everything here is an **upsert**:
--- repeated calls with an unchanged spec touch nothing but the LRU bookkeeping.
---
--- Why process-backed rather than an in-process (native Lua) server: one `fff-mcp` per project is shared
--- by every Neovim instance on the hub and survives editor restarts, and — because `:lcd` lets two
--- projects be current at once in a single Neovim — it can serve several roots simultaneously, which
--- fff.nvim's single in-process index cannot.
---
--- Lifecycle.  Servers are written into the overlay config file `M.config.overlay` and started; the number
--- of *running* ones is capped by `M.config.max_active`, evicting the least recently used (stopped and marked
--- `disabled`).  The overlay is *ephemeral*: whichever Neovim spawns a hub disables every entry in it first,
--- so a fresh hub starts none of them, and each Neovim then re-enables the ones it asked for once the hub is
--- ready (`M.on_hub_ready()`).  What runs therefore follows where you are now, not where you were when the
--- hub last ran.  The entry itself is kept as a cheap catalogue record; `M.forget()` deletes it and
--- `M.prune()` drops entries whose root has disappeared.
---
--- The overlay is a config file of its own, which the hub reads after the global `servers.json`
--- (`config_overlays` in `lua/plugins/mcphub.lua`).  Only this module writes it.  It lives in Neovim's
--- state directory, away from the deployed `~/.config/mcphub/servers.json`: `make install` replaces that file
--- wholesale, and when project servers lived there the hub dropped every one of them on each install.

local M = {}

M.config = {
    --- The config file holding every project-scoped server, read by the hub after the global one.
    overlay = vim.fs.normalize(vim.fn.stdpath('state') .. '/mcphub/project-servers.json'),
    --- How many project-scoped servers may run at once.  Beyond this the least recently used is stopped.
    max_active = 2,
    --- Flags every project-scoped fff server gets:
    ---   * `--no-warmup` skips only the *eager mmap warmup* — the pass that once drove fff to 178 GiB
    ---     resident when several instances started at once.  Files are still mmap'd lazily on first access.
    ---   * `--content-indexing` keeps the bigram content index that makes `grep` fast, which `--no-warmup`
    ---     would otherwise drop.  The two belong together.
    ---   * `--no-update-check` suppresses fff-mcp's check for a newer release *of itself*.  It has nothing
    ---     to do with index freshness: that is `--no-watch`, which we deliberately do NOT pass, so the file
    ---     watcher stays on and edits made in this session are searchable immediately.
    fff_args = { '--no-warmup', '--content-indexing', '--no-update-check' },
    --- fff exposes read-only tools, so none of them needs confirmation.
    fff_auto_approve = { 'find_files', 'grep', 'multi_grep' },
}

--- Project-scoped servers we manage, keyed by server name.  `wanted` is this session's intent, which
--- `M.resync()` restores after a hub spawn disabled the overlay; eviction and `M.release()` clear it.
--- @type table<string, { root: string, last_used: integer, spec: table, running: boolean, wanted: boolean }>
M.state = {}

--- @param msg string
--- @param level? integer
local function notify(msg, level) vim.notify('project.mcp: ' .. msg, level or vim.log.levels.INFO) end

--- The mcphub modules, or nil while mcphub has not been set up yet.
--- @return table|nil state, table|nil config_manager
local function mcphub()
    local ok_state, state = pcall(require, 'mcphub.state')
    local ok_cm, config_manager = pcall(require, 'mcphub.utils.config_manager')
    if not (ok_state and ok_cm) or not (state.config and state.config.config) then return nil, nil end
    return state, config_manager
end

--- Server name for `root`: readable prefix plus a hash, because worktrees of different repositories
--- share basenames (`worktrees/universe/quercus` vs `worktrees/runtime/quercus`).
--- @param root string
--- @return string
local function server_name(root)
    local base = (vim.fn.fnamemodify(root, ':t'):gsub('[^%w_]', '_'))
    return ('fff_%s_%s'):format(base, vim.fn.sha256(root):sub(1, 6))
end

--- Human-readable label: the last two path components.
--- @param root string
--- @return string
local function label(root)
    return ('fff (%s/%s)'):format(vim.fn.fnamemodify(root, ':h:t'), vim.fn.fnamemodify(root, ':t'))
end

--- The desired server entry for `root`.
--- @param root string
--- @param opts table
--- @return table
local function spec_for(root, opts)
    local args = { root }
    for _, arg in ipairs(opts.args or M.config.fff_args) do table.insert(args, arg) end

    return {
        command = opts.command or 'fff-mcp',
        args = args,
        autoApprove = opts.auto_approve or M.config.fff_auto_approve,
        disabled = false,
        name = opts.label or label(root),
        custom_instructions = {
            text = opts.instructions
                or ('Project-scoped fff index of `%s`, the project you are currently working in.\n\n'):format(root)
                    .. 'Prefer it over shelling out `rg`/`find` for this tree. It is rooted at the project, so '
                    .. 'query with project-relative patterns. A file watcher keeps the index current, so edits '
                    .. 'made during this session are searchable immediately.',
        },
        --- Marks the entry as ours so `M.prune()` can recognise it across sessions.
        _project_root = root,
    }
end

--- Write `spec` for `name` into the hub's config file, replacing any previous entry wholesale.
---
--- `merge = false` matters: the default deep-merge would splice the *old* `args` list element-wise into
--- the new one, so shrinking or reordering flags would silently keep stale entries.
--- @param name string
--- @param spec table|nil nil deletes the entry
--- @return boolean success
local function write_entry(name, spec)
    local _, config_manager = mcphub()
    if not config_manager then return false end
    return config_manager.update_server_config(name, spec, { merge = false, config_source = M.config.overlay })
end

--- The entry for `name` as the overlay holds it, or nil.
--- @param name string
--- @return table|nil
local function file_entry(name)
    local _, config_manager = mcphub()
    if not config_manager then return nil end
    return ((config_manager.get_file_config(M.config.overlay) or {}).mcpServers or {})[name]
end

--- Current status of `name` as the hub sees it, or nil when the hub does not know it.
--- @param name string
--- @return string|nil
local function status_of(name)
    local state = mcphub()
    if not state then return nil end
    for _, server in ipairs((state.server_state or {}).servers or {}) do
        if server.name == name then return server.status end
    end
    return nil
end

--- Is `name` actually up?
---
--- The hub is authoritative here.  A server can come up without our own start request completing — the hub
--- picks up config-file writes through its own `--watch` — and then the cached `running` flag stays false,
--- which made `evict` blind to a live server and let `max_active` be exceeded.  Fall back to the flag only
--- while the hub has no opinion at all (not ready yet, or the entry is not in its server list).
--- @param name string
--- @return boolean
local function is_running(name)
    local status = status_of(name)
    if status then return status == 'connected' end
    return (M.state[name] or {}).running == true
end

--- Start `name` unless the hub already has it connected.
---
--- Does nothing while the hub is not ready: the entry we just wrote has `disabled = false`, so the hub
--- spawns it as part of its own start-up.  Calling the REST API before then would only log a failure.
--- @param name string
local function ensure_running(name)
    local state = mcphub()
    local hub = state and state.hub_instance
    if not hub then return end
    if not (hub.is_ready and hub:is_ready()) then return end
    if is_running(name) then
        if M.state[name] then M.state[name].running = true end
        return
    end

    hub:start_mcp_server(name, {
        callback = function(_, err)
            if err then
                notify(('failed to start %s: %s'):format(name, err), vim.log.levels.WARN)
            elseif M.state[name] then
                M.state[name].running = true
            end
        end,
    })
end

--- Stop `name` and mark it disabled, so neither the hub nor `M.resync()` brings it back.
--- @param name string
local function stop(name)
    local state = mcphub()
    local hub = state and state.hub_instance
    if M.state[name] then M.state[name].running, M.state[name].wanted = false, false end
    if not hub then return end
    hub:stop_mcp_server(name, true, {
        callback = function(_, err)
            if err then notify(('failed to stop %s: %s'):format(name, err), vim.log.levels.WARN) end
        end,
    })
end

--- Stop the least recently used servers until at most `max_active` remain running.
--- @param keep string name that must stay running
local function evict(keep)
    local running = {}
    for name, entry in pairs(M.state) do
        if is_running(name) and name ~= keep then table.insert(running, { name = name, at = entry.last_used }) end
    end
    table.sort(running, function(a, b) return a.at < b.at end)

    local budget = math.max(M.config.max_active - 1, 0)  -- `keep` occupies one slot
    for i = 1, #running - budget do
        notify(('evicting %s (least recently used, max_active = %d)'):format(running[i].name, M.config.max_active))
        stop(running[i].name)
    end
end

--- Ensure a project-scoped fff server indexes `root`, and that it is running.
---
--- Idempotent: with an unchanged spec this only refreshes the LRU timestamp and, if the hub dropped the
--- server, restarts it.
--- @param opts? { root?: string, args?: string[], auto_approve?: string[], command?: string, label?: string, instructions?: string }
--- @return string|nil name the server name, or nil when mcphub is not ready yet
function M.fff(opts)
    opts = opts or {}
    local root = vim.fs.normalize(opts.root or vim.fn.getcwd())
    local name = server_name(root)

    if not mcphub() then
        notify('mcphub is not ready; skipping ' .. name, vim.log.levels.DEBUG)
        return nil
    end

    -- Compare with the file, not with what this session last wrote: the entry can change or vanish behind
    -- our back (another Neovim, an edit in the MCPHub UI), and a cached copy would then keep us from
    -- restoring it.
    local spec = spec_for(root, opts)
    if not vim.deep_equal(file_entry(name), spec) then
        if not write_entry(name, spec) then
            notify('failed to register ' .. name, vim.log.levels.ERROR)
            return nil
        end
    end
    local known = M.state[name]
    if known then
        known.spec, known.last_used, known.wanted = spec, os.time(), true
    else
        M.state[name] = { root = root, last_used = os.time(), spec = spec, running = false, wanted = true }
    end

    ensure_running(name)
    evict(name)
    return name
end

--- Register an arbitrary project-scoped MCP server, for anything that is not fff.
--- @param name string
--- @param spec table an mcp-hub server entry (`command`/`args`/`env`, or `url`/`headers`)
--- @return boolean success
function M.server(name, spec)
    if not write_entry(name, spec) then
        notify('failed to register ' .. name, vim.log.levels.ERROR)
        return false
    end
    return true
end

--- Stop the server for `root`, keeping its catalogue entry.  Suitable for a `.project.lua` teardown.
--- @param root string
function M.release(root)
    local name = server_name(vim.fs.normalize(root))
    if M.state[name] then stop(name) end
end

--- Delete the server entry for `root` entirely.
--- @param root string
function M.forget(root)
    local name = server_name(vim.fs.normalize(root))
    stop(name)
    write_entry(name, nil)
    M.state[name] = nil
end

--- Entries of the config file `path` that this module wrote, keyed by server name.
--- @param path string
--- @return table<string, table>
local function project_entries(path)
    local _, config_manager = mcphub()
    if not config_manager then return {} end

    local file = config_manager.get_file_config(path) or {}
    local entries = {}
    for name, entry in pairs(file.mcpServers or {}) do
        if type(entry) == 'table' and entry._project_root then entries[name] = entry end
    end
    return entries
end

--- Delete entries that earlier versions of this module wrote into the global config file.  `make install`
--- would drop them eventually; until then they clutter the hub with stale servers.
--- @return string[] names
local function prune_global()
    local state, config_manager = mcphub()
    if not state or not config_manager then return {} end

    local removed = {}
    for name in pairs(project_entries(state.config.config)) do
        config_manager.update_server_config(name, nil, { config_source = state.config.config })
        table.insert(removed, name)
    end
    return removed
end

--- Drop entries whose root no longer exists.  Worktrees get deleted routinely, and the entries outlive them
--- because the overlay persists.  Leftovers in the global config file are dropped as well.
--- @return integer removed
--- @return string[] names the overlay entries that were deleted
function M.prune()
    local removed = {}
    for name, entry in pairs(project_entries(M.config.overlay)) do
        if vim.fn.isdirectory(entry._project_root) == 0 then
            write_entry(name, nil)
            M.state[name] = nil
            table.insert(removed, name)
        end
    end
    local leftovers = prune_global()
    if #removed + #leftovers > 0 then
        notify(('pruned %d stale project server(s)'):format(#removed + #leftovers))
    end
    return #removed, removed
end

--- Re-enable every server this session wants that the overlay has disabled or lost, typically because a
--- Neovim spawning the hub disabled the whole overlay first.
---
--- Reads the overlay from disk rather than mcphub's cache.  After a restart every Neovim reloads its cache and
--- reconnects, and one that reloads just before the spawning one disables the overlay would otherwise still
--- see its entries enabled and leave them off.
--- @return string[] names the entries written back
function M.resync()
    local _, config_manager = mcphub()
    if not config_manager then return {} end
    config_manager.load_config(M.config.overlay)

    local restored = {}
    for name, entry in pairs(M.state) do
        if entry.wanted then
            local current = file_entry(name)
            if (not current or current.disabled == true) and write_entry(name, entry.spec) then
                table.insert(restored, name)
            end
            ensure_running(name)
        end
    end
    return restored
end

--- `on_ready` hook for `mcphub.setup`.  The hub reports ready to every connected Neovim, including after
--- another one restarted it, so each restores its own servers.
function M.on_hub_ready() vim.schedule(M.resync) end

--- Once-per-session housekeeping: prune vanished projects.  Returns false while the hub's config is not
--- loaded yet, so the caller can retry on a later event.
--- @return boolean ran
function M.sweep()
    local state = mcphub()
    if not state or not (state.config_files_cache or {})[M.config.overlay] then return false end

    M.prune()
    return true
end

--- Project-scoped servers we manage, for debugging.
--- @return table[]
function M.status()
    local out = {}
    for name, entry in pairs(M.state) do
        table.insert(out, { name = name, root = entry.root, running = is_running(name), hub_status = status_of(name) })
    end
    return out
end

return M
