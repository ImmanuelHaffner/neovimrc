return {
    { 'folke/noice.nvim',
        tag = 'v4.10.0',
        event = 'VeryLazy',
        dependencies = {
            -- if you lazy-load any plugin below, make sure to add proper `module='...'` entries
            'MunifTanjim/nui.nvim',
            -- OPTIONAL:
            --   `nvim-notify` is only needed, if you want to use the notification view.
            --   If not available, we use `mini` as the fallback
            'rcarriga/nvim-notify',
            'hrsh7th/nvim-cmp',
        },
        config = function()
            local msg_width = 60

            -- Set up autocmd to compute width after UI is initialized
            vim.api.nvim_create_autocmd('UIEnter', {
                callback = function()
                    local term_width = vim.o.columns
                    if term_width then
                        if term_width > 4 then
                            msg_width = term_width - 4  -- leave space for border and padding
                        else
                            msg_width = term_width
                        end
                    end
                end,
            })

            require'noice'.setup{
                lsp = {
                    -- override markdown rendering so that **cmp** and other plugins use **Treesitter**
                    override = {
                        ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
                        ['vim.lsp.util.stylize_markdown'] = true,
                        ['cmp.entry.get_documentation'] = true, -- requires hrsh7th/nvim-cmp
                    },
                    signature = {
                        enabled = false,  -- handled by another plugin
                    },
                },
                -- you can enable a preset for easier configuration
                presets = {
                    bottom_search = false, -- use a classic bottom cmdline for search
                    command_palette = false, -- position the cmdline and popupmenu together
                    long_message_to_split = true, -- long messages will be sent to a split
                    inc_rename = false, -- enables an input dialog for inc-rename.nvim
                    lsp_doc_border = true, -- add a border to hover docs and signature help
                },
                messages = {
                    -- NOTE: If you enable messages, then the cmdline is enabled automatically.  This is a current
                    -- Neovim limitation.
                    enabled = true, -- enables the Noice messages UI
                    view = 'messages', -- default view for messages
                    view_error = 'messages', -- view for errors
                    view_warn = 'messages', -- view for warnings
                    view_history = 'messages', -- view for :messages
                    view_search = 'virtualtext', -- view for search count messages. Set to `false` to disable
                },
                routes = {
                    -- Route all confirmation dialogs to the confirm view
                    {
                        filter = {
                            any = {
                                { event = 'msg_show', kind = 'confirm' },
                                { event = 'msg_show', kind = 'confirm_sub' },
                                { event = 'msg_show', kind = 'number_prompt' },
                            },
                        },
                        view = 'confirm',
                    },
                    -- Don't show a message for the "File written" prompt.
                    {
                        filter = {
                            event = 'msg_show',
                            kind = 'bufwrite',
                        },
                        opts = { skip = true },
                    },
                    {
                        filter = {
                            event = 'msg_show',
                            find = 'B written',  -- to match '... 4491L, 184689B written'
                        },
                    },
                    -- Don't show a message for the search match count while searching.
                    {
                        filter = {
                            event = 'msg_show',
                            kind = 'search_count',
                        },
                        opts = { skip = true },
                    },
                    {
                        filter = {
                            event = 'msg_show',
                            kind = 'search_cmd',
                        },
                        opts = { skip = true },
                    },
                    -- Suppress a bunch of errors.
                    --  - Don't show a message when search hits end of file.
                    --  - ltex-ls LSP that we want to silence.
                    --  - Don't show a message when running a command with AsyncRun.
                    {
                        filter = {
                            event = 'msg_show',
                            kind = 'emsg',
                            any = {
                                { find = 'E384:' },  -- wrap scan, reached top of file
                                { find = 'E385:' },  -- wrap scan, reached end of file
                                { find = 'vim.schedule' },
                                { find = 'Running command:' },  -- AsyncRun
                                { find = 'ns=nvim.treesitter.highlighter' },  -- treesitter highlighting error
                            },
                        },
                        opts = { skip = true },
                    },
                    {
                        filter = {
                            event = 'msg_show',
                            kind = 'echomsg',
                            any = {
                                { find = '[lsp-status] Received `end`' },
                                { find = 'Following fonts couldn\'t be loaded:' },
                            },
                        },
                        opts = { skip = true },
                    },
                    {
                        filter = {
                            event = 'msg_show',
                            kind = 'lua_error',
                            any = {
                                { find = 'Invalid buffer id' },
                            },
                        },
                        opts = { skip = true },
                    },
                    {
                        filter = {
                            event = 'msg_show',
                            any = {
                                { find = '%--' },
                            },
                        },
                        opts = { skip = true },
                    },
                    -- Skip warning messages from CodeCompanion
                    {
                        filter = {
                            event = 'notify',
                            find = 'CodeCompanion',
                            warning = true,
                        },
                        opts = { skip = true },
                    },
                    -- Route short warning and error messages to Notify
                    {
                        filter = {
                            event = 'msg_show',
                            any = { { error = true }, { warning = true } },
                            max_height = 3,
                            max_width = msg_width > 12 and (msg_width - 12) or msg_width,  -- account for the 'Error' prefix
                        },
                        view = 'notify',
                    },
                    -- Route short messages in general to mini.
                    {
                        filter = {
                            event = 'msg_show',
                            warning = false,
                            error = false,
                            max_height = 3,
                            max_width = math.floor(.8 * msg_width),
                        },
                        view = 'mini',
                    },
                    -- Preserve short notifications to go to notify
                    {
                        filter = {
                            event = 'notify',
                            max_height = 3,
                            max_width = msg_width,  -- account for the 'Error' prefix
                        },
                        view = 'notify',
                    },
                },
                views = {
                    cmdline_popup = {
                        relative = 'editor',
                        position = {
                            row = 10,
                            col = '50%',
                        },
                        size = {
                            width = '60%',
                            height = 'auto',
                        },
                        zindex = 9999,  -- must be the absolute top
                    },
                    popupmenu = {
                        relative = 'editor',
                        position = {
                            row = 12,
                            col = '50%',
                        },
                        size = {
                            width = '60%',
                            height = 'auto',
                        },
                        win_options = {
                            winbar = '',
                            foldenable = false,
                            cursorline = true,
                            cursorlineopt = 'line',
                            winhighlight = {
                                Normal = 'NormalFloat', -- change to NormalFloat to make it look like other floats
                                FloatBorder = 'NoiceCmdlinePopupBorder', -- border highlight
                                CursorLine = 'NoicePopupmenuSelected', -- used for highlighting the selected item
                                PmenuMatch = 'NoicePopupmenuMatch', -- used to highlight the part of the item that matches the input
                            },
                        },
                        border = {
                            padding = { 0, 2 },
                            style = 'single',
                        },
                        zindex = 9999,  -- must be the absolute top
                    },
                    mini = {
                        timeout = 6000,  -- in ms
                        position = {
                            row = -2,
                            col = '100%',
                        },
                        border = {
                            style = 'rounded',
                            padding = { 0, 3, 0, -1 },
                        },
                        zindex = 80,
                    },
                    messages = {
                        enter = false,  -- show messages but preserve cursor position and focus
                    },
                },
            }
        end,
    },
}

