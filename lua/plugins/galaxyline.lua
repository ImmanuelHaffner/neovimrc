local colors = require'theme'.colors()
local Utils = require'utils'

local navic_style_table = {
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

--- Enrich the navic location string with colors via highlight groups.
--- @param loc string
local function stylize_lsp_status(loc)
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

return {
    { 'glepnir/galaxyline.nvim',
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
              local spinner_frames = { '⣾', '⣽', '⣻', '⢿', '⡿', '⣟', '⣯', '⣷' }

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
            gl.short_line_list = {'neo-tree'}

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
                    ['NORMAL'] = true,
                    ['INSERT'] = true,
                    ['COMMAND'] = true,
                    ['TERMINAL'] = true,
                    ['VISUAL'] = false,
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

            -- Left side
            gls.left = {
                { ViMode = {
                    provider = function()
                        local color, mode = table.unpack(Utils.get_vim_mode_info())
                        vim.api.nvim_command('hi GalaxyViMode guibg=' .. color)
                        local text = '  ' .. mode
                        if vim.o.filetype == 'toggleterm' then
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
                }},
                -- Hack the Operator Pending information into Galaxyline.  We must do this as a `separator` to bypass
                -- escaping.
                { OperatorPending = {
                    provider = function() return '' end,
                    separator = [[%#GalaxyViMode#%{%luaeval('require"galaxyline"._mysection.set_showcmd()')%} ]],  -- the name must match the previous section name
                }},
                { MacroRecording = {
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
                }},
                -- Hack the LSP status as a separator that calls our function.
                { LSP = {
                    provider = function() return '' end,
                    separator = [[%{%luaeval('require"galaxyline"._mysection.compose_lsp_status()')%}]],  -- the name must match the previous section name
                    separator_highlight = { colors.fg, colors.gray3 },
                }},
                { Background = {
                    provider = function() return '' end,
                    separator = '',
                    separator_highlight = { colors.gray3, colors.gray },
                }},
            }

            -- Right side
            gls.right = {
                { GitInfo = {
                    provider = function() return '' end,
                    separator = [[%{%luaeval('require"galaxyline"._mysection.compose_git_info(25)')%}]],
                    separator_highlight = { colors.light_orange, colors.gray },
                }},
                { Space = {
                    provider = function() return '' end,
                    highlight = { colors.fg, colors.gray }
                }},
                { AsyncRun = {
                    provider = function() return vim.g['asyncrun_status'] .. ' ' end,
                    condition = function() return vim.g['asyncrun_status'] ~= '' end,
                    icon = '  ',
                    separator = '',
                    separator_highlight = { colors.red2, colors.gray },
                    highlight = { colors.gray, colors.red2 },
                    event = { 'AsyncRunPre', 'AsyncRunStart', 'AsyncRunStop' },
                }},
                { Search = {
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
                }},
                { CursorPos = {
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
                }},
                { PerCent = {
                    provider = 'LinePercent',
                    separator = '',
                    separator_highlight = { colors.blue, colors.purple3 },
                    highlight = { colors.gray, colors.blue }
                }},
            }

            -- Short status line
            gls.short_line_left = {
                { ViMode = {
                    provider = function()
                        local color, mode = table.unpack(Utils.get_vim_mode_info())
                        vim.api.nvim_command('hi GalaxyViMode guibg=' .. color)
                        return '  ' .. mode
                    end,
                    highlight = { colors.gray, colors.bg, 'bold' },
                    event = { 'ModeChanged' },
                }},
                -- Hack the Operator Pending information into Galaxyline.  We must do this as a `separator` to bypass
                -- escaping.
                { OperatorPending = {
                    provider = function() return '' end,
                    separator = '%#GalaxyViMode# %S ',  -- the name must match the previous section name
                }},
                { color = {
                    provider = function() return '' end,
                    highlight = { colors.gray3, colors.gray },
                }},
            }

            gls.short_line_right = {
                { MacroRecording = {
                    provider = function()
                        local recording_register = vim.fn.reg_recording()
                        return ' 󰑋 recording @' .. recording_register .. ' ' -- Show recording status
                    end,
                    condition = function()
                        local recording_register = vim.fn.reg_recording()
                        return recording_register ~= nil and recording_register ~= ''
                    end,
                    highlight = { colors.fg, colors.dark_red },
                    separator = '',
                    separator_highlight = { colors.dark_red, colors.gray },
                    event = { 'RecordingEnter', 'RecordingLeave'},
                }},
                { MacroRecordingEnd = {
                    provider = function() return '  ' end,
                    condition = function()
                        local recording_register = vim.fn.reg_recording()
                        return recording_register ~= nil and recording_register ~= ''
                    end,
                    highlight = { colors.dark_red, colors.gray },
                    event = { 'RecordingEnter', 'RecordingLeave'},
                }},
                { GitInfo = {
                    provider = function() return '' end,
                    separator = [[%{%luaeval('require"galaxyline"._mysection.compose_git_info(12)')%}]],
                    separator_highlight = { colors.light_orange, colors.gray },
                }},
                { Space = {
                    provider = function() return '' end,
                    highlight = { colors.fg, colors.gray }
                }},
                { AsyncRun = {
                    provider = function() return vim.g.asyncrun_status .. ' ' end,
                    condition = function() return vim.g['asyncrun_status'] ~= '' end,
                    icon = '  ',
                    separator = '',
                    separator_highlight = { colors.red2, colors.gray },
                    highlight = { colors.gray, colors.red2 },
                    event = { 'AsyncRunPre', 'AsyncRunStart', 'AsyncRunStop' },
                }},
                { BufferIcon = {
                    provider = 'BufferIcon',
                    highlight = {colors.yellow, colors.section_bg},
                    separator = '',
                    separator_highlight = {colors.section_bg, colors.bg}
                }},
            }

            -- Force manual load so that nvim boots with a status line
            gl.load_galaxyline()
        end,
    },
}
