-- The harness itself: modules under test come from this working tree, and the fake hub behaves.

local H = require 'tests.helpers'
local eq = MiniTest.expect.equality

local T = MiniTest.new_set{ hooks = { post_case = H.teardown } }

--- Source file of `fn`, without the leading `@`.
local function source_of(fn) return (debug.getinfo(fn, 'S').source:gsub('^@', '')) end

T['project modules load from the working tree, not the deployed copy'] = function()
    local mcp = H.fresh 'project.mcp'
    eq(source_of(mcp.fff), H.root .. '/lua/project/mcp.lua')
end

T['mcphub loads from the working copy in the lazy directory'] = function()
    local config_manager = require 'mcphub.utils.config_manager'
    local expected = vim.fn.stdpath('data') .. '/lazy/mcphub.nvim/lua/mcphub/utils/config_manager.lua'
    eq(source_of(config_manager.update_server_config), expected)
end

T['the fake hub stops a server by disabling it in the file that defines it'] = function()
    local env = H.fake_hub{ overlay = { mcpServers = { x = { command = 'true' } } } }
    local global = H.slurp(env.global)

    env.hub:stop_mcp_server('x', true)

    eq(H.read_json(env.overlay).mcpServers.x, { command = 'true', disabled = true })
    eq(env.hub.calls, { { 'stop', 'x', true } })
    eq(H.slurp(env.global), global)
end

T['teardown restores the mcphub state'] = function()
    local State = require 'mcphub.state'
    local before = State.hub_instance
    local env = H.fake_hub()
    eq(State.hub_instance, env.hub)

    H.teardown()
    eq(State.hub_instance, before)
    eq(vim.fn.isdirectory(env.dir), 0)
end

return T
