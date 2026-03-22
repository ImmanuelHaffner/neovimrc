local function get_navic_style_table()
    local colors = require'theme'.colors()
    return {
    -- Separator
    { '> ', ' ', fg = colors.gray, bg = colors.gray3 },
    -- Function
    { '󰊕 ', '󰊕 ', fg = colors.blue, bg = colors.gray3 },
    -- Macro
    { '󰟢 ', '󰟢 ', fg = colors.magenta4, bg = colors.gray3 },
    -- Namespace / Class
    { '󰌗 ', '󰌗 ', fg = colors.orange2, bg = colors.gray3 },
    -- Constructor
    { ' ', ' ', fg = colors.orange, bg = colors.gray3 },
    -- Method
    { '󰆧 ', '󰆧 ', fg = colors.blue, bg = colors.gray3 },
    -- Array
    { '󰅪 ', '󰅪 ', fg = colors.light_purple, bg = colors.gray3, gui = 'bold' },
    -- Table
    { '󰅩 ', '󰅩 ', fg = colors.light_purple, bg = colors.gray3, gui = 'bold' },
    -- Statement
    { ' ', ' ', fg = colors.magenta, bg = colors.gray3 },
    --
    { '󰀬 ', '󰀬 ', fg = colors.orange, bg = colors.gray3 },
    }
end

--- Enrich the navic location string with colors via highlight groups.
--- @param loc string
local function stylize_lsp_status(loc)
    local navic_style_table = get_navic_style_table()
    local hl_groupname_proto = 'GalaxylineLSP%d'

    -- %%#Comment#
    for index, entry in ipairs(navic_style_table) do
        local pattern = entry[1]
        local replacement = entry[2]

        -- Generate group name
        local hl_groupname = hl_groupname_proto:format(index)
        -- Check if group exists
        if vim.fn.hlexists(hl_groupname) ~= 1 then
            -- Create group
            local cmd = 'hi ' .. hl_groupname
            if entry.fg then
                cmd = cmd .. ' guifg=' .. entry.fg
            end
            if entry.bg then
                cmd = cmd .. ' guibg=' .. entry.bg
            end
            if entry.gui then
                cmd = cmd .. ' gui=' .. entry.gui
            end
            vim.api.nvim_command(cmd)
        end

        local styled_replacement = '%%#' .. hl_groupname .. '#' .. replacement .. '%%#LSPSeparator#'
        loc = string.gsub(loc, pattern, styled_replacement)
    end
    return loc
end

--- Check if the given host is an Arca devbox.
--- Detection: ~/.arca directory exists (created by Arca tooling)
--- @param host string The hostname to check
--- @return boolean True if running on an Arca devbox
local function is_arca_devbox(host)
    -- Check for ~/.arca directory which is created by Arca tooling
    local arca_dir = vim.fn.expand('~/.arca')
    return vim.fn.isdirectory(arca_dir) == 1
end

--- Get a friendly alias for the remote host.
--- @param host string The hostname
--- @param port number|nil The port number (optional)
--- @return string|nil The alias if found, nil otherwise
local function get_host_alias(host, port)
    if is_arca_devbox(host) then
        if port then
            if port == 42137 then
                return 'Arca[1]'
            elseif port == 42138 then
                return 'Arca[2]'
            else
                return 'Arca:' .. port
            end
        end
        return 'Arca'
    end
    return nil
end

return {
    {
        'glepnir/galaxyline.nvim',
        dependencies = {
            'SmiteshP/nvim-navic',
            'nvim-lua/lsp-status.nvim',
        },
        branch = 'main',
        config = function()
            local gl = require'galaxyline'
            local Utils = require'utils'
            local colors = require'theme'.colors()

            local lsp_status = require'lsp-status'
            local navic = require'nvim-navic'

            local function get_lsp_progress()
                local lsp_messages = lsp_status.messages()
                local message_list = {}
                -- local spinner_frames = { '⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷' }
                local spinner_frames = { '⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏' }

                for _, msg in ipairs(lsp_messages) do
                    if msg.progress then
                        local message = msg.title
                        if msg.message then message = message .. ' ' .. msg.message end

                        -- this percentage format string escapes a percent sign once to show a percentage and one more
                        -- time to prevent errors in vim statusline's because of it's treatment of % chars
                        if msg.percentage then message = message .. string.format(" (%.0f%%%%)", msg.percentage) end

                        if msg.spinner then
                            message = spinner_frames[(msg.spinner % #spinner_frames) + 1] .. ' ' .. message
                        end
                        table.insert(message_list, message)
                    elseif msg.status then
                        if msg.content ~= 'idle' then
                            table.insert(message_list, msg.content)
                        end
                    end
                end

                return message_list
            end

            gl._mysection = gl._mysection or {}
            local gls = gl.section
            gl.short_line_list = { 'neo-tree', 'neo-tree-popup' }

            -- Expand %S to pending command in statusline.  We will hack this into Galaxyline as a separator, see below
            -- the `OperatorPending` entry.
            vim.o.showcmd = true
            vim.o.showcmdloc = 'statusline'

            -- Clear AsyncRun status on setup
            vim.g.asyncrun_status = ''

            -- Redraw status on macro recording start / stop
            vim.api.nvim_create_autocmd({
                'RecordingEnter', 'RecordingLeave',  -- macro recording
            }, {
                callback = function()
                    gl.load_galaxyline()  -- force redraw
                end,
            })

            -- Redraw status on explicit User event
            -- Can be triggered with `doautocmd User statusline`
            vim.api.nvim_create_autocmd('User', {
                pattern = 'statusline',
                callback = function()
                    gl.load_galaxyline()  -- force redraw
                end,
            })

            -- Redraw on search start
            gl._mysection.search_active = false
            vim.api.nvim_create_autocmd({ 'CmdlineEnter' }, {
                pattern = '[/?]',
                callback = function()
                    gl._mysection.search_active = true
                    gl.load_galaxyline()  -- force redraw
                end,
            })

            local function get_git_branch()
                local result = vim.system({ 'git', 'symbolic-ref', '--short', '-q', 'HEAD' }, { text = true }):wait()
                if result ~= nil and result.signal == 0 and result.code == 0 then
                    return result.stdout:sub(1, -2)
                end

                result = vim.system({ 'git', 'rev-parse', '--short', 'HEAD' }, { text = true }):wait()
                if result ~= nil and result.signal == 0 and result.code == 0 then
                    return 'HEAD detached at ' .. result.stdout:sub(1, -2)
                end

                return ''
            end

            gl._mysection.compose_lsp_status = function()
                local status_str = ''

                local messages = get_lsp_progress()
                if next(messages) ~= nil then
                    status_str = status_str .. table.concat(messages, ' ') .. ' '
                end

                local loc = navic.get_location()
                if loc ~= '' then
                    status_str = status_str .. loc ..  ' '
                end

                if status_str ~= '' then
                    local git_branch = get_git_branch()
                    if status_str:len() + git_branch:len() + 30 > vim.o.columns  then
                        return ''
                    end

                    vim.api.nvim_command('hi LSPSeparatorEnd guifg=' .. colors.gray3 .. ' guibg=' .. colors.gray)
                    status_str = ' ' .. status_str .. '%#LSPSeparatorEnd#'
                end

                status_str = stylize_lsp_status(status_str)
                return status_str
            end

            gl._mysection.set_showcmd = function()
                local enable_showcmd = {
                    ['NORMAL'] = false,
                    ['INSERT'] = true,
                    ['COMMAND'] = true,
                    ['TERMINAL'] = false,  -- don't show terminal mode
                    ['VISUAL'] = false,  -- disable in visual mode due to flickering bug
                    ['V-BLOCK'] = false,
                    ['V-LINE'] = false,
                    ['REPLACE'] = true,
                    ['SELECT'] = true,
                    ['S-LINE'] = true,
                    ['S-BLOCK'] = true,
                    ['PROMPT'] = true,
                    ['SHELL'] = true,
                    ['OPERATOR'] = true,
                }
                local mode = Utils.get_vim_mode_info()[2]
                return enable_showcmd[mode] and ' %S' or ''
            end

            gl._mysection.compose_git_info = function(min_width)
                local git_branch = get_git_branch()
                if git_branch == '' then return '' end

                if min_width + 3 + git_branch:len() < vim.o.columns then
                    return '  ' .. git_branch .. ' '
                end
                if min_width + 3 < vim.o.columns  then
                    return '  '
                end
                return ''
            end

            --  ── Section factories ──────────────────────────────────────────────
            -- Each factory returns a single { Name = { ... } } table suitable for
            -- inclusion in a galaxyline section list.

            local function make_remote()
                return { Remote = {
                    provider = function()
                        if not Utils.is_ssh_connection() and not Utils.is_client_server_connection() then
                            return ' '
                        end
                        local host = vim.fn.hostname()
                        local servername = vim.v.servername
                        local port = nil
                        if servername ~= nil then
                            local pos = servername:find(':')
                            if pos then
                                port = tonumber(servername:sub(pos + 1))
                            end
                        end

                        -- Connection type suffix
                        local suffix = ''
                        if port then
                            suffix = ':' .. port
                        elseif Utils.is_ssh_connection() then
                            suffix = '(SSH)'
                        end


                        -- Check for known alias (alias already encodes host+port)
                        local alias = get_host_alias(host, port)
                        -- Alias encodes port; only append suffix for non-port info (e.g. SSH)
                        local display = alias or host
                        if not alias or not port then
                            display = display .. suffix
                        end
                        return '   ' .. display .. ' '
                    end,
                    highlight = { colors.gray, colors.light_red, 'bold' }
                }}
            end

            local function make_cwd()
                return { Cwd = {
                    provider = function()
                        return '  ' .. Utils.shorten_absolute_path(vim.fn.getcwd(), 30)  --    
                    end,
                    separator = '▐',
                    separator_highlight = { colors.bg, colors.light_red },
                    highlight = { colors.gray, colors.light_red, 'bold' }
                }}
            end

            --- Build a ViMode section.  The section_name controls the Galaxy highlight
            --- group (Galaxy<section_name>), so each statusline instance gets its own
            --- group and they don't interfere with each other.
            local function make_vimode(section_name)
                local hl_group = 'Galaxy' .. section_name
                return { [section_name] = {
                    provider = function()
                        local color, mode = table.unpack(Utils.get_vim_mode_info())
                        vim.api.nvim_command('hi ' .. hl_group .. ' guibg=' .. color)
                        local text = ' ' .. mode
                        if vim.b.toggle_number then
                            text = text .. '['
                            if mode ~= 'TERMINAL' then
                                text = text .. 'TERM '
                            end
                            text = text .. vim.b.toggle_number .. ']'
                        end
                        return text
                    end,
                    highlight = { colors.gray, colors.bg, 'bold' },
                    event = { 'ModeChanged' },
                }}
            end

            --- Build an OperatorPending section that references the highlight group of
            --- the given vimode section.  Must be placed directly after the corresponding
            --- make_vimode() entry so the separator inherits the right background.
            local function make_operator_pending(vimode_section_name)
                local hl_group = 'Galaxy' .. vimode_section_name
                return { OperatorPending = {
                    provider = function() return '' end,
                    separator = '%#' .. hl_group
                        .. [[#%{%luaeval('require"galaxyline"._mysection.set_showcmd()')%} ]],
                }}
            end

            local function make_macro_recording()
                return { MacroRecording = {
                    provider = function()
                        local recording_register = vim.fn.reg_recording()
                        return '  󰑋 recording @' .. recording_register .. ' ' -- Show recording status
                    end,
                    condition = function()
                        local recording_register = vim.fn.reg_recording()
                        return recording_register ~= nil and recording_register ~= ''
                    end,
                    highlight = { colors.fg, colors.dark_red },
                    -- separator = '',
                    separator_highlight = { colors.dark_red, colors.gray },
                    event = { 'RecordingEnter', 'RecordingLeave'},
                }}
            end

            local function make_background()
                return { Background = {
                    provider = function() return '' end,
                    separator = '',
                    separator_highlight = { colors.gray3, colors.gray },
                }}
            end

            local function make_git_info(min_width)
                return { GitInfo = {
                    provider = function() return '' end,
                    separator = [[%{%luaeval('require"galaxyline"._mysection.compose_git_info(]]
                        .. min_width .. [[)')%}]],
                    separator_highlight = { colors.light_orange, colors.gray },
                }}
            end

            local function make_space()
                return { Space = {
                    provider = function() return '' end,
                    highlight = { colors.fg, colors.gray }
                }}
            end

            local function make_asyncrun()
                return { AsyncRun = {
                    provider = function() return vim.g.asyncrun_status .. ' ' end,
                    condition = function() return vim.g['asyncrun_status'] ~= '' end,
                    icon = '  ',
                    separator = '',
                    separator_highlight = { colors.red2, colors.gray },
                    highlight = { colors.gray, colors.red2 },
                    event = { 'AsyncRunPre', 'AsyncRunStart', 'AsyncRunStop' },
                }}
            end

            local function make_lsp()
                return { LSP = {
                    provider = function() return '' end,
                    separator = [[%{%luaeval('require"galaxyline"._mysection.compose_lsp_status()')%}]],
                    separator_highlight = { colors.fg, colors.gray3 },
                }}
            end

            local function make_search()
                return { Search = {
                    provider = function()
                        local search_info = vim.fn.searchcount()
                        if search_info.total == 0 then
                            return ''
                        end

                        local current = search_info.current
                        local total = search_info.total
                        local text = string.format('  󰍉 %d/%d ', current, total)

                        -- Add indicator if search is incomplete
                        if search_info.incomplete == 1 then
                            text = text .. '⏳'
                        elseif search_info.incomplete == 2 then
                            text = text .. '>'
                        end

                        return text
                    end,
                    condition = function()
                        local search_info = vim.fn.searchcount()
                        -- Show if we have an active search with matches
                        return gl._mysection.search_active and search_info.total > 0
                    end,
                    highlight = { colors.gray, colors.orange },
                    separator = '',
                    separator_highlight = { colors.green, colors.gray },
                }}
            end

            local function make_cursor_pos()
                return { CursorPos = {
                    provider = function()
                        local _, line, byte, _ = table.unpack(vim.fn.getpos('.'))
                        local col = vim.fn.virtcol('.')  -- get the visible column, not bytes in line
                        local str = ''

                        local visual_modes = { [118]=true, [22]=true, [86]=true }
                        if visual_modes[vim.fn.mode():byte()] then
                            local starts = vim.fn.line'v'
                            local ends = vim.fn.line'.'
                            local lines = starts <= ends and ends - starts + 1 or starts - ends + 1
                            str = str .. '  󰊄 ' .. tostring(lines) .. 'L,' .. tostring(vim.fn.wordcount().visual_chars) .. 'C'
                        end

                        str = str .. '   ' .. line .. ',' .. col
                        if col ~= byte then
                            str = str .. ' (B' .. byte .. ')'
                        end
                        return str
                    end,
                    highlight = { colors.gray, colors.purple3 },
                }}
            end

            local function make_percent()
                return { PerCent = {
                    provider = 'LinePercent',
                    separator = '',
                    separator_highlight = { colors.blue, colors.purple3 },
                    highlight = { colors.gray, colors.blue }
                }}
            end

            local function make_buffer_icon()
                return { BufferIcon = {
                    provider = 'BufferIcon',
                    highlight = { colors.yellow, colors.section_bg },
                    separator = '',
                    separator_highlight = { colors.section_bg, colors.bg }
                }}
            end

            --  ── Section composition helpers ────────────────────────────────────
            local function right_common(min_width)
                return {
                    make_git_info(min_width),
                    make_space(),
                    make_asyncrun(),
                    make_search(),
                }
            end

            --  ── Left side ──────────────────────────────────────────────────────
            gls.left = {
                make_remote(),
                make_cwd(),
                make_vimode('ViMode'),
                make_operator_pending('ViMode'),
                make_macro_recording(),
                make_lsp(),
                make_background(),
            }

            --  ── Right side ─────────────────────────────────────────────────────
            gls.right = vim.list_extend(right_common(25), {
                make_cursor_pos(),
                make_percent(),
            })

            --  ── Short status line (left) ───────────────────────────────────────
            gls.short_line_left = {
                make_remote(),
                make_cwd(),
                make_vimode('ViModeShort'),
                make_operator_pending('ViModeShort'),
                make_macro_recording(),
                make_background(),
            }

            --  ── Short status line (right) ──────────────────────────────────────
            gls.short_line_right = vim.list_extend(right_common(12), {
                make_buffer_icon(),
            })

            -- Force manual load so that nvim boots with a status line
            gl.load_galaxyline()
        end,
    },
}
