return {
    { 'folke/noice.nvim',
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
        opts = {
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
                -- NOTE: If you enable messages, then the cmdline is enabled automatically.  This is a current Neovim
                -- limitation.
                enabled = true, -- enables the Noice messages UI
                view = 'mini', -- default view for messages
                view_error = 'mini', -- view for errors
                view_warn = 'mini', -- view for warnings
                view_history = 'messages', -- view for :messages
                view_search = 'virtualtext', -- view for search count messages. Set to `false` to disable
            },
            routes = {
                {
                    filter = {
                        event = 'msg_show',
                        kind = '',
                        find = 'written',
                    },
                    opts = { skip = true },
                },
                {
                    filter = {
                        event = 'msg_show',
                        kind = 'search_count',
                    },
                    opts = { skip = true },
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
                        padding = { 0, 1 },
                    },
                },
                mini = {
                    timeout = 6000,
                    position = {
                        row = -2,
                        col = '100%',
                    },
                    border = {
                        style = 'rounded',
                        padding = { 0, 2, 0, 0 },
                    },
                    zindex = 1000,
                },
            },
        },
    },
}
