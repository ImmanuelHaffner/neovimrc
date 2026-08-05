--- Project-local configuration.
---
--- A directory becomes a *project root* by containing `.project.lua` (preferred) or the legacy
--- `.project.vim`.  The root is resolved by walking up from the directory we changed into, but the walk is
--- **bounded**: it never leaves the enclosing repository, and it never resolves an *ancestor* at or above
--- `M.config.stop_at` (`$HOME` by default).  So a stray `~/.project.lua` still applies while you sit in
--- `~`, but it never governs `~/Documents/whatever`.  Outside a repository only the directory itself is
--- considered.  (MCPHub's `look_for` search had the opposite behaviour — it never stopped at `$HOME` — and
--- every unmarked directory below `$HOME` ended up resolving to a `$HOME`-rooted workspace.)
---
--- `.project.lua` returns a table with a `load` function:
---
--- ```lua
--- local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h')
---
--- return {
---     --- @param ctx { root: string, cwd: string, cd_mode: string, first: boolean, changed_window: boolean }
---     load = function(ctx)
---         -- `ctx.cd_mode` is 'global', 'tabpage' or 'window': which flavour of `:cd` triggered this.
---         -- Called on EVERY directory change into this project, including the first one and including
---         -- plain window/tab switches (see `ctx.changed_window`), so this MUST be idempotent: upsert
---         -- state, never append to it.
---     end,
--- }
--- ```
---
--- The file itself is compiled and executed at most **once per root per session** — top-level code runs
--- once, `load` runs per directory change.  Editing the file re-runs it (the cache is keyed on mtime), so
--- authoring a project config needs no restart.
---
--- Files are read through |vim.secure.read()|, which prompts once per file *version* and remembers the
--- answer in the trust database; an untrusted file is skipped for the rest of the session — with a warning,
--- because a project that silently does nothing is indistinguishable from one that has nothing to do.
---
--- A `.project.lua` may also return a table *without* a `load` function: a project with top-level setup but
--- nothing to do per directory change.  Returning something that is not a table at all is the **legacy**
--- form — its side effects run once per session and a warning points at the contract above.  Legacy files
--- deliberately no longer re-run on every `:cd`, which is what made appending configs (e.g.
--- `table.insert(dap.configurations…)`) accumulate duplicates.

local M = {}

local uv = vim.uv or vim.loop

--- Files that mark a project root, in order of preference.
local MARKERS = { '.project.lua', '.project.vim' }

--- Bounds for the upward search performed by `find_root`.
M.config = {
    --- Never walk out of the enclosing repository: the directory holding one of these markers is the last
    --- one considered.  Without such a directory, only the starting directory itself is considered.
    boundary_markers = { '.git' },
    --- Never resolve an *ancestor* root at or above this directory.  The starting directory itself is
    --- always considered, so a config placed here still applies when you sit in it.
}


--- @class Project.Entry
--- @field path string  absolute path of the config file that was loaded
--- @field mtime number  mtime (in seconds) of that file when it was loaded
--- @field fn? fun(ctx: table)  the `load` hook, when the file provides one
--- @field legacy boolean  true when the file has no `load` hook (side effects only)
--- @field denied boolean  true when the file was not trusted

--- Loaded project configs, keyed by project root.
--- @type table<string, Project.Entry>
local registry = {}

--- @param msg string
--- @param level? integer
local function notify(msg, level) vim.notify('project: ' .. msg, level or vim.log.levels.INFO) end

--- mtime of `path` in seconds, or nil when `path` is not a readable file.
--- @param path string
--- @return integer|nil
local function file_mtime(path)
    local stat = uv.fs_stat(path)
    if not stat or stat.type ~= 'file' then return nil end
    return stat.mtime.sec
end

--- Read `path` through |vim.secure.read()|.
--- @param path string
--- @return string|nil|false contents, nil when untrusted, false on error
local function read_trusted(path)
    local ok, contents = pcall(vim.secure.read, path)
    if not ok then
        notify(('failed to read %s: %s'):format(path, contents), vim.log.levels.ERROR)
        return false
    end
    return contents
end

--- Compile and run a `.project.lua`.
--- @param path string
--- @param mtime integer
--- @param contents string
--- @return Project.Entry|nil
local function load_lua(path, mtime, contents)
    -- The `@`-prefixed chunk name keeps `debug.getinfo(1, 'S').source` pointing at the real file, which
    -- project configs use to derive their own directory.
    local chunk, err = load(contents, '@' .. path, 't')
    if not chunk then
        notify(('failed to compile %s: %s'):format(path, err), vim.log.levels.ERROR)
        return nil
    end

    local ok, mod = pcall(chunk)
    if not ok then
        notify(('error while loading %s: %s'):format(path, mod), vim.log.levels.ERROR)
        return nil
    end

    if type(mod) == 'table' then
        -- A table without `load` is legitimate: top-level setup, nothing to do per directory change.
        return { path = path, mtime = mtime, fn = mod.load, legacy = false, denied = false }
    end

    notify(('%s uses the legacy side-effect form; its top-level code ran once for this session.\n'
        .. 'Return `{ load = function(ctx) … end }` to react to directory changes.'):format(path),
        vim.log.levels.WARN)
    return { path = path, mtime = mtime, legacy = true, denied = false }
end

--- Execute a legacy `.project.vim`.
--- @param path string
--- @param mtime integer
--- @param contents string
--- @return Project.Entry|nil
local function load_vim(path, mtime, contents)
    local ok, err = pcall(vim.api.nvim_exec2, contents, {})
    if not ok then
        notify(('error while sourcing %s: %s'):format(path, err), vim.log.levels.ERROR)
        return nil
    end

    notify(('%s is a legacy `.project.vim`; it ran once for this session.\n'
        .. 'Prefer `.project.lua` returning `{ load = function(cd_mode, ctx) … end }`.'):format(path),
        vim.log.levels.WARN)
    return { path = path, mtime = mtime, legacy = true, denied = false }
end

--- Does `dir` hold a project config?
--- @param dir string
--- @return boolean
local function has_config(dir)
    for _, marker in ipairs(MARKERS) do
        if file_mtime(dir .. '/' .. marker) then return true end
    end
    return false
end

--- Resolve the project root governing `dir`, or nil when there is none.
---
--- `dir` itself is always considered.  Ancestors are only considered while they stay inside the enclosing
--- repository and strictly below `M.config.stop_at`; see the bounding rationale at the top of this file.
--- @param dir string
--- @return string|nil
local function find_root(dir)
    dir = (vim.fs.normalize(vim.fn.fnamemodify(dir, ':p')):gsub('/$', ''))
    if has_config(dir) then return dir end

    -- No enclosing repository means no upward search at all.
    local boundary = vim.fs.root(dir, M.config.boundary_markers)
    if not boundary then return nil end

    local stop = M.config.stop_at and (vim.fs.normalize(M.config.stop_at):gsub('/$', '')) or nil
    local current = vim.fs.dirname(dir)
    while current and current ~= '' do
        -- Reached or passed the stop directory: refuse to inherit from it or anything above it.
        if stop and not vim.startswith(current, stop .. '/') then return nil end
        if has_config(current) then return current end
        if current == boundary then return nil end  -- do not leave the repository

        local parent = vim.fs.dirname(current)
        if parent == current then return nil end
        current = parent
    end
    return nil
end
--- Load (or reuse) the project config governing `cwd`, then invoke its `load` hook.
--- @param cd_mode? 'global'|'tabpage'|'window' defaults to `'global'`
--- @param cwd? string directory to resolve the root from; defaults to the current working directory
function M.load(cd_mode, cwd)
    cd_mode = cd_mode or 'global'
    cwd = cwd or vim.fn.getcwd()

    local root = find_root(cwd)
    if not root then return end

    local lua_path = root .. '/.project.lua'
    local path = file_mtime(lua_path) and lua_path or root .. '/.project.vim'
    local mtime = file_mtime(path)
    if not mtime then return end

    local entry, first = registry[root], false
    if not entry or entry.mtime ~= mtime or entry.path ~= path then
        first = true

        local contents = read_trusted(path)
        if contents == false then return end
        if contents == nil then  -- not trusted: remember, so we neither re-read nor re-prompt
            registry[root] = { path = path, mtime = mtime, legacy = false, denied = true }
            -- Say so.  The prompt is keyed on the file *version*, so every edit re-asks, and a dismissed
            -- prompt otherwise costs the project its `load` hook — no MCP servers, no options, no symptom.
            notify(('%s is not trusted, so this project is skipped for the rest of the session.\n'
                .. "Run `:trust` while editing that file, then `:lua require'project'.reload()`."):format(path),
                vim.log.levels.WARN)
            return
        end

        local loaded = (path == lua_path) and load_lua(path, mtime, contents) or load_vim(path, mtime, contents)
        if not loaded then return end
        registry[root], entry = loaded, loaded
    end

    if entry.denied or not entry.fn then return end

    local ctx = {
        root = root,
        cwd = cwd,
        cd_mode = cd_mode,
        first = first,
        changed_window = vim.v.event.changed_window or false,
    }
    local ok, err = pcall(entry.fn, ctx)
    if not ok then notify(('`load` hook of %s failed: %s'):format(entry.path, err), vim.log.levels.ERROR) end
end

--- Forget cached project configs, so they are compiled and run again on the next directory change.
--- @param root? string only forget this root; defaults to all of them
function M.reload(root)
    if root then registry[root] = nil else registry = {} end
end

--- Roots whose project config is currently loaded, for debugging.
--- @return string[]
function M.roots() return vim.tbl_keys(registry) end

--- Install the `DirChanged` handler and load the config for the current directory.
function M.setup()
    local group = vim.api.nvim_create_augroup('LoadProjectConfig', { clear = true })
    vim.api.nvim_create_autocmd('DirChanged', {
        group = group,
        -- Every flavour: `:cd`, `:tcd`, `:lcd` and 'autochdir'.  The old handler listened to `global`
        -- only, so window- and tab-local roots were never picked up.
        pattern = { 'global', 'tabpage', 'window', 'auto' },
        desc = 'Load project-local configuration on directory change',
        callback = function() M.load(vim.v.event.scope, vim.v.event.cwd) end,
    })

    M.load('global')
end

return M
