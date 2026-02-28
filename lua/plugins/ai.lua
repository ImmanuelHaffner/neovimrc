return {
    { 'monkoose/neocodeium',
        dependencies = {
            'folke/which-key.nvim',
        },
        enabled = false,
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
        enabled = true,
        cmd = 'Copilot',
        event = 'InsertEnter',
        config = function()
            require'copilot'.setup{}
        end,
    },
    { 'CopilotC-Nvim/CopilotChat.nvim',
        enabled = false,
        dependencies = {
            { 'zbirenbaum/copilot.lua' },
            { 'nvim-lua/plenary.nvim' }, -- for curl, log and async functions
        },
        build = 'make tiktoken', -- Only on MacOS or Linux
        opts = {
            model = 'claude-sonnet-4',
        },
    },
    { 'ravitemer/mcphub.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim',  -- Required for Job and HTTP requests
            'Joakker/lua-json5',
        },
        -- uncomment the following line to load hub lazily
        --cmd = 'MCPHub',  -- lazy load
        build = "cd ~/.local && npm install mcp-hub@latest",
        config = function()
            require("mcphub").setup()
        end
    },
    { 'Davidyz/VectorCode',
        version = '0.7.12', -- optional, depending on whether you're on nightly or release
        enabled = function()
            -- Check whether `vectorcode` binary is executable
            return vim.fn.executable('vectorcode') == 1
        end,
        dependencies = {
            'nvim-lua/plenary.nvim'
        },
        cmd = 'VectorCode', -- if you're lazy-loading VectorCode
        config = function()
            local vc = require'vectorcode'
            vc.setup{
                cli_cmds = {
                    vectorcode = 'vectorcode',
                },
                n_query = 5,
            }
        end
    },
    { 'olimorris/codecompanion.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-treesitter/nvim-treesitter',
            'ravitemer/mcphub.nvim',
            'zbirenbaum/copilot.lua',
            -- 'CopilotC-Nvim/CopilotChat.nvim',
            'folke/which-key.nvim',
            'Davidyz/VectorCode',
        },
        config = function()
            -- Check if Docker service is running (Linux with systemd only)
            local function check_docker_service()
                -- Only check on Linux with systemd
                if vim.fn.has('linux') == 0 or vim.fn.executable('systemctl') == 0 then
                    return
                end

                local result = vim.fn.system('systemctl status docker.service')
                if not string.match(result, 'Active: active %(running%)') then
                    vim.notify(
                        'Warning: Docker service is not running! CodeCompanion features may not work properly.',
                        vim.log.levels.WARN,
                        { title = 'CodeCompanion Check' }
                    )
                end
            end

            -- Run the check when Neovim starts
            check_docker_service()

            --- Returns the default adapter based on available credentials/configuration.
            --- Adapters are checked in priority order; first available one wins.
            --- @return string adapter_name The name of the adapter to use.
            local function get_default_adapter()
                -- Define adapters in priority order (highest priority first).
                -- Each entry specifies:
                --   - name: the adapter name as registered in codecompanion
                --   - is_available: function that returns true if this adapter can be used
                local adapters = {
                    {
                        name = 'databricks',
                        is_available = function()
                            local token = vim.env.DATABRICKS_TOKEN
                            return token ~= nil and token ~= ''
                        end,
                    },
                    -- Future adapters can be added here, e.g.:
                    -- {
                    --     name = 'anthropic',
                    --     is_available = function()
                    --         local key = vim.env.ANTHROPIC_API_KEY
                    --         return key ~= nil and key ~= ''
                    --     end,
                    -- },
                }

                -- Check each adapter in priority order.
                for _, adapter in ipairs(adapters) do
                    if adapter.is_available() then
                        return adapter.name
                    end
                end

                -- Fallback adapter (always available via GitHub auth).
                return 'copilot'
            end

            -- Capture the default system prompt BEFORE setup (to avoid infinite recursion)
            local default_system_prompt_fn = require('codecompanion.config').config.interactions.chat.opts.system_prompt

            -- Load Neovim-specific additions from file
            local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h:h')
            local additions_path = plugin_root .. '/assets/code-companion-neovim-additions.md'
            local neovim_additions = ''
            if vim.fn.filereadable(additions_path) == 1 then
                neovim_additions = table.concat(vim.fn.readfile(additions_path), '\n')
            end

            local cc = require'codecompanion'
            cc.setup{
                adapters = {
                    http = {
                        copilot = function()
                            return require'codecompanion.adapters'.extend('copilot', {
                                schema = {
                                    model = {
                                        default = 'claude-sonnet-4',
                                    },
                                },
                            })
                        end,
                        databricks = function()
                            local openai = require('codecompanion.adapters.http.openai')
                            return require'codecompanion.adapters'.extend('openai_compatible', {
                                env = {
                                    api_key = 'DATABRICKS_TOKEN',
                                },
                                -- Dogfood
                                url = 'https://6051921418418893.ai-gateway.staging.cloud.databricks.com/mlflow/v1/chat/completions',
                                headers = {
                                    ['Content-Type'] = 'application/json',
                                    ['Authorization'] = 'Bearer ${api_key}',
                                },
                                handlers = {
                                    -- Override form_messages to ensure tool_calls have valid function.name
                                    -- and valid JSON arguments.
                                    -- Databricks API strictly validates that:
                                    -- 1. Every tool_calls[].function.name field is present
                                    -- 2. Every tool_calls[].function.arguments is a valid JSON string
                                    form_messages = function(self, messages)
                                        -- Call the base OpenAI form_messages first
                                        local result = openai.handlers.form_messages(self, messages)

                                        -- Helper function to validate and fix JSON arguments
                                        local function ensure_valid_json_args(args)
                                            if args == nil or args == '' then
                                                return '{}'
                                            end
                                            -- Try to parse the JSON to validate it
                                            local ok, _ = pcall(vim.json.decode, args)
                                            if ok then
                                                return args  -- Valid JSON, return as-is
                                            end
                                            -- Invalid JSON - try to salvage by completing truncated JSON
                                            -- Common case: streaming left incomplete object like '{"path": "foo'
                                            -- Count unmatched braces and brackets
                                            local open_braces = 0
                                            local open_brackets = 0
                                            local in_string = false
                                            local escape_next = false
                                            for i = 1, #args do
                                                local c = args:sub(i, i)
                                                if escape_next then
                                                    escape_next = false
                                                elseif c == '\\' and in_string then
                                                    escape_next = true
                                                elseif c == '"' and not escape_next then
                                                    in_string = not in_string
                                                elseif not in_string then
                                                    if c == '{' then open_braces = open_braces + 1
                                                    elseif c == '}' then open_braces = open_braces - 1
                                                    elseif c == '[' then open_brackets = open_brackets + 1
                                                    elseif c == ']' then open_brackets = open_brackets - 1
                                                    end
                                                end
                                            end
                                            -- Try to complete the JSON
                                            local fixed = args
                                            if in_string then
                                                fixed = fixed .. '"'  -- Close unclosed string
                                            end
                                            -- Close any unclosed brackets/braces
                                            for _ = 1, open_brackets do
                                                fixed = fixed .. ']'
                                            end
                                            for _ = 1, open_braces do
                                                fixed = fixed .. '}'
                                            end
                                            -- Verify the fix worked
                                            local ok2, _ = pcall(vim.json.decode, fixed)
                                            if ok2 then
                                                return fixed
                                            end
                                            -- If still invalid, fall back to empty object
                                            return '{}'
                                        end

                                        -- Ensure all tool_calls have function.name and valid arguments
                                        if result and result.messages then
                                            for _, msg in ipairs(result.messages) do
                                                if msg.tool_calls then
                                                    for _, tool_call in ipairs(msg.tool_calls) do
                                                        if tool_call['function'] then
                                                            -- Ensure name is present (use id as fallback if missing)
                                                            if not tool_call['function']['name'] or tool_call['function']['name'] == '' then
                                                                tool_call['function']['name'] = tool_call.id or 'unknown_tool'
                                                            end
                                                            -- Ensure arguments is valid JSON
                                                            tool_call['function']['arguments'] = ensure_valid_json_args(
                                                                tool_call['function']['arguments']
                                                            )
                                                        end
                                                    end
                                                end
                                            end
                                        end

                                        return result
                                    end,
                                    tools = {
                                        -- Override format_tool_calls to fix empty/invalid arguments issue for Databricks API.
                                        -- Databricks requires `arguments` to be a valid JSON string.
                                        format_tool_calls = function(self, tools)
                                            -- Reuse the same JSON validation helper
                                            local function ensure_valid_json_args(args)
                                                if args == nil or args == '' then
                                                    return '{}'
                                                end
                                                local ok, _ = pcall(vim.json.decode, args)
                                                if ok then
                                                    return args
                                                end
                                                -- Try to complete truncated JSON
                                                local open_braces, open_brackets = 0, 0
                                                local in_string, escape_next = false, false
                                                for i = 1, #args do
                                                    local c = args:sub(i, i)
                                                    if escape_next then
                                                        escape_next = false
                                                    elseif c == '\\' and in_string then
                                                        escape_next = true
                                                    elseif c == '"' and not escape_next then
                                                        in_string = not in_string
                                                    elseif not in_string then
                                                        if c == '{' then open_braces = open_braces + 1
                                                        elseif c == '}' then open_braces = open_braces - 1
                                                        elseif c == '[' then open_brackets = open_brackets + 1
                                                        elseif c == ']' then open_brackets = open_brackets - 1
                                                        end
                                                    end
                                                end
                                                local fixed = args
                                                if in_string then fixed = fixed .. '"' end
                                                for _ = 1, open_brackets do fixed = fixed .. ']' end
                                                for _ = 1, open_braces do fixed = fixed .. '}' end
                                                local ok2, _ = pcall(vim.json.decode, fixed)
                                                if ok2 then return fixed end
                                                return '{}'
                                            end

                                            for _, tool in ipairs(tools) do
                                                if tool['function'] then
                                                    -- Ensure name is present
                                                    if not tool['function']['name'] or tool['function']['name'] == '' then
                                                        tool['function']['name'] = tool.id or 'unknown_tool'
                                                    end
                                                    -- Ensure arguments is valid JSON
                                                    tool['function']['arguments'] = ensure_valid_json_args(
                                                        tool['function']['arguments']
                                                    )
                                                end
                                            end
                                            return tools
                                        end,
                                        output_response = function(self, tool_call, output)
                                            return openai.handlers.tools.output_response(self, tool_call, output)
                                        end,
                                    },
                                },
                                schema = {
                                    model = {
                                        default = 'databricks-claude-opus-4-5',
                                        choices = {
                                            'databricks-claude-opus-4-5',
                                            'databricks-claude-opus-4-6',
                                            'databricks-claude-sonnet-4-5',
                                            'databricks-gpt-5-2',
                                            'databricks-gpt-5-1-codex-max',
                                        },
                                    },
                                },
                            })
                        end
                    }
                },
                strategies = {
                    chat = {
                        adapter = get_default_adapter(),
                        tools = {
                            -- The `memory` tool needs no approval.
                            ['memory'] = {
                                opts = {
                                    require_approval_before = false,
                                },
                            },
                            -- editor_context tool is registered via the nvu.editor_context extension
                            opts = {
                                auto_submit_errors = true, -- Send any errors to the LLM automatically?
                                auto_submit_success = true, -- Send any successful output to the LLM automatically?
                                default_tools = {
                                    'memory',
                                    'neovim',  -- all tools from the Neovim MCP server
                                    'editor_context',  -- provide context on open buffers, cursor pos, active buffer
                                },
                            },
                            groups = {
                                ['dev'] = {
                                    description = "Default developer setup",
                                    tools = {
                                        'read_file',
                                        'file_search',
                                        'grep_search',
                                        'editor_context',  -- custom tool for editor state
                                        'neovim',  -- all tools from the Neovim MCP server
                                    },
                                    opts = {
                                        collapse_tools = false, -- When true, show as a single group reference instead of individual tools
                                    },
                                },
                            },
                        },
                        opts = {
                            ---Extend the default system prompt with Neovim-specific additions
                            ---@param opts table Options passed by CodeCompanion (contains language, etc.)
                            ---@return string
                            system_prompt = function(opts)
                                -- Use the captured default prompt (avoids infinite recursion)
                                local base_prompt = type(default_system_prompt_fn) == 'function'
                                    and default_system_prompt_fn(opts)
                                    or (default_system_prompt_fn or '')

                                return base_prompt .. '\n' .. neovim_additions
                            end,

                            ---Decorate the user message before it's sent to the LLM
                            ---@param message string
                            ---@param _ CodeCompanion.Adapter
                            ---@param _ table
                            ---@return string
                            prompt_decorator = function(message, _, _)
                                local prompt = string.format([[<prompt>%s</prompt>]], message)
                                return prompt
                            end,
                        },
                    },
                    inline = {
                        adapter = get_default_adapter(),
                    },
                    cmd = {
                        adapter = get_default_adapter(),
                    }
                },
                ui = {
                    chat_window = {
                        filetype = 'markdown', -- Set the chat window filetype to Markdown
                        syntax_highlighting = true, -- Enable syntax highlighting
                    },
                },
                display = {
                    action_palette = {
                        opts = {
                            show_default_actions = true,
                        }
                    },

                    chat = {
                        show_token_count = true,
                        show_settings = false,  -- when `true` prevents changing adapter/model

                        --- Customize how tokens are displayed
                        --- @param tokens number
                        --- @param _ CodeCompanion.Adapter
                        --- @return string
                        token_count = function(tokens, _)
                            return ' (' .. tokens .. ' tokens)'
                        end,
                    },
                },
                prompt_library = {
                    markdown = {
                        dirs = {
                            function() return vim.fn.getcwd() .. '/.prompts' end,  -- Project-specific prompts
                            '~/.config/nvim/prompts',                              -- Global prompts
                        },
                    },
                },
                extensions = {
                    -- Editor context extension from nvu library (provides #editor variable and editor_context tool)
                    editor_context = {
                        callback = 'codecompanion._extensions.editor_context',
                        opts = {
                            require_approval_before = false,  -- This is a read-only tool, no approval needed
                        },
                    },
                    mcphub = {
                        callback = 'mcphub.extensions.codecompanion',
                        opts = {
                            make_vars = true,
                            make_slash_commands = true,
                            show_result_in_chat = true,
                        }
                    },
                    vectorcode = vim.fn.executable('vectorcode') == 1 and {
                        ---@type VectorCode.CodeCompanion.ExtensionOpts
                        opts = {
                            tool_group = {
                                -- this will register a tool group called `@vectorcode_toolbox` that contains all 3 tools
                                enabled = true,
                                -- a list of extra tools that you want to include in `@vectorcode_toolbox`.
                                -- if you use @vectorcode_vectorise, it'll be very handy to include
                                -- `file_search` here.
                                extras = {
                                    'read_file',
                                    'file_search',
                                    'grep_search',
                                },
                                collapse = false, -- whether the individual tools should be shown in the chat
                            },
                            tool_opts = {
                                ---@type VectorCode.CodeCompanion.ToolOpts
                                ["*"] = {},
                                ---@type VectorCode.CodeCompanion.LsToolOpts
                                ls = {},
                                ---@type VectorCode.CodeCompanion.VectoriseToolOpts
                                vectorise = {},
                                ---@type VectorCode.CodeCompanion.QueryToolOpts
                                query = {
                                    max_num = { chunk = -1, document = -1 },
                                    default_num = { chunk = 50, document = 10 },
                                    include_stderr = false,
                                    use_lsp = false,
                                    no_duplicate = true,
                                    chunk_mode = false,
                                    ---@type VectorCode.CodeCompanion.SummariseOpts
                                    summarise = {
                                        ---@type boolean|(fun(chat: CodeCompanion.Chat, results: VectorCode.QueryResult[]):boolean)|nil
                                        enabled = false,
                                        adapter = nil,
                                        query_augmented = true,
                                    }
                                },
                                files_ls = {},
                                files_rm = {}
                            }
                        },
                    } or nil,
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

            local cc_group = vim.api.nvim_create_augroup('CodeCompanionHooks', {})

            -- Automatically attach current buffer to new chat
            vim.api.nvim_create_autocmd('User', {
                pattern = 'CodeCompanionChatCreated',
                group = cc_group,
                callback = function(request)
                    -- Render output nicely as Markdown
                    vim.treesitter.start(request.buf, 'markdown')
                    vim.wo.colorcolumn = ''
                end,
            })
        end,
    },
}






