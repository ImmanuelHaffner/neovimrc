--- Per-chat attachment of project-scoped MCP servers.
---
--- CodeCompanion's `default_tools` apply to every chat alike, so listing project servers there handed each
--- chat the indexes of every project any Neovim on the hub had open.  Instead `default_tools` names only
--- global servers (`M.global_tool_names`), and each chat gets the project servers of the directory it was
--- opened from, added to that chat alone (`M.attach`).
---
--- A project server may still be indexing when the chat opens, so `attach` runs again on every
--- `servers_updated` and adds what has connected since.  Each server is attached at most once per chat:
--- one the user removed from a chat stays removed.

local mcp = require 'project.mcp'

local M = {}

--- Per chat buffer: the directory it belongs to, and the servers already attached to it.
--- @type table<integer, { dir: string, attached: table<string, true> }>
M.chats = {}

--- The directory a chat belongs to: the cwd of the window it was opened from.
---
--- A chat opened from another chat's window inherits nothing from that window, which shows no project, so
--- the originating buffer's directory stands in; failing that, the global cwd.
--- @param chat { buffer_context?: { winnr?: integer, path?: string } }
--- @return string
function M.chat_dir(chat)
    local context = chat.buffer_context or {}
    local win = context.winnr
    if win and vim.api.nvim_win_is_valid(win)
        and vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= 'codecompanion' then
        local tab = vim.api.nvim_tabpage_get_number(vim.api.nvim_win_get_tabpage(win))
        return vim.fn.getcwd(win, tab)
    end
    if context.path and context.path ~= '' then return vim.fs.dirname(context.path) end
    return vim.fn.getcwd(-1, -1)
end

--- Attach the connected project servers of `chat`'s directory that it does not have yet.
---
--- A server counts as attached only once the registry accepted it: until mcphub has registered the
--- server's tool group, `add` returns nil and the next call tries again.
--- @param chat { bufnr: integer, buffer_context?: table, tool_registry: { add: fun(self, name: string): any } }
--- @return string[] names the servers attached by this call
function M.attach(chat)
    local record = M.chats[chat.bufnr]
    if not record then
        record = { dir = M.chat_dir(chat), attached = {} }
        M.chats[chat.bufnr] = record
    end

    local added = {}
    for _, name in ipairs(mcp.servers_for_dir(record.dir)) do
        if not record.attached[name] and chat.tool_registry:add(name) then
            record.attached[name] = true
            table.insert(added, name)
        end
    end
    return added
end

--- Drop the record of a closed chat.
--- @param bufnr integer
function M.forget(bufnr) M.chats[bufnr] = nil end

--- The servers every chat gets: connected `fff*` and `mcphub` servers that are not project-scoped.
--- @param server_state { servers?: table[], native_servers?: table[] }
--- @return string[]
function M.global_tool_names(server_state)
    local names = {}
    for _, servers in ipairs{ server_state.servers or {}, server_state.native_servers or {} } do
        for _, server in ipairs(servers) do
            local name = server.name
            if type(name) == 'string' and (name == 'mcphub' or name:match('^fff'))
                and server.status == 'connected' and not mcp.is_project_server(server) then
                table.insert(names, name)
            end
        end
    end
    return names
end

return M
