return {
    {
        'monkoose/neocodeium',
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
    {
        'zbirenbaum/copilot.lua',
        enabled = false,
        cmd = 'Copilot',
        event = 'InsertEnter',
        config = function()
            require'copilot'.setup{}
        end,
    },
    {
        'CopilotC-Nvim/CopilotChat.nvim',
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
    {
        -- TODO: Switch back to 'ravitemer/mcphub.nvim' once PR #279 is merged:
        --       https://github.com/ravitemer/mcphub.nvim/pull/279
        --       This fork adds CodeCompanion v19 compatibility (tool cmd signature,
        --       variables→editor_context rename, output handler changes, image API).
        'bahaaza/mcphub.nvim',
        commit = 'f94e1c8e1aea68c3f8f6df5cf51c752033584fd0',
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
    {
        'Davidyz/VectorCode',
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
    {
        'ImmanuelHaffner/codecompanion.nvim',
        dev = true,
        branch = 'dev',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-treesitter/nvim-treesitter',
            'bahaaza/mcphub.nvim',  -- TODO: switch back to 'ravitemer/mcphub.nvim' after PR #279 merged
            -- 'zbirenbaum/copilot.lua',
            -- 'CopilotC-Nvim/CopilotChat.nvim',
            'folke/which-key.nvim',
            -- 'Davidyz/VectorCode',
        },
        config = function()
            -- Databricks AI Gateway URL (used by both OpenAI-compatible and Anthropic adapters)
            local DATABRICKS_AI_GATEWAY_URL = 'https://6051921418418893.ai-gateway.staging.cloud.databricks.com'

            --- Validate and fix JSON arguments for tool calls.
            --- Databricks API strictly validates that tool_calls[].function.arguments is valid JSON.
            --- Streaming can produce truncated JSON, so we attempt to complete it.
            ---@param args string|nil The JSON arguments string to validate
            ---@return string Valid JSON string (empty object '{}' if input is nil/empty/unfixable)
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
                        name = 'Databricks Anthropic',
                        is_available = function()
                            local key = vim.env.DATABRICKS_ANTHROPIC_API_KEY
                            return key ~= nil and key ~= ''
                        end,
                    },
                    {
                        name = 'Databricks FMAPI (Anthropic)',
                        is_available = function()
                            local token = vim.env.DATABRICKS_AI_GATEWAY_TOKEN
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
                        -- Databricks Anthropic adapter (connects directly to Anthropic API)
                        ['Databricks Anthropic'] = function()
                            return require'codecompanion.adapters'.extend('anthropic', {
                                formatted_name = 'Databricks Anthropic',
                                env = {
                                    api_key = 'DATABRICKS_ANTHROPIC_API_KEY',
                                },
                                headers = {
                                    -- Enable extended context (1M tokens) via beta header
                                    ['anthropic-beta'] = 'prompt-caching-2024-07-31,context-1m-2025-08-07',
                                },
                                schema = {
                                    model = {
                                        default = 'claude-opus-4-6',
                                        choices = {
                                            ['claude-sonnet-4-5'] = {
                                                formatted_name = 'Claude Sonnet 4.5',
                                                opts = { can_reason = true, has_vision = true },
                                            },
                                            ['claude-opus-4-5'] = {
                                                formatted_name = 'Claude Opus 4.5',
                                                opts = { can_reason = true, has_vision = true },
                                            },
                                            ['claude-opus-4-6'] = {
                                                formatted_name = 'Claude Opus 4.6',
                                                opts = { can_reason = true, has_vision = true },
                                            },
                                        },
                                    },
                                    thinking_budget = { default = 32000 },
                                    max_tokens = { default = 64000 },
                                },
                            })
                        end,
                        -- Databricks FMAPI adapter for Anthropic models via OpenAI-compatible endpoint
                        ['Databricks FMAPI (Anthropic)'] = function()
                            local openai = require('codecompanion.adapters.http.openai')
                            return require'codecompanion.adapters'.extend('openai_compatible', {
                                formatted_name = 'Databricks FMAPI (Anthropic)',
                                env = {
                                    api_key = 'DATABRICKS_AI_GATEWAY_TOKEN',
                                },
                                url = DATABRICKS_AI_GATEWAY_URL .. '/mlflow/v1/chat/completions',
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
                                body = {
                                    -- Opt-in to Anthropic's large context window (up to 1M tokens)
                                    -- Ref: https://docs.anthropic.com/en/docs/build-with-claude/extended-context
                                    anthropic_beta = { 'context-1m-2025-08-07' },
                                },
                                schema = {
                                    model = {
                                        default = 'databricks-claude-opus-4-6',
                                        choices = {
                                            ['databricks-claude-opus-4-6'] = {
                                                formatted_name = 'Claude Opus 4.6',
                                            },
                                            ['databricks-claude-opus-4-5'] = {
                                                formatted_name = 'Claude Opus 4.5',
                                            },
                                            ['databricks-claude-sonnet-4-5'] = {
                                                formatted_name = 'Claude Sonnet 4.5',
                                            },
                                        },
                                    },
                                },
                            })
                        end
                    }
                },
                interactions = {
                    chat = {
                        adapter = get_default_adapter(),
                        keymaps = {
                            close = {
                                modes = {
                                    n = '<C-c>',
                                    i = '<C-c>',
                                },
                                index = 4,
                                callback = function(chat)
                                    local choice = vim.fn.confirm('Close this chat?', '&Yes\n&No', 2, 'Question')
                                    if choice ~= 1 then return end
                                    -- Signal to BufUnload guard that this is a legitimate close
                                    vim.b[chat.bufnr]._cc_closing = true
                                    chat:close()
                                    local chats = require('codecompanion').buf_get_chat()
                                    if vim.tbl_count(chats) == 0 then return end
                                    local window_opts = chat.ui.window_opts or { default = true }
                                    chats[1].chat.ui:open({ window_opts = window_opts })
                                end,
                                description = '[Chat] Close (with confirmation)',
                            },
                        },
                        tools = {
                            -- The `memory` tool needs no approval.
                            ['memory'] = {
                                opts = {
                                    require_approval_before = false,
                                },
                            },
                            -- neovim_context tool is registered via the nvu.editor_context extension
                            opts = {
                                auto_submit_errors = true, -- Send any errors to the LLM automatically?
                                auto_submit_success = true, -- Send any successful output to the LLM automatically?
                                default_tools = {
                                    'memory',
                                    'neovim',  -- all tools from the Neovim MCP server
                                    'neovim_context',  -- provide context on open buffers, cursor pos, active buffer
                                },
                            },
                            groups = {
                                ['dev'] = {
                                    description = "Default developer setup",
                                    tools = {
                                        'read_file',
                                        'file_search',
                                        'grep_search',
                                        'neovim_context',  -- custom tool for editor state
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
                    },
                    background = {
                        adapter = get_default_adapter(),
                        chat = {
                            opts = {
                                enabled = true,  -- enable background chat actions (e.g. auto-title generation)
                            },
                        },
                    },
                },
                display = {
                    action_palette = {
                        opts = {
                            show_preset_actions = true,
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
                    -- Neovim context extension from nvu library (provides #neovim_context variable and neovim_context tool)
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
                            show_server_tools_in_chat = false,  -- Hide individual MCP tools from @ completion; use groups instead
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

            -- Use vertical layout for the action palette so the preview gets more space.
            -- Supply a custom previewer that:
            --   1. Attaches markview with hybrid_mode disabled (markview's own OptionSet autocmd
            --      attaches with the global default hybrid_mode=true; our FileType autocmd in
            --      markdown.lua can't override it because the buffer isn't in the preview window
            --      yet when FileType fires — Telescope schedules win_set_buf asynchronously)
            --   2. Sets wrap=true on the preview window for readable markdown
            local ok_tp, telescope_provider = pcall(require, 'codecompanion.providers.actions.telescope')
            if ok_tp then
                local previewers = require('telescope.previewers')

                --- Attach markview to a Telescope preview buffer with hybrid_mode disabled.
                ---@param bufnr integer
                local function markview_attach_preview(bufnr)
                    if not vim.api.nvim_buf_is_valid(bufnr) then return end
                    local has_mv, mv_actions = pcall(require, 'markview.actions')
                    if not has_mv then return end
                    local mv_state = require('markview.state')
                    if mv_state.buf_attached(bufnr) then
                        mv_state.set_buffer_state(bufnr, { enable = true, hybrid_mode = false })
                        mv_actions.render(bufnr)
                    else
                        mv_actions.attach(bufnr, { enable = true, hybrid_mode = false })
                    end
                end

                local action_previewer = previewers.new_buffer_previewer({
                    define_preview = function(self, entry)
                        local width = vim.api.nvim_win_get_width(self.state.winid) - 4
                        entry.preview_command(entry, self.state.bufnr, width)
                        vim.bo[self.state.bufnr].filetype = 'markdown'
                        -- Markview's OptionSet autocmd fires synchronously from the filetype
                        -- assignment above and attaches with the global hybrid_mode=true default.
                        -- Override to hybrid_mode=false so the CursorLine is fully concealed.
                        markview_attach_preview(self.state.bufnr)
                        -- Telescope sets wrap=false on every preview window; override for markdown.
                        -- After enabling wrap we must re-render markview so it recalculates
                        -- virtual text / concealment for the new wrap state.
                        vim.schedule(function()
                            if self.state and self.state.winid and vim.api.nvim_win_is_valid(self.state.winid) then
                                vim.wo[self.state.winid].wrap = true
                                markview_attach_preview(self.state.bufnr)
                            end
                        end)
                    end,
                })

                local original_picker = telescope_provider.picker
                function telescope_provider:picker(items, opts)
                    opts = vim.tbl_deep_extend('force', opts or {}, {
                        layout_strategy = 'vertical',
                        layout_config = {
                            width = math.max(80, math.min(200, math.floor(vim.o.columns * 0.7))),
                            preview_height = 0.7,
                        },
                        previewer = action_previewer,
                    })
                    -- Defer picker creation so that any in-flight Telescope cleanup
                    -- (e.g. scheduled prompt buffer deletion from a parent picker's
                    -- unmount) completes before the new picker opens.  Without this,
                    -- the deferred buf_delete of the first picker can reset the mode
                    -- after the second picker's feedkeys('A') has already run.
                    local provider = self
                    vim.schedule(function()
                        original_picker(provider, items, opts)
                    end)
                end
            end

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

            -- Strip expensive nvim-cmp sources from CodeCompanion chat buffers.
            -- cmp-buffer's on_lines watcher re-indexes the full buffer on every
            -- text change → extreme lag during LLM streaming in large (10k+
            -- line) chats.  CC's cmp provider registers a FileType autocmd
            -- (cmp/setup.lua) that calls cmp.setup.filetype('codecompanion', ...)
            -- with all global sources appended.  We counter this with our own
            -- deferred FileType autocmd that strips everything except CC's own
            -- sources (the `/`, `@`, `#` trigger-character sources still work).
            do
                local cmp_ok, cmp = pcall(require, 'cmp')
                if cmp_ok then
                    -- Hardcode the CC-native source names so we never depend on
                    -- reading back a filetype config that another autocmd may not
                    -- have populated yet (race during session restore, lazy load,
                    -- or when CC's one-shot FileType autocmd has already self-removed).
                    local cc_only_sources = {
                        { name = 'codecompanion_acp_commands' },
                        { name = 'codecompanion_editor_context' },
                        { name = 'codecompanion_models' },
                        { name = 'codecompanion_slash_commands' },
                        { name = 'codecompanion_tools' },
                    }
                    vim.api.nvim_create_autocmd('FileType', {
                        group = cc_group,
                        pattern = 'codecompanion',
                        callback = function()
                            -- Defer so CC's own FileType autocmd (which appends
                            -- global sources like buffer/lsp) runs first; we then
                            -- overwrite with only the CC-native sources.
                            vim.schedule(function()
                                cmp.setup.filetype('codecompanion', {
                                    sources = cc_only_sources,
                                })
                            end)
                        end,
                        desc = 'Strip expensive cmp sources from CodeCompanion chat buffers',
                    })
                end
            end

            --- Disable expensive rendering on CodeCompanion chat buffers.
            --- Stops treesitter highlighting and the underlying parser, and
            --- disables markview at the state level.
            --- See: https://github.com/olimorris/codecompanion.nvim/issues/552
            ---
            --- Performance context (measured on a 2800-line chat buffer):
            ---   TS full reparse with injections: ~36ms (scales to ~300ms at 10k lines)
            ---   Markview enable + render:        ~45ms (scales similarly)
            local function disable_chat_rendering(bufnr)
                bufnr = bufnr or vim.api.nvim_get_current_buf()
                -- Stop treesitter highlighting
                if vim.treesitter.highlighter.active[bufnr] then
                    vim.treesitter.stop(bufnr)
                end
                -- Destroy the TS parser so its on_bytes callback doesn't maintain a
                -- (growing and ultimately stale) parse tree during long streaming sessions.
                -- vim.treesitter.start() will recreate it when re-enabling.
                local ok_parser, parser = pcall(vim.treesitter.get_parser, bufnr)
                if ok_parser and parser and parser.destroy then
                    parser:destroy()
                end
                -- Disable markview at the state level so its autocmds early-return
                local has_mv, mv_actions = pcall(require, 'markview.actions')
                if has_mv then
                    mv_actions.disable(bufnr)
                end
            end

            --- Re-enable rendering after LLM streaming or insert mode ends.
            --- Staggers re-enables: TS highlighting first (lets the highlighter
            --- lazily parse only the visible range), then markview after a short
            --- defer so the UI unblocks between the two expensive operations.
            local function enable_chat_rendering(bufnr)
                bufnr = bufnr or vim.api.nvim_get_current_buf()
                vim.schedule(function()
                    if not vim.api.nvim_buf_is_valid(bufnr) then return end
                    -- Re-enable treesitter highlighting; the highlighter's on_win
                    -- callback will lazily parse only the visible range.
                    vim.treesitter.start(bufnr, 'markdown')
                    -- Defer markview re-enable so the first redraw (with TS) completes
                    -- before markview adds its decorations (~45ms at 2800 lines).
                    vim.defer_fn(function()
                        if not vim.api.nvim_buf_is_valid(bufnr) then return end
                        local has_mv, mv_actions = pcall(require, 'markview.actions')
                        if has_mv then
                            mv_actions.enable(bufnr)
                        end
                    end, 50)
                end)
            end

            -- Disable rendering while LLM is streaming to prevent lag
            vim.api.nvim_create_autocmd('User', {
                pattern = { 'CodeCompanionRequestStarted' },
                group = cc_group,
                callback = function(args)
                    local bufnr = args.data and args.data.bufnr
                    if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
                        vim.b[bufnr]._cc_streaming = true
                        disable_chat_rendering(bufnr)
                        -- Disable undo history during streaming to prevent memory bloat
                        vim.bo[bufnr].undolevels = -1
                    end
                end,
                desc = 'Disable TS/markview during CodeCompanion streaming',
            })

            -- Re-enable rendering after streaming completes
            vim.api.nvim_create_autocmd('User', {
                pattern = { 'CodeCompanionRequestFinished' },
                group = cc_group,
                callback = function(args)
                    local bufnr = args.data and args.data.bufnr
                    if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
                        vim.b[bufnr]._cc_streaming = false
                        -- Re-enable undo (restore default)
                        vim.bo[bufnr].undolevels = vim.api.nvim_get_option_value('undolevels', { scope = 'global' })
                        enable_chat_rendering(bufnr)
                    end
                end,
                desc = 'Re-enable TS/markview after CodeCompanion streaming',
            })

            -- Disable rendering during insert mode to prevent per-keystroke lag.
            -- Markview's TextChangedI autocmd fires on every keystroke even when
            -- modes={'n'}, because it still runs actions.clear(). Using
            -- actions.disable() sets buffer state so all autocmd callbacks bail out.
            vim.api.nvim_create_autocmd('InsertEnter', {
                group = cc_group,
                pattern = '*',
                callback = function(args)
                    if vim.bo[args.buf].filetype ~= 'codecompanion' then return end
                    disable_chat_rendering(args.buf)
                end,
                desc = 'Disable TS/markview on InsertEnter in CodeCompanion chat',
            })

            vim.api.nvim_create_autocmd('InsertLeave', {
                group = cc_group,
                pattern = '*',
                callback = function(args)
                    if vim.bo[args.buf].filetype ~= 'codecompanion' then return end
                    -- Don't re-enable if the LLM is currently streaming
                    if vim.b[args.buf]._cc_streaming then return end
                    enable_chat_rendering(args.buf)
                end,
                desc = 'Re-enable TS/markview on InsertLeave in CodeCompanion chat',
            })

            -- Exit insert mode after a prompt-library slash command is completed.
            -- Two hooks needed: CompleteDone for the built-in <C-_> completion,
            -- and cmp's confirm_done for nvim-cmp (<C-n>/<C-p>).
            local function stopinsert_deferred()
                vim.defer_fn(function()
                    if vim.api.nvim_get_mode().mode:sub(1, 1) == 'i' then
                        vim.cmd.stopinsert()
                    end
                end, 50)
            end

            -- Hook 1: built-in completion via <C-_> (vim.fn.complete)
            vim.api.nvim_create_autocmd('CompleteDone', {
                group = cc_group,
                callback = function(args)
                    if vim.bo[args.buf].filetype ~= 'codecompanion' then return end
                    local item = vim.v.completed_item
                    if item.user_data and type(item.user_data) == 'table' and item.user_data.from_prompt_library then
                        stopinsert_deferred()
                    end
                end,
                desc = 'Exit insert mode after prompt-library slash command (built-in completion)',
            })

            -- Hook 2: nvim-cmp completion via <C-n>/<C-p>
            do
                local cmp_ok, cmp = pcall(require, 'cmp')
                if cmp_ok then
                    cmp.event:on('confirm_done', function(evt)
                        if vim.bo.filetype ~= 'codecompanion' then return end
                        local entry = evt.entry
                        if entry.source.name ~= 'codecompanion_slash_commands' then return end
                        local item = entry:get_completion_item()
                        if item.from_prompt_library then
                            stopinsert_deferred()
                        end
                    end)
                end
            end

            --- Refresh the CodeCompanion prompt library cache (silently, in background)
            local function refresh_prompt_library()
                local context = require('codecompanion.utils.context').get(vim.api.nvim_get_current_buf())
                require('codecompanion.actions').refresh_cache(context)
            end

            -- Refresh prompt library on CWD change
            vim.api.nvim_create_autocmd('DirChanged', {
                group = cc_group,
                callback = refresh_prompt_library,
                desc = 'Refresh CodeCompanion prompt library on CWD change',
            })

            -- Refresh prompt library after session load
            vim.api.nvim_create_autocmd('SessionLoadPost', {
                group = cc_group,
                callback = refresh_prompt_library,
                desc = 'Refresh CodeCompanion prompt library after session load',
            })

            -- Meta-groups: combine tools from multiple MCP servers by prefix.
            -- After mcphub registers dynamic tools (e.g. `databricks_slack__slack_read_api_call`),
            -- we scan the tool registry and build groups that aggregate tools from several servers.
            local meta_groups = {
                ['db_all'] = {
                    description = "All Databricks MCP servers",
                    servers = {
                        'databricks_confluence', 'databricks_devportal', 'databricks_github',
                        'databricks_glean', 'databricks_google', 'databricks_jira',
                        'databricks_pagerduty', 'databricks_platform', 'databricks_slack',
                        'databricks_testman',
                    },
                },
                ['db_incidents'] = {
                    description = "Incident investigation: PagerDuty, Slack, Jira, platform, Confluence",
                    servers = {
                        'databricks_pagerduty', 'databricks_slack', 'databricks_jira',
                        'databricks_platform', 'databricks_confluence',
                    },
                },
                ['db_docs'] = {
                    description = "Google Docs/Slides work: Google, Confluence, Glean",
                    servers = { 'databricks_google', 'databricks_confluence', 'databricks_glean' },
                },
                ['db_dev'] = {
                    description = "Feature development: GitHub, Jira, Confluence, DevPortal, platform, TestMan",
                    servers = {
                        'databricks_github', 'databricks_jira', 'databricks_confluence',
                        'databricks_devportal', 'databricks_platform', 'databricks_testman',
                    },
                },
                ['db_data_science'] = {
                    description = "Data science / statistics: platform, GitHub, Confluence, Glean",
                    servers = {
                        'databricks_platform', 'databricks_github',
                        'databricks_confluence', 'databricks_glean',
                    },
                },
            }

            --- Build meta-groups by scanning CodeCompanion's tool registry for namespaced tools.
            --- Each MCP tool is registered as `<server>__<tool_name>` by mcphub; we match the prefix.
            local function build_meta_groups()
                local cc_config = require('codecompanion.config')
                local tools_cfg = cc_config.interactions.chat.tools
                local groups = tools_cfg.groups or {}

                for group_name, spec in pairs(meta_groups) do
                    local tool_names = {}
                    for _, server_prefix in ipairs(spec.servers) do
                        local prefix = server_prefix .. '__'
                        for tool_key, _ in pairs(tools_cfg) do
                            if type(tool_key) == 'string' and tool_key:sub(1, #prefix) == prefix then
                                table.insert(tool_names, tool_key)
                            end
                        end
                    end
                    table.sort(tool_names)

                    if #tool_names > 0 then
                        groups[group_name] = {
                            description = spec.description,
                            tools = tool_names,
                            opts = { collapse_tools = true },
                        }
                    else
                        groups[group_name] = nil  -- remove stale group if servers aren't connected
                    end
                end
            end

            -- When MCPHub finishes registering tools/resources (may happen after chat is already open),
            -- rebuild meta-groups and refresh tools + editor_context (variables) on all open chats.
            -- The mcphub CC extension's initial vim.schedule(M.register) often runs before the hub
            -- is ready, so the first `servers_updated` event is the earliest reliable point where
            -- MCP tools and variables become available.
            require('mcphub').on({ 'servers_updated', 'tool_list_changed', 'resource_list_changed' },
                vim.schedule_wrap(function()
                    build_meta_groups()
                    local EditorContext = require('codecompanion.interactions.shared.editor_context')
                    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == 'codecompanion' then
                            local chat = cc.buf_get_chat(buf)
                            if chat then
                                -- Refresh tools (schema, groups, etc.)
                                if chat.tools then
                                    chat.tools:refresh({ adapter = chat.adapter })
                                end
                                -- Refresh editor_context so MCP variables (#mcp:…) are available
                                chat.editor_context = EditorContext.new('chat')
                            end
                        end
                    end
                end)
            )

            -- Patch Chat:set_title to update registry `name` (shown in the
            -- Telescope picker list) WITHOUT clobbering `description`.
            --
            -- The stock set_title writes `description = title`, which replaces
            -- the "[No messages]" sentinel.  The Telescope preview_command
            -- checks for that sentinel to decide whether to show the live
            -- buffer content; once it's gone the preview just shows the title
            -- string.  We therefore skip the description update entirely and
            -- only touch `name` + the fields that don't affect the preview.
            local Chat = require('codecompanion.interactions.chat')
            local registry = require('codecompanion.interactions.shared.registry')
            function Chat:set_title(title)
                assert(type(title) == 'string', 'title must be a string')
                self.title = title
                self.ui.title = title
                registry.update(self.bufnr, { name = title })
                pcall(vim.api.nvim_buf_set_name, self.bufnr, title)
            end

            -- Protect chat buffers from accidental deletion (`:bdel`, `:bw`).
            --
            -- Layer 1 – switch buftype to `acwrite` and keep `modified=true`.
            --   `nofile` buffers silently ignore the modified flag, so `:bdel`
            --   always succeeds.  `acwrite` respects it, making `:bdel` fail
            --   with "No write since last change" while still behaving like a
            --   non-file buffer in every other regard.
            --
            -- Layer 2 – `BufUnload` autocmd catches forced deletion (`:bdel!`)
            --   and properly deregisters the chat so no ghost entry remains in
            --   the "Open chats…" picker.
            vim.api.nvim_create_autocmd('User', {
                pattern = 'CodeCompanionChatCreated',
                group = cc_group,
                callback = function(request)
                    local bufnr = request.buf

                    -- Layer 1: make buffer protected via acwrite + modified
                    vim.bo[bufnr].buftype = 'acwrite'
                    vim.bo[bufnr].modified = true

                    -- No-op BufWriteCmd so `:w` doesn't error; re-arm modified flag.
                    vim.api.nvim_create_autocmd('BufWriteCmd', {
                        buffer = bufnr,
                        group = cc_group,
                        callback = function()
                            vim.bo[bufnr].modified = true
                        end,
                        desc = 'No-op write for protected CodeCompanion chat buffer',
                    })

                    -- Keep modified=true after content changes (LLM streaming
                    -- uses nvim_buf_set_lines which resets it).
                    vim.api.nvim_create_autocmd({ 'TextChanged', 'TextChangedI' }, {
                        buffer = bufnr,
                        group = cc_group,
                        callback = function()
                            if not vim.bo[bufnr].modified then
                                vim.bo[bufnr].modified = true
                            end
                        end,
                        desc = 'Keep CodeCompanion chat buffer marked as modified',
                    })

                    -- Layer 2: catch forced deletion (`:bdel!`) and clean up
                    -- the chat properly so no ghost entry lingers in the registry.
                    vim.api.nvim_create_autocmd('BufUnload', {
                        buffer = bufnr,
                        group = cc_group,
                        once = true,
                        callback = function()
                            -- When chat:close() deletes the buffer it already
                            -- cleans up the registry.  Detect that case via a
                            -- per-buffer flag so we don't double-close.
                            if vim.b[bufnr] and vim.b[bufnr]._cc_closing then
                                return
                            end
                            -- Forced deletion from outside – clean up the chat.
                            vim.schedule(function()
                                local chat = cc.buf_get_chat(bufnr)
                                if chat then
                                    chat:close()
                                end
                            end)
                        end,
                        desc = 'Clean up CodeCompanion chat on forced buffer deletion',
                    })
                end,
                desc = 'Protect CodeCompanion chat buffers from accidental deletion',
            })

            -- Automatically attach current buffer to new chat
            vim.api.nvim_create_autocmd('User', {
                pattern = 'CodeCompanionChatCreated',
                group = cc_group,
                callback = function(request)
                    -- Render output nicely as Markdown
                    vim.treesitter.start(request.buf, 'markdown')
                    vim.wo.colorcolumn = ''

                    -- Auto-include neovim context on chat initialization
                    local chat = cc.buf_get_chat(request.buf)
                    if chat then
                        local ok, ext = pcall(require, 'codecompanion._extensions.editor_context')
                        if ok and ext.exports then
                            local context = ext.exports.get_formatted_context(chat.buffer_context)
                            if context and context ~= '' then
                                chat:add_message({
                                    role = 'user',
                                    content = '<neovimContext>\n' .. context .. '\n</neovimContext>',
                                }, { visible = false })
                            end
                        end
                    end
                end,
            })

            -- Speech-to-text integration (macOS: <D-F8> to record, <F8><D-v> to paste & submit)
            require'speech'.setup()
        end,
    },
}
