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
                  if msg.percentage then message = message .. string.format(" (%.0f%%)", msg.percentage) end

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

              return table.concat(message_list, ' ')
            end

            local gls = gl.section
            gl.short_line_list = {'defx', 'packager', 'vista', 'NvimTree'}

            local colors = {
                bg = '#282c34',
                fg = '#aab2bf',
                section_bg = '#38393f',
                blue = '#61afef',
                green = '#98c379',
                purple = '#c678dd',
                orange = '#e5c07b',
                red1 = '#e06c75',
                red2 = '#be5046',
                yellow = '#e5c07b',
                gray1 = '#5c6370',
                gray2 = '#2c323d',
                gray3 = '#3e4452',
                darkgrey = '#5c6370',
                grey = '#848586',
                middlegrey = '#8791A5'
            }

            -- Local helper functions
            local buffer_not_empty = function() return not Utils.is_buffer_empty() end

            local checkwidth = function()
                return Utils.has_width_gt(40) and buffer_not_empty()
            end

            local mode_color = function()
                local mode_colors = {
                    [110] = colors.green,
                    [105] = colors.blue,
                    [99] = colors.green,
                    [116] = colors.blue,
                    [118] = colors.purple,
                    [22] = colors.purple,
                    [86] = colors.purple,
                    [82] = colors.red1,
                    [115] = colors.red1,
                    [83] = colors.red1
                }

                local mode_color = mode_colors[vim.fn.mode():byte()]
                if mode_color ~= nil then
                    return mode_color
                else
                    return colors.purple
                end
            end

            local function file_readonly()
                if vim.bo.filetype == 'help' then return '' end
                if vim.bo.readonly == true then return '  ' end
                return ''
            end

            local function get_current_file_name()
                local file = vim.fn.expand('%:t')
                if vim.fn.empty(file) == 1 then return '' end
                if string.len(file_readonly()) ~= 0 then return file .. file_readonly() end
                if vim.bo.modifiable then
                    if vim.bo.modified then return file .. '  ' end
                end
                return file .. ' '
            end

            local function mode_alias()
                local aliases = {
                    [110] = 'NORMAL',
                    [105] = 'INSERT',
                    [99] = 'COMMAND',
                    [116] = 'TERMINAL',
                    [118] = 'VISUAL',
                    [22] = 'V-BLOCK',
                    [86] = 'V-LINE',
                    [82] = 'REPLACE',
                    [115] = 'SELECT',
                    [83] = 'S-LINE'
                }
                return aliases[vim.fn.mode():byte()]
            end

            -- Clear AsyncRun status on setup
            vim.g.asyncrun_status = ''

            -- Left side
            gls.left[1] = {
                ViMode = {
                    provider = function()
                        vim.api.nvim_command('hi GalaxyViMode guibg=' .. mode_color())
                        local alias = mode_alias()
                        if alias ~= nil then
                            return '  ' .. alias .. ' '
                        else
                            return '  ' .. vim.fn.mode():byte() .. ' '
                        end
                    end,
                    highlight = {colors.bg, colors.bg, 'bold'}
                }
            }
            gls.left[2] = {
                FileIcon = {
                    provider = {function() return '  ' end, 'FileIcon'},
                    condition = buffer_not_empty,
                    highlight = {
                        require('galaxyline.provider_fileinfo').get_file_icon,
                        colors.section_bg
                    }
                }
            }
            gls.left[3] = {
                FileName = {
                    provider = get_current_file_name,
                    condition = buffer_not_empty,
                    highlight = {colors.fg, colors.section_bg},
                    separator = "",
                    separator_highlight = {colors.section_bg, colors.bg}
                }
            }
            gls.left[4] = {
                DiagnosticError = {
                    provider = 'DiagnosticError',
                    condition = buffer_not_empty,
                    icon = '  ',
                    highlight = {colors.red1, colors.bg},
                }
            }
            gls.left[5] = {
                DiagnosticWarn = {
                    provider = 'DiagnosticWarn',
                    condition = buffer_not_empty,
                    icon = '  ',
                    highlight = {colors.orange, colors.bg},
                }
            }
            gls.left[6] = {
                DiagnosticInfo = {
                    provider = 'DiagnosticInfo',
                    condition = buffer_not_empty,
                    icon = '  ',
                    highlight = {colors.blue, colors.bg},
                    separator = "",
                    separator_highlight = {colors.bg, colors.section_bg},
                }
            }
            -- LSP status (current function)
            gls.left[8] = {
                LSPStatus = {
                    provider = function() return ' ' .. get_lsp_progress() .. ' ' end,
                    condition = function() return #vim.lsp.get_clients() > 0 end,
                    highlight = {colors.middlegrey, colors.section_bg},
                }
            }
            gls.left[9] = {
                nvimNavic = {
                    provider = function()
                        return ' ' .. navic.get_location() .. ' '
                    end,
                    condition = function()
                        return buffer_not_empty() and navic.is_available()
                    end,
                    highlight = {colors.middlegrey, colors.section_bg},
                    separator = "",
                    separator_highlight = {colors.section_bg, colors.bg},
                }
            }
            gls.left[10] = {
                color = {
                    provider = function() return '' end,
                    condition = function()
                        return not (buffer_not_empty() and navic.is_available())
                    end,
                    highlight = {colors.section_bg, colors.bg},
                }
            }

            -- Right side
            gls.right[1] = {
                DiffAdd = {
                    provider = 'DiffAdd',
                    condition = checkwidth,
                    icon = '+',
                    highlight = {colors.green, colors.bg}
                }
            }
            gls.right[2] = {
                DiffModified = {
                    provider = 'DiffModified',
                    condition = checkwidth,
                    icon = '~',
                    highlight = {colors.orange, colors.bg}
                }
            }
            gls.right[3] = {
                DiffRemove = {
                    provider = 'DiffRemove',
                    condition = checkwidth,
                    icon = '-',
                    highlight = {colors.red1, colors.bg}
                }
            }
            gls.right[4] = {
                Space = {
                    provider = function() return ' ' end,
                    highlight = {colors.section_bg, colors.bg}
                }
            }
            gls.right[5] = {
                GitIcon = {
                    provider = function() return '  ' end,
                    condition = buffer_not_empty and require('galaxyline.provider_vcs').check_git_workspace,
                    highlight = {colors.middlegrey, colors.bg}
                }
            }
            gls.right[6] = {
                GitBranch = {
                    provider = 'GitBranch',
                    condition = buffer_not_empty,
                    highlight = {colors.middlegrey, colors.bg}
                }
            }
            gls.right[7] = {
                Space = {
                    provider = function() return ' ' end,
                    condition = buffer_not_empty and require('galaxyline.provider_vcs').check_git_workspace,
                    highlight = {colors.middlegrey, colors.bg}
                }
            }
            gls.right[8] = {
                AsyncRun = {
                    provider = function() return vim.g.asyncrun_status .. ' ' end,
                    condition = function() return vim.g['asyncrun_status'] ~= '' end,
                    icon = '  ',
                    separator = '',
                    separator_highlight = { colors.red1, colors.bg },
                    highlight = { colors.gray2, colors.red1 },
                    event = { 'AsyncRunPre', 'AsyncRunStart', 'AsyncRunStop' },
                }
            }
            gls.right[10] = {
                CursorPos = {
                    provider = function()
                        local _, line, byte, _ = unpack(vim.fn.getpos('.'))
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
                    highlight = { colors.gray2, colors.purple },
                }
            }
            gls.right[11] = {
                PerCent = {
                    provider = 'LinePercent',
                    separator = '',
                    separator_highlight = { colors.blue, colors.purple },
                    highlight = {colors.gray2, colors.blue}
                }
            }

            -- Short status line
            gls.short_line_left[1] = {
                BufferType = {
                    provider = 'FileTypeName',
                    highlight = {colors.fg, colors.section_bg},
                    separator = ' ',
                    separator_highlight = {colors.section_bg, colors.bg}
                }
            }

            gls.short_line_right[1] = {
                BufferIcon = {
                    provider = 'BufferIcon',
                    highlight = {colors.yellow, colors.section_bg},
                    separator = '',
                    separator_highlight = {colors.section_bg, colors.bg}
                }
            }

            -- Force manual load so that nvim boots with a status line
            gl.load_galaxyline()
        end,
    },
}
