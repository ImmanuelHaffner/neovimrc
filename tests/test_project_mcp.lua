-- `project.mcp` against the real mcphub ConfigManager and a fake hub.

local H = require 'tests.helpers'
local eq = MiniTest.expect.equality

local env, mcp

--- A fresh `project.mcp` writing to `env.overlay`.
--- @param opts? table passed to `H.fake_hub`
local function setup(opts)
    env = H.fake_hub(opts)
    mcp = H.fresh 'project.mcp'
    mcp.config.overlay = env.overlay
end

--- An existing project directory under the temp dir.
--- @param rel string
--- @return string
local function project(rel)
    local dir = env.dir .. '/' .. rel
    vim.fn.mkdir(dir, 'p')
    return dir
end

--- Report `names` as connected servers read from the overlay.
--- @param names string[]
local function connected(names)
    H.set_servers(vim.tbl_map(function(name)
        return { name = name, status = 'connected', config_source = env.overlay }
    end, names))
end

--- Reload the hub's view of the config files after editing them on disk.
local function reload() assert(require('mcphub.utils.config_manager').refresh_config()) end

local T = MiniTest.new_set{ hooks = { post_case = H.teardown } }

T['overlay'] = MiniTest.new_set{ hooks = { pre_case = function() setup() end } }

T['overlay']['fff writes its entry to the overlay only'] = function()
    local global = H.slurp(env.global)
    local root = project('proj')

    local name = mcp.fff{ root = root }

    local entry = H.read_json(env.overlay).mcpServers[name]
    eq(entry._project_root, root)
    eq(entry.disabled, false)
    eq(entry.args[1], root)
    eq(H.slurp(env.global), global)
end

T['overlay']['an entry that vanished from the overlay is written again'] = function()
    local root = project('proj')
    local name = mcp.fff{ root = root }
    H.write_json(env.overlay, { mcpServers = vim.empty_dict() })
    reload()

    eq(mcp.fff{ root = root }, name)
    eq(H.read_json(env.overlay).mcpServers[name]._project_root, root)
end

T['overlay']['an unchanged entry is not written again'] = function()
    local root = project('proj')
    local name = mcp.fff{ root = root }
    connected{ name }
    -- Same data, different formatting: any rewrite would pretty-print it.
    local compact = vim.json.encode(H.read_json(env.overlay))
    vim.fn.writefile({ compact }, env.overlay)
    reload()
    local calls = #env.hub.calls

    mcp.fff{ root = root }

    eq(H.slurp(env.overlay), compact .. '\n')
    eq(#env.hub.calls, calls)
end

T['overlay']['eviction disables the least recently used server in the overlay'] = function()
    mcp.config.max_active = 1
    local global = H.slurp(env.global)
    local first = mcp.fff{ root = project('a') }
    connected{ first }

    local second = mcp.fff{ root = project('b') }

    local servers = H.read_json(env.overlay).mcpServers
    eq(servers[first].disabled, true)
    eq(servers[second].disabled, false)
    eq(vim.tbl_contains(env.hub.calls, function(call)
        return vim.deep_equal(call, { 'stop', first, true })
    end, { predicate = true }), true)
    eq(H.slurp(env.global), global)
end

T['resync'] = MiniTest.new_set{ hooks = { pre_case = function() setup() end } }

--- Rewrite the overlay on disk with `edit` applied to its servers, leaving mcphub's cache stale.
--- @param edit fun(servers: table)
local function edit_overlay(edit)
    local file = H.read_json(env.overlay)
    edit(file.mcpServers)
    H.write_json(env.overlay, file)
end

T['resync']['re-enables a wanted entry the spawning hub disabled'] = function()
    local name = mcp.fff{ root = project('proj') }
    -- Behind the cache's back, as a Neovim spawning the hub would.
    edit_overlay(function(servers) servers[name].disabled = true end)

    eq(mcp.resync(), { name })
    eq(H.read_json(env.overlay).mcpServers[name].disabled, false)
end

T['resync']['leaves an evicted entry disabled'] = function()
    mcp.config.max_active = 1
    local first = mcp.fff{ root = project('a') }
    connected{ first }
    local second = mcp.fff{ root = project('b') }

    eq(mcp.resync(), {})
    local servers = H.read_json(env.overlay).mcpServers
    eq(servers[first].disabled, true)
    eq(servers[second].disabled, false)
end

T['resync']['restores a wanted entry deleted from the overlay'] = function()
    local root = project('proj')
    local name = mcp.fff{ root = root }
    edit_overlay(function(servers) servers[name] = nil end)

    eq(mcp.resync(), { name })
    eq(H.read_json(env.overlay).mcpServers[name]._project_root, root)
end

T['resync']['ignores entries this session never asked for'] = function()
    edit_overlay(function(servers)
        servers.fff_foreign = { command = 'fff-mcp', disabled = true, _project_root = env.dir }
    end)

    eq(mcp.resync(), {})
    eq(H.read_json(env.overlay).mcpServers.fff_foreign.disabled, true)
    eq(env.hub.calls, {})
end

T['observe'] = MiniTest.new_set{ hooks = { pre_case = function()
    setup{ overlay = { mcpServers = {
        fff_foreign = { command = 'fff-mcp', disabled = false, _project_root = '/elsewhere/foreign' },
    } } }
end } }

--- Did the fake hub get asked to stop `name`?
--- @param name string
--- @return boolean
local function stopped(name)
    return vim.tbl_contains(env.hub.calls, function(call)
        return call[1] == 'stop' and call[2] == name
    end, { predicate = true })
end

T['observe']['adopts a connected server another session started'] = function()
    connected{ 'fff_foreign' }

    eq(mcp.observe(), { 'fff_foreign' })
    eq(mcp.state.fff_foreign.root, '/elsewhere/foreign')
    eq(mcp.state.fff_foreign.wanted, false)
end

T['observe']['adopted servers are evictable'] = function()
    mcp.config.max_active = 1
    connected{ 'fff_foreign' }
    mcp.observe()

    mcp.fff{ root = project('mine') }

    eq(stopped('fff_foreign'), true)
    eq(H.read_json(env.overlay).mcpServers.fff_foreign.disabled, true)
end

T['observe']['our own stale server goes first'] = function()
    mcp.config.max_active = 2
    local own = mcp.fff{ root = project('old') }
    mcp.state[own].last_used = os.time() - 3600
    connected{ own, 'fff_foreign' }
    mcp.observe()

    mcp.fff{ root = project('new') }

    eq(stopped(own), true)
    eq(stopped('fff_foreign'), false)
end

T['observe']['ignores global and disconnected servers'] = function()
    H.write_json(env.global, { mcpServers = {
        fff_global = { command = 'fff-mcp', _project_root = '/elsewhere/global' },
    } })
    reload()
    H.set_servers{
        { name = 'fff_global', status = 'connected', config_source = env.global },
        { name = 'fff_foreign', status = 'disconnected', config_source = env.overlay },
    }

    eq(mcp.observe(), {})
    eq(mcp.state, {})
end

T['observe']['is idempotent'] = function()
    connected{ 'fff_foreign' }
    mcp.observe()
    local before = vim.deepcopy(mcp.state)

    eq(mcp.observe(), {})
    eq(mcp.state, before)
end

T['observe']['an adopted server the hub dropped stops counting'] = function()
    mcp.config.max_active = 1
    connected{ 'fff_foreign' }
    mcp.observe()
    H.set_servers{}

    mcp.fff{ root = project('mine') }

    eq(stopped('fff_foreign'), false)
end

T['prune'] = MiniTest.new_set()

T['prune']['drops overlay entries whose root is gone'] = function()
    setup()
    H.write_json(env.overlay, { mcpServers = {
        gone = { command = 'fff-mcp', _project_root = env.dir .. '/gone' },
        here = { command = 'fff-mcp', _project_root = env.dir },
    } })
    reload()

    local count, names = mcp.prune()

    eq({ count, names }, { 1, { 'gone' } })
    eq(vim.tbl_keys(H.read_json(env.overlay).mcpServers), { 'here' })
end

T['prune']['drops project entries left in the global config'] = function()
    setup{ global = { mcpServers = {
        keep = { command = 'true' },
        fff_old_123456 = { command = 'fff-mcp', _project_root = '/somewhere' },
    } } }

    mcp.prune()

    eq(H.read_json(env.global).mcpServers, { keep = { command = 'true' } })
end

T['prune']['sweep runs once the overlay is loaded'] = function()
    setup()
    eq(mcp.sweep(), true)
    require('mcphub.state').config_files_cache = {}
    eq(mcp.sweep(), false)
end

return T
