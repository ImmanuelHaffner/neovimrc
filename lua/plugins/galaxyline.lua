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

              return message_list
            end

            local gls = gl.section
            gl.short_line_list = {'defx', 'packager', 'vista', 'NvimTree'}

            -- Local helper functions
            local buffer_not_empty = function() return not Utils.is_buffer_empty() end

            local checkwidth = function()
                return Utils.has_width_gt(40) and buffer_not_empty()
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

            -- Clear AsyncRun status on setup
            vim.g.asyncrun_status = ''

            -- Left side
            gls.left[1] = {
                ViMode = {
                    provider = function()
                        local color, mode = unpack(Utils.get_vim_mode_info())
                        vim.api.nvim_command('hi GalaxyViMode guibg=' .. color)
                        return '  ' .. mode .. ' '
                    end,
                    highlight = {colors.bg, colors.bg, 'bold'}
                }
            }
            -- gls.left[2] = {
            --     FileIcon = {
            --         provider = {function() return '  ' end, 'FileIcon'},
            --         condition = buffer_not_empty,
            --         highlight = {
            --             require('galaxyline.provider_fileinfo').get_file_icon,
            --             colors.section_bg
            --         }
            --     }
            -- }
            -- gls.left[3] = {
            --     FileName = {
            --         provider = get_current_file_name,
            --         condition = buffer_not_empty,
            --         highlight = {colors.fg, colors.section_bg},
            --         separator = "",
            --         separator_highlight = {colors.section_bg, colors.bg}
            --     }
            -- }
            -- gls.left[4] = {
            --     DiagnosticError = {
            --         provider = 'DiagnosticError',
            --         condition = buffer_not_empty,
            --         icon = '  ',
            --         highlight = {colors.red1, colors.bg},
            --     }
            -- }
            -- gls.left[5] = {
            --     DiagnosticWarn = {
            --         provider = 'DiagnosticWarn',
            --         condition = buffer_not_empty,
            --         icon = '  ',
            --         highlight = {colors.orange, colors.bg},
            --     }
            -- }
            -- gls.left[6] = {
            --     DiagnosticInfo = {
            --         provider = 'DiagnosticInfo',
            --         condition = buffer_not_empty,
            --         icon = '  ',
            --         highlight = {colors.blue, colors.bg},
            --         separator = "",
            --         separator_highlight = {colors.bg, colors.section_bg},
            --     }
            -- }
            -- LSP status (current function)
            gls.left[2] = {
                LSPStatus = {
                    provider = function()
                        local messages = get_lsp_progress()
                        if next(messages) == nil then
                            return ''
                        end
                        return '  ' .. table.concat(messages) .. ' '
                    end,
                    condition = function() return next(vim.lsp.get_clients()) ~= nil end,
                    highlight = {colors.middlegrey, colors.section_bg},
                }
            }
            gls.left[9] = {
                nvimNavic = {
                    provider = function()
                        local loc = navic.get_location()
                        if loc == '' then
                            return ''
                        end
                        return '  ' .. navic.get_location() .. ' '
                    end,
                    condition = function()
                        return buffer_not_empty() and navic.is_available()
                    end,
                    highlight = {colors.middlegrey, colors.section_bg},
                    separator = "",
                    separator_highlight = {colors.section_bg, colors.bg},
                }
            }
            -- gls.left[10] = {
            --     color = {
            --         provider = function() return '' end,
            --         condition = function()
            --             return buffer_not_empty() and navic.is_available()
            --         end,
            --         highlight = {colors.section_bg, colors.bg},
            --     }
            -- }
            gls.left[10] = {
                color = {
                    provider = function() return '' end,
                    highlight = {colors.section_bg, colors.bg},
                }
            }

            -- Right side
            -- gls.right[1] = {
            --     DiffAdd = {
            --         provider = 'DiffAdd',
            --         condition = checkwidth,
            --         icon = '+',
            --         highlight = {colors.green, colors.bg}
            --     }
            -- }
            -- gls.right[2] = {
            --     DiffModified = {
            --         provider = 'DiffModified',
            --         condition = checkwidth,
            --         icon = '~',
            --         highlight = {colors.orange, colors.bg}
            --     }
            -- }
            -- gls.right[3] = {
            --     DiffRemove = {
            --         provider = 'DiffRemove',
            --         condition = checkwidth,
            --         icon = '-',
            --         highlight = {colors.red1, colors.bg}
            --     }
            -- }
            -- gls.right[4] = {
            --     Space = {
            --         provider = function() return ' ' end,
            --         highlight = {colors.section_bg, colors.bg}
            --     }
            -- }
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
