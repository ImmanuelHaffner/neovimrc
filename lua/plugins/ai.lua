return {
    { 'monkoose/neocodeium',
        dependencies = {
            'folke/which-key.nvim',
        },
        event = 'VeryLazy',
        config = function()
            local neocodeium = require'neocodeium'
            neocodeium.setup{
                enabled = false,  -- don't enable by default
                filetypes = {
                    TelescopePrompt = false,
                    ["dap-repl"] = false,
                },
            }

            local cmd = require'neocodeium.commands'
            require'which-key'.add{
                { '<leader>a', group = 'AI Tools' },
                { '<leader>an', group = 'NeoCodeium' },
                { '<leader>ant', cmd.toggle, desc = 'Toggle NeoCodeium globally' },
                { '<leader>anb', cmd.toggle_buffer, desc = 'Toggle NeoCodeium for current buffer' },
                { '<leader>anc', neocodeium.chat, desc = 'NeoCodeium chat' },
            }

            vim.keymap.set("i", "<A-a>", function()
                require("neocodeium").accept()
            end)
            vim.keymap.set("i", "<A-w>", function()
                require("neocodeium").accept_word()
            end)
            vim.keymap.set("i", "<A-l>", function()
                require("neocodeium").accept_line()
            end)
            vim.keymap.set("i", "<A-n>", function()
                require("neocodeium").cycle_or_complete()
            end)
            vim.keymap.set("i", "<A-p>", function()
                require("neocodeium").cycle_or_complete(-1)
            end)
            vim.keymap.set("i", "<A-c>", function()
                require("neocodeium").clear()
            end)
        end,
    },
    { 'zbirenbaum/copilot.lua',
        cmd = 'Copilot',
        event = 'InsertEnter',
        config = function()
            require'copilot'.setup{}
        end,
    },
    { 'CopilotC-Nvim/CopilotChat.nvim',
        dependencies = {
            { 'zbirenbaum/copilot.lua' },
            { 'nvim-lua/plenary.nvim' }, -- for curl, log and async functions
        },
        build = 'make tiktoken', -- Only on MacOS or Linux
        opts = {
            model = 'claude-3.7-sonnet',
        },
    },
    { 'ravitemer/mcphub.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim',  -- Required for Job and HTTP requests
        },
        -- uncomment the following line to load hub lazily
        --cmd = 'MCPHub',  -- lazy load
        -- build = 'npm install mcp-hub@latest',  -- Installs required mcp-hub npm module
        -- uncomment this if you don't want mcp-hub to be available globally or can't use -g
        build = 'bundled_build.lua',  -- Use this and set use_bundled_binary = true in opts  (see Advanced configuration)
        config = function()
            require'mcphub'.setup{
                use_bundled_binary = true,
            }
        end,
    },
    { 'olimorris/codecompanion.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-treesitter/nvim-treesitter',
            'ravitemer/mcphub.nvim',
            'zbirenbaum/copilot.lua',
            'CopilotC-Nvim/CopilotChat.nvim',
            'folke/which-key.nvim',
        },
        config = function()
            require'codecompanion'.setup{
                adapters = {
                    copilot = function()
                        return require'codecompanion.adapters'.extend('copilot', {
                            schema = {
                                model = {
                                    default = 'claude-3.7-sonnet',
                                },
                            },
                        })
                    end
                },
                strategies = {
                    chat = {
                        adapter = 'copilot',
                        variables = {},
                        opts = {
                            ---Decorate the user message before it's sent to the LLM
                            ---@param message string
                            ---@param adapter CodeCompanion.Adapter
                            ---@param context table
                            ---@return string
                            prompt_decorator = function(message, adapter, context)
                                return string.format([[<prompt>%s</prompt>]], message)
                            end,
                        },
                    },
                    inline = {
                        adapter = 'copilot',
                    },
                    cmd = {
                        adapter = 'copilot',
                    }
                },
                ui = {
                    chat_window = {
                        filetype = 'markdown', -- Set the chat window filetype to Markdown
                        syntax_highlighting = true, -- Enable syntax highlighting
                    },
                },
                extensions = {
                    mcphub = {
                        callback = 'mcphub.extensions.codecompanion',
                        opts = {
                            make_vars = true,
                            make_slash_commands = true,
                            show_result_in_chat = true,
                        }
                    }
                }
            }

            local wk = require'which-key'
            wk.add{
                { '<leader>ac', group = 'CodeCompanion…' },
                { '<leader>aca', '<cmd>CodeCompanionActions<cr>', desc = 'Actions' },
                { '<leader>act', '<cmd>CodeCompanionChat Toggle<cr>', desc = 'Toggle Chat' },
                { '<leader>acc', ':CodeCompanionCmd ', desc = 'Prompt command', silent = false, },
                { '<leader>ace', '<cmd>CodeCompanion /explain<cr>', desc = 'Explain' },
            }

            wk.add{
                mode = { 'v' },
                { '<C-e>', '<cmd>CodeCompanion /explain<cr>', desc = 'Explain' },
            }

            -- Render output nicely as Markdown
            vim.api.nvim_create_autocmd('FileType', {
                pattern = 'codecompanion',
                callback = function(args)
                    vim.treesitter.start(args.buf, 'markdown')
                end,
            })
        end,
    },
}
