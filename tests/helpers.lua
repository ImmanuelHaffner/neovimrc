-- Shared helpers for this configuration's headless tests.

local H = {}

--- Root of the repository under test.
H.root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')

--- @param path string
--- @return string|nil
function H.slurp(path)
    local file = io.open(path, 'r')
    if not file then return nil end
    local content = file:read('*a')
    file:close()
    return content
end

--- @param path string
--- @return table|nil
function H.read_json(path)
    local content = H.slurp(path)
    return content and vim.json.decode(content) or nil
end

--- @param path string
--- @param value table
function H.write_json(path, value)
    vim.fn.writefile({ vim.json.encode(value) }, path)
end

--- `require(name)` with module-level state reset.
--- @param name string
--- @return any
function H.fresh(name)
    package.loaded[name] = nil
    return require(name)
end

--- What `fake_hub` replaced, restored by `teardown`.
local saved

--- Point mcphub at a temp global config and overlay, and install a fake hub that is ready.
---
--- The fake records every start and stop in `hub.calls` and, like `MCPHub:start_mcp_server` and
--- `stop_mcp_server`, flips `disabled` through the real ConfigManager.  Also like the real ones it never calls
--- `opts.callback`: that only happens for `via_curl_request`, which nothing here uses.
--- @param opts? { global?: table, overlay?: table, servers?: table[], is_owner?: boolean }
--- @return { dir: string, global: string, overlay: string, hub: table, state: table }
function H.fake_hub(opts)
    opts = opts or {}
    local State = require 'mcphub.state'
    local config_manager = require 'mcphub.utils.config_manager'

    local dir = vim.fn.tempname()
    vim.fn.mkdir(dir, 'p')
    local global, overlay = dir .. '/servers.json', dir .. '/project-servers.json'
    H.write_json(global, opts.global or { mcpServers = vim.empty_dict() })
    H.write_json(overlay, opts.overlay or { mcpServers = vim.empty_dict() })

    saved = saved or {
        dirs = {},
        config = State.config,
        current_hub = State.current_hub,
        config_files_cache = State.config_files_cache,
        server_state = State.server_state,
        hub_instance = State.hub_instance,
    }
    table.insert(saved.dirs, dir)

    local calls = {}
    local hub = {
        ready = true,
        is_owner = opts.is_owner ~= false,
        calls = calls,
    }
    function hub:is_ready() return self.ready end
    function hub:start_mcp_server(name, _)
        table.insert(calls, { 'start', name })
        config_manager.update_server_config(name, { disabled = false })
    end
    function hub:stop_mcp_server(name, disable, _)
        table.insert(calls, { 'stop', name, disable == true })
        config_manager.update_server_config(name, { disabled = disable == true })
    end

    -- ConfigManager reads options such as `json_decode` through `mcphub.config`, which errors until set up.
    State.config = require('mcphub.config').setup{ config = global, config_overlays = { { path = overlay } } }
    State.current_hub = { config_files = { global, overlay } }
    State.config_files_cache = {}
    State.server_state = vim.tbl_extend('force', State.server_state or {}, {
        servers = opts.servers or {},
        native_servers = {},
    })
    State.hub_instance = hub
    assert(config_manager.refresh_config())

    return { dir = dir, global = global, overlay = overlay, hub = hub, state = State }
end

--- Replace the servers the hub reports: `{ { name = …, status = …, config_source = … }, … }`.
--- @param servers table[]
function H.set_servers(servers)
    require('mcphub.state').server_state.servers = servers
end

--- Undo `fake_hub`.
function H.teardown()
    if not saved then return end
    local State = require 'mcphub.state'
    State.config = saved.config
    State.current_hub = saved.current_hub
    State.config_files_cache = saved.config_files_cache
    State.server_state = saved.server_state
    State.hub_instance = saved.hub_instance
    for _, dir in ipairs(saved.dirs) do vim.fn.delete(dir, 'rf') end
    saved = nil
end

return H
