--- Shared configuration for the Databricks Scala repositories: the canonical checkouts `~/universe` and
--- `~/runtime`, plus every worktree under `~/worktrees/**`.
---
--- Each project's `.project.lua` is a stub that delegates here:
---
--- ```lua
--- return {
---     load = function(ctx) require'project.databricks'.load(ctx) end,
--- }
--- ```
---
--- The logic lives here, in a version-controlled file, rather than being copied into a dozen-plus
--- machine-local `.project.lua` files (which are covered by the global gitignore and therefore backed up
--- nowhere).  Adding a worktree then costs a three-line stub, and fixing a bug costs one edit.
---
--- `load` runs on every directory change into a project, so everything here is idempotent.

local M = {}

M.config = {
    --- Scala house style: `textwidth`, with `colorcolumn` one past it.
    textwidth = 100,
    --- Roots that must NOT get a project-scoped fff server.  The canonical checkouts are already indexed by
    --- the static, global `fff_universe` / `fff_runtime` servers, so a project server would be a second
    --- index of the same tree; code changes belong in a worktree anyway.
    canonical_checkouts = { vim.fs.normalize('~/universe'), vim.fs.normalize('~/runtime') },
    --- Attach to a running DBR runtime.  Upserted by `name`, so it exists exactly once however many
    --- projects register it and however often this runs.
    dap_config = {
        type = 'scala',
        request = 'attach',
        buildTarget = 'main',
        name = 'Attach to DBR runtime',
        hostName = 'localhost',
        port = 8771,
    },
}

--- Project roots registered this session, used by the single `FileType` autocmd below.
--- @type table<string, boolean>
local roots = {}

local autocmd_installed = false

--- Install one `FileType` autocmd for *all* Databricks roots.
---
--- Deliberately not one autocmd per project: the previous per-project configs each created an augroup named
--- `Databricks` with `clear = true`, so entering a second Databricks project silently wiped the first one's
--- autocmds — which bit the Quercus workflow, whose work spans a Universe and a Runtime worktree.
local function ensure_autocmd()
    if autocmd_installed then return end
    autocmd_installed = true

    local group = vim.api.nvim_create_augroup('DatabricksScala', { clear = true })
    vim.api.nvim_create_autocmd('FileType', {
        group = group,
        pattern = 'scala',
        desc = 'Databricks Scala house style',
        callback = function(opts)
            local file = vim.api.nvim_buf_get_name(opts.buf)
            for root in pairs(roots) do
                if vim.startswith(file, root) then
                    vim.bo[opts.buf].textwidth = M.config.textwidth
                    for _, win in ipairs(vim.fn.win_findbuf(opts.buf)) do
                        vim.wo[win].colorcolumn = tostring(M.config.textwidth + 1)
                    end
                    return
                end
            end
        end,
    })
end

--- Register the DBR attach configuration, replacing any previous entry of the same name.
---
--- Note `pcall(require, …)`: the per-project configs used to read `pcall('require', 'dap')`, which passes a
--- string where a function belongs, so the pcall always failed and this never registered.
local function ensure_dap_config()
    local has_dap, dap = pcall(require, 'dap')
    if not has_dap then return end

    local wanted = M.config.dap_config
    local configs = dap.configurations.scala or {}
    for i, config in ipairs(configs) do
        if config.name == wanted.name then
            configs[i] = wanted
            dap.configurations.scala = configs
            return
        end
    end
    table.insert(configs, wanted)
    dap.configurations.scala = configs
end

--- Configure the Databricks project rooted at `ctx.root`.
--- @param ctx { root: string, cwd: string, cd_mode: string, first: boolean, changed_window: boolean }
function M.load(ctx)
    local root = vim.fs.normalize(ctx.root)

    roots[root] = true
    ensure_autocmd()
    ensure_dap_config()

    -- A worktree gets its own fff index; the canonical checkouts are served by the global servers.
    if not vim.tbl_contains(M.config.canonical_checkouts, root) then
        require'project.mcp'.fff{ root = root }
    end
end

return M
