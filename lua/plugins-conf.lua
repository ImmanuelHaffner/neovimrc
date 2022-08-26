local M = { }

function M.setup()

    --- NeoSolarized {{{------------------------------------------------------------------------------------------------
    vim.cmd[[colorscheme NeoSolarized]]
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- lsp_lines {{{-------------------------------------------------------------------------------------------------
    vim.diagnostic.config({
        virtual_text = false, -- Disable virtual_text since it's redundant due to lsp_lines.
    })
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- Airline {{{---------------------------------------------------------------------------------------------------
    -- vim.cmd[[
    -- let g:airline#extensions#tabline#enabled = 1
    -- let g:airline#extensions#tagbar#enabled = 0
    -- let g:airline_powerline_fonts = 1
    -- let g:airline#extensions#tabline#show_buffers = 0
    -- let g:airline#extensions#tabline#formatter = 'unique_tail_improved'
    -- let g:airline_section_error = airline#section#create_right(['%{g:asyncrun_status}'])
    -- ]]
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- Neovim Session Manager {{{------------------------------------------------------------------------------------
    local Path = require('plenary.path')
    require('session_manager').setup({
        sessions_dir = Path:new(vim.fn.stdpath('data'), '.sessions'), -- The directory where the session files will be saved.
        path_replacer = '__', -- The character to which the path separator will be replaced for session files.
        colon_replacer = '++', -- The character to which the colon symbol will be replaced for session files.
        autoload_mode = require('session_manager.config').AutoloadMode.CurrentDir, -- Define what to do when Neovim is started without arguments. Possible values: Disabled, CurrentDir, LastSession
        autosave_last_session = true, -- Automatically save last session on exit and on session switch.
        autosave_ignore_not_normal = true, -- Plugin will not save a session when no buffers are opened, or all of them aren't writable or listed.
        autosave_ignore_filetypes = { -- All buffers of these file types will be closed before the session is saved.
        'gitcommit',
    },
    autosave_only_in_session = false, -- Always autosaves session. If true, only autosaves after a session is active.
    max_path_length = 80,  -- Shorten the display path if length exceeds this threshold. Use 0 if don't want to shorten the path at all.
    })
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- CtrlP {{{-----------------------------------------------------------------------------------------------------
    if vim.fn.executable('ag') == 1 then
        vim.g.ctrlp_user_command = 'ag %s -l --nocolor -g ""'
    elseif vim.fn.executable('ack') then
        vim.g.ctrlp_user_command = 'ack %s -l --nocolor -g ""'
    end
    vim.g.ctrlp_custom_ignore = {
        ['dir']  = '\\v[\\/]\\.(git|hg|svn)$|build',
        ['file'] = '\\v\\.(exe|so|dll|a)$',
    }
    vim.g.ctrlp_cache_dir = os.getenv('HOME') .. '/.cache/ctrlp'
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- IndentLine {{{------------------------------------------------------------------------------------------------
    vim.g.indentLine_enabled = false
    vim.cmd[[
    augroup filetype
        au FileType c,cpp,python,java IndentLinesEnable
    augroup END
    ]]
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- ViewDoc {{{---------------------------------------------------------------------------------------------------
    vim.g.viewdoc_openempty = false

    -- If set to 1, the word which is looked up is also copied into the Vims search register which allows to easily search
    -- in the documentation for occurrences of this word.
    vim.g.viewdoc_copy_to_search_reg = true
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- Gutentags {{{-------------------------------------------------------------------------------------------------
    vim.g.gutentags_cache_dir = os.getenv('HOME') .. '/.cache/vim/tags'
    vim.g.gutentags_generate_on_new = true
    vim.g.gutentags_generate_on_missing = true
    vim.g.gutentags_generate_on_write = true
    vim.g.gutentags_generate_on_empty_buffer = false
    vim.g.gutentags_ctags_extra_args = {
        '--tag-relative=yes',
        '--fields=+ailmnS',
    }
    vim.g.gutentags_file_list_command = {
        ['markers'] = {
            ['.git'] = 'git ls-files',
            ['.hg']  = 'hg files',
        }
    }
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- Telescope {{{-------------------------------------------------------------------------------------------------
    require('telescope').setup {
        extensions = {
            ['fzf'] = {
                fuzzy = true,                    -- false will only do exact matching
                override_generic_sorter = true,  -- override the generic sorter
                override_file_sorter = true,     -- override the file sorter
                case_mode = 'smart_case',        -- or "ignore_case" or "respect_case"
            },
            ['ui-select'] = { require('telescope.themes').get_dropdown { } }
        }
    }
    -- To get fzf loaded and working with telescope, you need to call
    -- load_extension, somewhere after setup function:
    local telescope = require('telescope')
    telescope.load_extension('fzf')
    telescope.load_extension('ui-select')
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- VimTeX {{{----------------------------------------------------------------------------------------------------
    vim.g.tex_flavor = 'latex'
    vim.g.vimtex_compiler_method = 'latexmk'
    vim.g.vimtex_view_method = 'zathura'
    vim.g.vimtex_view_zathura_options = '-x "nvr --servername ' .. vim.api.nvim_get_vvar('servername') .. ' --remote-silent %{input} -c %{line}"'
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- NERDCommenter {{{---------------------------------------------------------------------------------------------
    vim.g.NERDCreateDefaultMappings = 0
    vim.g.NERDAllowAnyVisualDelims = 1
    vim.g.NERDSpaceDelims = 1
    vim.g.NERDCompactSexyComs = 1
    vim.g.NERDTrimTrailingWhitespace = 1
    vim.g.NERDDefaultAlign = 'left'
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- nvim-cmp {{{--------------------------------------------------------------------------------------------------
    local cmp = require'cmp'
    cmp.setup{
        sources = cmp.config.sources({
            { name = 'nvim_lsp' },
            { name = 'path' },
        }, {
            { name = 'buffer' },
        }),
        mapping = cmp.mapping.preset.insert{
            ['C-n'] = cmp.mapping.select_next_item(),
            ['C-p'] = cmp.mapping.select_prev_item(),
            ['C-b'] = cmp.mapping.scroll_docs(8),
            ['C-f'] = cmp.mapping.scroll_docs(-8),
        },
    }
    cmp.setup.filetype('gitcommit', {
        sources = cmp.config.sources({
            { name = 'cmp_git' },
        }, {
            { name = 'buffer' },
        })
    })
    cmp.setup.cmdline('/', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
            { name = 'buffer' }
        }
    })
    cmp.setup.cmdline(':', {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
            { name = 'path' }
        }, {
            { name = 'cmdline' }
        })
    })
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- lsp_signature {{{---------------------------------------------------------------------------------------------
    require'lsp_signature'.setup{
        bind = true, -- This is mandatory, otherwise border config won't get registered.
        handler_opts = {
            border = 'rounded'
        }
    }
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- tabline {{{---------------------------------------------------------------------------------------------------
    --[[
    local render = function(f)
        local colors = {
            black = '#000000',
            white = '#ffffff',
            bg = '#181A1F',
            bg_sel = '#282c34',
            fg = '#696969'
        }

        f.add { '  ' }

        f.make_tabs(function(info)
            f.add {  ' ', fg = colors.black }
            f.set_fg(not info.current and colors.fg or nil)

            f.add( info.index .. ' ')

            if info.filename then
                f.add {
                    f.icon(info.filename),
                    fg = info.current and f.icon_color(info.filename) or nil
                }
                f.add(' ' .. info.filename)
                f.add(info.modified and '+')
            else
                f.add(info.modified and '[+]' or '[-]')
            end

            f.add {
                ' ',
                fg = info.current and colors.bg_sel or colors.bg,
                bg = colors.black
            }
        end)

        f.add_spacer()

        local errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
        local warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })

        f.add { '  ' .. errors, fg = "#e86671" }
        f.add { '  ' .. warnings, fg = "#e5c07b"}
        f.add ' '
    end

    require('tabline_framework').setup{
        render = render,
        hl = { fg = '#abb2bf', bg = '#181A1F' },
        hl_sel = { fg = '#abb2bf', bg = '#282c34' },
        hl_fill = { fg = '#ffffff', bg = '#000000' },
    }
    ]]--
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- bufferline {{{------------------------------------------------------------------------------------------------
    require'bufferline'.setup{
        options = {
            mode = 'tabs',
            right_mouse_command = nil,
            tab_size = 32,
            max_name_length = 32,
            max_prefix_length = 0,
            name_formatter = function(buf)
                return require'lua/utils'.shorten_relative_path(buf.path, 32)
            end,
            diagnostics = 'nvim_lsp',
            diagnostics_indicator = function(count, level, diagnostics_dict, context)
                local s = ' '
                for e, n in pairs(diagnostics_dict) do
                    local sym = e == 'error' and ' ' or (e == 'warning' and ' ' or '' )
                    s = s .. n .. sym
                end
                return s
            end,
            close_icon = '',
            buffer_close_icon = '',
            sort_by = 'tabs',
            offsets = {
                {
                    filetype = 'NvimTree',
                    text = function()
                        return require'lua/utils'.shorten_path(vim.fn.getcwd(), 20)
                    end,
                    highlight = 'Directory',
                    text_align = 'left',
                }
            }
        }
    }
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- statusline: galaxyline {{{------------------------------------------------------------------------------------
    local gl = require('galaxyline')
    local utils = require('lua/utils')

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
    local buffer_not_empty = function() return not utils.is_buffer_empty() end

    local checkwidth = function()
        return utils.has_width_gt(40) and buffer_not_empty()
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

        mode_color = mode_colors[vim.fn.mode():byte()]
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

    local asyncrun_status = {
        ['running'] = true,
        ['success'] = true,
        ['failure'] = true,
    }

    -- Left side
    gls.left[1] = {
        ViMode = {
            provider = function()
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
                vim.api.nvim_command('hi GalaxyViMode guibg=' .. mode_color())
                alias = aliases[vim.fn.mode():byte()]
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
    gls.left[9] = {
        DiagnosticError = {
            provider = 'DiagnosticError',
            icon = '  ',
            highlight = {colors.red1, colors.bg}
        }
    }
    gls.left[10] = {
        Space = {
            provider = function() return ' ' end,
            highlight = {colors.section_bg, colors.bg}
        }
    }
    gls.left[11] = {
        DiagnosticWarn = {
            provider = 'DiagnosticWarn',
            icon = '  ',
            highlight = {colors.orange, colors.bg}
        }
    }
    gls.left[12] = {
        Space = {
            provider = function() return ' ' end,
            highlight = {colors.section_bg, colors.bg}
        }
    }
    gls.left[13] = {
        DiagnosticInfo = {
            provider = 'DiagnosticInfo',
            icon = '  ',
            highlight = {colors.blue, colors.section_bg},
            separator = ' ',
            separator_highlight = {colors.section_bg, colors.bg}
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
            provider = function() return '  ' end,
            condition = buffer_not_empty and
            require('galaxyline.provider_vcs').check_git_workspace,
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
        AsyncRun = {
            provider = function() return vim.g.asyncrun_status .. ' ' end,
            condition = function()
                if vim.fn.empty(vim.g['asyncrun_status']) ~= 1 then
                    return true
                end
                return false
            end,
            icon = '  ',
            separator = '',
            separator_highlight = { colors.red1, colors.bg },
            highlight = { colors.gray2, colors.red1 },
            event = { 'AsyncRunPre', 'AsyncRunStart', 'AsyncRunStop' },
        }
    }
    gls.right[8] = {
        CursorPos = {
            provider = function()
                local _, line, col, _, colwanted = unpack(vim.fn.getcurpos())
                return line .. ',' .. col .. ' '
            end,
            icon = '   ',
            highlight = { colors.gray2, colors.purple },
        }
    }
    gls.right[9] = {
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
    --}}}---------------------------------------------------------------------------------------------------------------
end

return M
