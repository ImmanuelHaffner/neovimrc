-- Skills from the plugins installed and enabled in Claude Code, for CodeCompanion's skills.
--
-- CodeCompanion reads the installed copies in place.  Claude Code substitutes variables such as
-- `${CLAUDE_PLUGIN_ROOT}` before the model sees a skill, while CodeCompanion passes files through verbatim, so
-- the values are given to the model alongside the skill instead.
local M = {}

local function read_json(path)
    local ok, data = pcall(function() return vim.json.decode(table.concat(vim.fn.readfile(path), '\n')) end)
    return ok and type(data) == 'table' and data or {}
end

---Plugins enabled in Claude Code, at the install path Claude Code itself loads them from.
---@return { id: string, root: string }[]
function M.plugins()
    local home = vim.fn.expand('~/.claude')
    local enabled = read_json(home .. '/settings.json').enabledPlugins or {}
    local installed = read_json(home .. '/plugins/installed_plugins.json').plugins or {}
    local plugins = {}
    for id, on in pairs(enabled) do
        local entry = on and (installed[id] or {})[1]
        if entry and entry.installPath and vim.fn.isdirectory(entry.installPath) == 1 then
            table.insert(plugins, { id = id, root = entry.installPath })
        end
    end
    -- `pairs` order is unspecified, and the order of `skills.dirs` decides which skill wins a name clash.
    table.sort(plugins, function(a, b) return a.id < b.id end)
    return plugins
end

---@param plugins { id: string, root: string }[]
---@return string[]
function M.skill_dirs(plugins)
    return vim.iter(plugins)
        :map(function(p) return p.root .. '/skills' end)
        :filter(function(d) return vim.fn.isdirectory(d) == 1 end)
        :totable()
end

local MARKER = 'CLAUDE_PLUGIN_ROOT'

local function bindings(plugin, skill)
    return table.concat({
        '',
        'This skill comes from the Claude Code plugin `' .. plugin.id .. '`.',
        'Wherever it or any file it references says `${CLAUDE_PLUGIN_ROOT}` or `$' .. MARKER .. '`, use `'
            .. plugin.root .. '`; for `${CLAUDE_SKILL_DIR}`, use `'
            .. vim.fs.dirname(skill.path) .. '`.',
        'When running its scripts, set both as environment variables, since some scripts read them.',
        '`$ARGUMENTS` and `$1`, `$2`, … stand for what the user asked for in their message.',
    }, '\n')
end

---Append the variable bindings to the context message CodeCompanion adds for each Claude plugin skill.
---
---Every path that adds a skill (`/skills`, `/skills_group`, prompt-library skills, autoload) calls
---`add_to_chat` through the module table, so wrapping it covers them all.  The bindings go into the skill's own
---message, found by its `<skill>name</skill>` context id, because a separate context item would not be tied to
---that skill.
---@param plugins { id: string, root: string }[]
function M.patch_codecompanion(plugins)
    local skills = require'codecompanion.skills'
    local add_to_chat = skills.add_to_chat
    local function owner(path)
        return vim.iter(plugins):find(function(p) return vim.startswith(path, p.root .. '/') end)
    end
    ---@diagnostic disable-next-line: duplicate-set-field
    skills.add_to_chat = function(chat, list)
        add_to_chat(chat, list)
        for _, skill in ipairs(list or {}) do
            local plugin = owner(skill.path)
            if plugin then
                local id = '<skill>' .. skill.name .. '</skill>'
                local msg = vim.iter(chat.messages):find(function(m) return m.context and m.context.id == id end)
                -- Re-adding a skill already in the chat is a no-op upstream, so must not append twice either.
                if msg and type(msg.content) == 'string' and not msg.content:find(MARKER, 1, true) then
                    msg.content = msg.content .. bindings(plugin, skill)
                end
            end
        end
    end
end

return M
