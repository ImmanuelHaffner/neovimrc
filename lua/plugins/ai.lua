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
        build = "cd ~/.local && npm install mcp-hub@latest",  -- Installs `mcp-hub` node binary globally
        config = function()
            require("mcphub").setup()
        end
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
            local cc = require'codecompanion'
            cc.setup{
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
                        tools = {
                            opts = {
                                auto_submit_errors = true, -- Send any errors to the LLM automatically?
                                auto_submit_success = true, -- Send any successful output to the LLM automatically?
                                default_tools = {
                                    'read_file',
                                    'grep_search',
                                    'file_search',
                                    'mcp',
                                },
                            },
                        },
                        opts = {
                            ---Decorate the user message before it's sent to the LLM
                            ---@param message string
                            ---@param adapter CodeCompanion.Adapter
                            ---@param context table
                            ---@return string
                            prompt_decorator = function(message, adapter, context)
                                local prompt = string.format([[<prompt>%s</prompt>]], message)

                                -- Automatically add some useful variables and tools.
                                if not context.initialized then
                                    context.initialized = true
                                    prompt = prompt
                                    .. [[ #{neovim://buffer}]]
                                end

                                return prompt
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

            -- Get the plugin root directory
            local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h:h')
            -- Read the default system prompt.
            local prompt_path = plugin_root .. '/assets/code-companion-system-prompt.md'
            local default_system_prompt = table.concat(vim.fn.readfile(prompt_path), '\n')

            -- Check for `.github/copilot-instructions.md` file or `.cursor/rules` directory on directory change and
            -- update system prompt.
            vim.api.nvim_create_autocmd('DirChanged', {
                pattern = '*',
                callback = function()
                    local copilot_instructions = '.github/copilot-instructions.md'
                    if vim.fn.filereadable(copilot_instructions) == 1 then
                        local prompt_content = table.concat(vim.fn.readfile(copilot_instructions), '\n')
                        local new_system_prompt = default_system_prompt .. '\n\n' .. prompt_content
                        require'codecompanion.config'.opts.system_prompt = function()
                            return new_system_prompt
                        end
                        vim.notify(
                            'CodeCompanion system prompt updated from \'.github/copilot-instructions.md\'',
                            vim.log.levels.INFO)
                        return
                    end

                    -- Check if the directory exists
                    local cursor_rules_dir = '.cursor/rules'
                    if vim.fn.isdirectory(cursor_rules_dir) == 1 then
                        local loaded_files = {}
                        local mdc_files = vim.fn.glob(cursor_rules_dir .. '/*.mdc', false, true)

                        if #mdc_files == 0 then return end

                        -- Read all .mdc files and combine their content
                        for _, file_path in ipairs(mdc_files) do
                            local lines = vim.fn.readfile(file_path)
                            local line_itr = next(lines, nil)
                            if line_itr ~= '---' then
                                goto continue  -- file has no header, skip
                            end
                            line_itr = next(lines, line_itr)

                            local apply = false
                            while line_itr and line_itr ~= '---' do
                                if line_itr == 'alwaysApply: true' then
                                    apply = true
                                end
                                line_itr = next(lines, line_itr)
                            end
                            if not apply then
                                goto continue
                            end

                            table.insert(loaded_files, file_path)
                            ::continue::
                        end

                        -- Read all .mdc files and combine their content
                        local new_system_prompt = default_system_prompt
                        for _, file_path in ipairs(loaded_files) do
                            local prompt_content = table.concat(vim.fn.readfile(file_path), '\n')
                            new_system_prompt = new_system_prompt .. '\n\n' .. prompt_content
                        end

                        -- Update CodeCompanion system prompt
                        require'codecompanion.config'.opts.system_prompt = function()
                            return new_system_prompt
                        end

                        vim.notify(
                            'CodeCompanion system prompt updated from \'' .. table.concat(loaded_files, '\', ') .. '\''
                            , vim.log.levels.INFO)
                        return
                    end
                end,
            })
        end,
    },
}





