-- Skills, commands and agents from the plugins installed and enabled in Claude Code, for CodeCompanion.
--
-- CodeCompanion reads the installed copies in place.  Claude Code substitutes variables such as
-- `${CLAUDE_PLUGIN_ROOT}` before the model sees a skill, while CodeCompanion passes files through verbatim, so
-- the values are given to the model alongside the skill instead.
--
-- Skills go to CodeCompanion's skills; commands and agents become prompt-library slash commands, named the way
-- Claude Code names them (`/<plugin>:<command>`, `/<plugin>:agent:<agent>`).  Agents are also returned by
-- `M.agents()` as data, for runners that start them as separate reviewers.
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

---@param plugin { id: string, root: string }
---@param dir? string the skill's own directory, for `${CLAUDE_SKILL_DIR}`
local function bindings(plugin, dir)
    return table.concat({
        '',
        'This comes from the Claude Code plugin `' .. plugin.id .. '`.',
        'Wherever it or any file it references says `${CLAUDE_PLUGIN_ROOT}` or `$' .. MARKER .. '`, use `'
            .. plugin.root .. '`'
            .. (dir and ('; for `${CLAUDE_SKILL_DIR}`, use `' .. dir .. '`.') or '.'),
        'When running its scripts, set these as environment variables, since some scripts read them.',
        '`$ARGUMENTS` and `$1`, `$2`, … stand for what the user asked for in their message.',
    }, '\n')
end

local function skill_bindings(plugin, skill)
    return bindings(plugin, vim.fs.dirname(skill.path))
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
                    msg.content = msg.content .. skill_bindings(plugin, skill)
                end
            end
        end
    end
end

-- Claude Code names its own tools; the model here has different ones and no way to spawn sub-agents.
local TOOL_NOTE = table.concat({
    'These instructions were written for Claude Code and name its tools (Bash, Read, Grep, Glob, Task, Agent, …).',
    'Use the equivalent tools you have.',
    'Where a step needs a capability you lack, such as spawning a sub-agent, say so instead of improvising around it.',
}, '\n')

local function unquote(v)
    return v:match('^"(.*)"$') or v:match("^'(.*)'$") or v
end

---Read a Claude Code command or agent file.
---
---Claude Code's frontmatter is looser than YAML: `argument-hint: <pr-url> [--fix]` is common and no YAML parser
---accepts it.  So read it the way Claude Code effectively does: one `key: value` per top-level line, `>` and `|`
---block scalars continued by indented lines, and `- item` lists under an empty value.  A file without a closed
---frontmatter block is all body.
---@param path string
---@return { meta: table<string, string>, body: string }
function M.read(path)
    local lines = vim.fn.readfile(path)
    local meta, first = {}, 1
    if lines[1] == '---' then
        local parsed, blocks, current = {}, {}, nil
        for i = 2, #lines do
            local line = lines[i]
            if line == '---' then
                for key, block in pairs(blocks) do
                    parsed[key] = table.concat(block.lines, block.sep)
                end
                meta, first = parsed, i + 1
                break
            end
            local key, value = line:match('^([%w_-]+):%s*(.-)%s*$')
            if key then
                current = nil
                if value == '' or value:match('^[>|][-+]?$') then
                    current = { lines = {}, sep = value:sub(1, 1) == '|' and '\n' or (value == '' and ', ' or ' ') }
                    blocks[key] = current
                else
                    parsed[key] = unquote(value)
                end
            elseif current and line:match('^%s') then
                table.insert(current.lines, unquote((vim.trim(line):gsub('^%-%s+', ''))))
            end
        end
    end
    return { meta = meta, body = vim.trim(table.concat(lines, '\n', first)) }
end

---@param body string
---@return string
local function first_line(body)
    for line in body:gmatch('[^\n]+') do
        local text = vim.trim((line:gsub('^#+%s*', '')))
        if text ~= '' then return text end
    end
    return ''
end

---@param plugin { id: string }
local function short_name(plugin)
    return (plugin.id:gsub('@.*$', ''))
end

---Markdown files under `dir`, recursively, with their path relative to `dir` and without the extension.
---@return { path: string, rel: string }[]
local function markdown_files(dir)
    if vim.fn.isdirectory(dir) == 0 then return {} end
    local found = {}
    for rel, kind in vim.fs.dir(dir, { depth = 5 }) do
        if kind == 'file' and rel:match('%.md$') then
            table.insert(found, { path = dir .. '/' .. rel, rel = rel:gsub('%.md$', '') })
        end
    end
    table.sort(found, function(a, b) return a.rel < b.rel end)
    return found
end

---@class ClaudePlugins.Entry
---@field plugin { id: string, root: string }
---@field name string the name Claude Code invokes it by, e.g. `dev-productivity:review`
---@field description string
---@field path string
---@field meta table<string, string> the rest of the frontmatter: `argument-hint`, `model`, `tools`, …

---Commands of the enabled plugins.  A command in a subdirectory gets a `:`-separated name, as in Claude Code.
---@param plugins { id: string, root: string }[]
---@return ClaudePlugins.Entry[]
function M.commands(plugins)
    local commands = {}
    for _, plugin in ipairs(plugins) do
        for _, file in ipairs(markdown_files(plugin.root .. '/commands')) do
            local doc = M.read(file.path)
            table.insert(commands, {
                plugin = plugin,
                name = short_name(plugin) .. ':' .. file.rel:gsub('/', ':'),
                description = doc.meta.description or first_line(doc.body),
                path = file.path,
                meta = doc.meta,
            })
        end
    end
    return commands
end

---Agents of the enabled plugins: persona definitions whose body is the agent's system prompt.
---@param plugins { id: string, root: string }[]
---@return ClaudePlugins.Entry[]
function M.agents(plugins)
    local agents = {}
    for _, plugin in ipairs(plugins) do
        for _, file in ipairs(markdown_files(plugin.root .. '/agents')) do
            local doc = M.read(file.path)
            table.insert(agents, {
                plugin = plugin,
                name = short_name(plugin) .. ':' .. (doc.meta.name or vim.fs.basename(file.rel)),
                description = doc.meta.description or first_line(doc.body),
                path = file.path,
                meta = doc.meta,
            })
        end
    end
    return agents
end

---Prompt-library items for the commands and agents of the enabled plugins, to merge into `prompt_library`.
---
---Each item adds its instructions as a hidden system message and leaves a user line in the chat buffer for the
---arguments, the counterpart of what follows `/name` in Claude Code.  The file is read when the item is used, not
---here, so that an updated plugin takes effect without a restart as long as its install path is unchanged.
---@param plugins { id: string, root: string }[]
---@return table<string, table>
function M.prompt_library(plugins)
    local items = {}

    local function add(entry, slash, preamble)
        local hint = entry.meta['argument-hint']
        items[slash] = {
            interaction = 'chat',
            description = entry.description .. (hint and hint ~= '' and ('  — ' .. hint) or ''),
            opts = { is_slash_cmd = true, alias = slash, auto_submit = false },
            prompts = {
                {
                    role = 'system',
                    content = function()
                        return table.concat({
                            preamble,
                            '',
                            M.read(entry.path).body,
                            bindings(entry.plugin),
                            '',
                            TOOL_NOTE,
                        }, '\n')
                    end,
                },
                { role = 'user', content = '`/' .. slash .. '` ' },
            },
        }
    end

    for _, command in ipairs(M.commands(plugins)) do
        add(command, command.name, 'The user invoked the Claude Code command `/' .. command.name
            .. '`; the text after it in their message is `$ARGUMENTS`. Its instructions follow.')
    end
    for _, agent in ipairs(M.agents(plugins)) do
        local plugin, persona = agent.name:match('^([^:]+):(.+)$')
        add(agent, plugin .. ':agent:' .. persona, 'From now on in this chat, act as the Claude Code sub-agent `'
            .. agent.name .. '`, defined below, on what the user asks next.'
            .. (agent.meta.tools and (' It was given only these tools: ' .. agent.meta.tools
                .. '; keep to their equivalents.') or ''))
    end
    return items
end

return M
