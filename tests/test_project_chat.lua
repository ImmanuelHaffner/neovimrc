-- `project.chat`: which project servers a chat gets, against a fake hub and fake chats.

local H = require 'tests.helpers'
local eq = MiniTest.expect.equality

local env, mcp, chat_mod
local windows = {}

local function setup()
    env = H.fake_hub()
    mcp = H.fresh 'project.mcp'
    mcp.config.overlay = env.overlay
    chat_mod = H.fresh 'project.chat'
end

local function teardown()
    for _, win in ipairs(windows) do
        if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    end
    windows = {}
    H.teardown()
end

--- A project directory with a `.project.lua`, under the temp dir.
--- @param rel string
--- @return string
local function project(rel)
    local dir = env.dir .. '/' .. rel
    vim.fn.mkdir(dir, 'p')
    vim.fn.writefile({ 'return {}' }, dir .. '/.project.lua')
    return dir
end

--- A split whose window-local cwd is `dir`, showing a scratch buffer of `filetype`.
--- @param dir string
--- @param filetype? string
--- @return integer win
local function window_in(dir, filetype)
    local buf = vim.api.nvim_create_buf(false, true)
    if filetype then vim.bo[buf].filetype = filetype end
    local win = vim.api.nvim_open_win(buf, false, { split = 'below' })
    vim.api.nvim_win_call(win, function() vim.cmd.lcd(dir) end)
    table.insert(windows, win)
    return win
end

--- A fake chat opened from `win`, whose registry records every add and accepts it unless `reject` says so.
--- @param win integer
--- @param opts? { path?: string, reject?: table<string, true> }
--- @return table chat
local function fake_chat(win, opts)
    opts = opts or {}
    local registry = { added = {}, reject = opts.reject or {} }
    function registry:add(name)
        table.insert(self.added, name)
        if self.reject[name] then return nil end
        return self
    end
    return {
        bufnr = vim.api.nvim_create_buf(false, true),
        buffer_context = { winnr = win, path = opts.path or '' },
        tool_registry = registry,
    }
end

--- Report `name` as an overlay server with `status`.
local function report(name, status)
    H.set_servers{ { name = name, status = status, config_source = env.overlay } }
end

--- Report every name in `names` as a connected overlay server.
--- @param names string[]
local function connected(names)
    H.set_servers(vim.tbl_map(function(name)
        return { name = name, status = 'connected', config_source = env.overlay }
    end, names))
end

--- Put an entry for `root` into the overlay as another Neovim would, without this session asking for it.
--- @param name string
--- @param root string
local function foreign_entry(name, root)
    local file = H.read_json(env.overlay)
    file.mcpServers[name] = { command = 'fff-mcp', args = { root }, disabled = false, _project_root = root }
    H.write_json(env.overlay, file)
    assert(require('mcphub.utils.config_manager').refresh_config())
end

local T = MiniTest.new_set{ hooks = { pre_case = setup, post_case = teardown } }

T['global tool names exclude project servers'] = function()
    local names = chat_mod.global_tool_names{
        servers = {
            { name = 'fff_universe', status = 'connected', config_source = env.global },
            { name = 'fff_dotfiles_neovimrc', status = 'connected', config_source = env.overlay },
            { name = 'fff_runtime', status = 'disconnected', config_source = env.global },
            { name = 'github', status = 'connected', config_source = env.global },
        },
        native_servers = { { name = 'mcphub', status = 'connected' }, { name = 'neovim', status = 'connected' } },
    }
    eq(names, { 'fff_universe', 'mcphub' })
end

T['the own project server is attached'] = function()
    local root = project('universe/quercus')
    local name = mcp.fff{ root = root }
    report(name, 'connected')
    local chat = fake_chat(window_in(root))

    eq(chat_mod.attach(chat), { name })
    eq(chat.tool_registry.added, { name })
end

T['a directory outside every project gets none'] = function()
    report(mcp.fff{ root = project('proj') }, 'connected')
    local chat = fake_chat(window_in(env.dir))

    eq(chat_mod.attach(chat), {})
    eq(chat.tool_registry.added, {})
end

T['a server that connects later is attached then'] = function()
    local root = project('proj')
    local name = mcp.fff{ root = root }
    report(name, 'connecting')
    local chat = fake_chat(window_in(root))

    eq(chat_mod.attach(chat), {})
    report(name, 'connected')
    eq(chat_mod.attach(chat), { name })
end

T['attaching is idempotent and respects removal'] = function()
    local root = project('proj')
    local name = mcp.fff{ root = root }
    report(name, 'connected')
    local chat = fake_chat(window_in(root))
    chat_mod.attach(chat)
    chat_mod.attach(chat)

    -- The user removed the tool group from the chat.
    chat.tool_registry.added = {}
    eq(chat_mod.attach(chat), {})
    eq(chat.tool_registry.added, {})
end

T['a server the registry rejected is tried again'] = function()
    local root = project('proj')
    local name = mcp.fff{ root = root }
    report(name, 'connected')
    local chat = fake_chat(window_in(root), { reject = { [name] = true } })

    eq(chat_mod.attach(chat), {})
    chat.tool_registry.reject = {}
    eq(chat_mod.attach(chat), { name })
end

T['a chat opened from a chat window falls back to the buffer path'] = function()
    local root = project('proj')
    local name = mcp.fff{ root = root }
    report(name, 'connected')
    local chat = fake_chat(window_in(env.dir, 'codecompanion'), { path = root .. '/init.lua' })

    eq(chat_mod.chat_dir(chat), root)
    eq(chat_mod.attach(chat), { name })
end

T['companions'] = MiniTest.new_set()

T['companions']['an absent companion adds nothing'] = function()
    local root, companion = project('universe/x'), project('runtime/x')
    local name = mcp.fff{ root = root, companions = { companion } }
    connected{ name }

    eq(chat_mod.attach(fake_chat(window_in(root))), { name })
end

T['companions']['a connected companion is attached too'] = function()
    local root, companion = project('universe/x'), project('runtime/x')
    foreign_entry('fff_runtime_x', companion)
    local name = mcp.fff{ root = root, companions = { companion } }
    connected{ name, 'fff_runtime_x' }

    eq(chat_mod.attach(fake_chat(window_in(root))), { name, 'fff_runtime_x' })
end

T['companions']['a companion that connects later is attached then'] = function()
    local root, companion = project('universe/x'), project('runtime/x')
    foreign_entry('fff_runtime_x', companion)
    local name = mcp.fff{ root = root, companions = { companion } }
    connected{ name }
    local chat = fake_chat(window_in(root))

    eq(chat_mod.attach(chat), { name })
    connected{ name, 'fff_runtime_x' }
    eq(chat_mod.attach(chat), { 'fff_runtime_x' })
end

return T
