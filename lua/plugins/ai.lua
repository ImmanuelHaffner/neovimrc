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
        --       Upstream looks dormant (last commit 2026-01-18); alternative PR #287
        --       was closed unmerged on 2026-06-01. Don't expect quick resolution.
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
            local Utils = require'utils'
            local port = 27373
            if Utils.is_ssh_connection() or Utils.is_client_server_connection() then
                port = port + 1
            end

            require("mcphub").setup({
                -- Pin an explicit port below the Linux ephemeral range (32768+) so the Arca SSH companion — which
                -- mirrors arbitrary remote devbox ports onto localhost — can never collide with the local hub.
                -- mcp-hub's default
                -- 37373 sits inside that ephemeral band and clashed with a remote mcp-hub forwarded by Arca, causing
                -- the hub to serve `/home/...` config paths (remote $HOME) and E739 on macOS autofs `/home`.
                port = port,
                -- Workspace hubs are OFF.  A workspace hub re-spawns every enabled global server, so each
                -- enrolled project added its own duplicate `fff_universe` / `fff_runtime` — three universe
                -- indexes at ~3.2 GiB each were once live at once, and 178 GiB resident was observed.
                -- Project-scoped servers now come from `.project.lua` via `lua/project/mcp.lua` instead,
                -- which yields exactly one hub, one static index per read-only checkout, and one process
                -- per project.  This also retires the `look_for` pin that stopped MCPHub's upward marker
                -- search (which never stopped at $HOME) from resolving every cwd under $HOME to a
                -- $HOME-rooted hub that merged Cursor's ~17 duplicate Databricks servers over ours.
                workspace = { enabled = false },
            })
            -- Register nvu.nvim's structured-edit tools
            -- (`neovim__apply_edit`, `neovim__read_with_fingerprint`) as
            -- siblings of mcphub's built-in `neovim__edit_file`. Loaded
            -- after setup{} so the native `neovim` server already exists.
            -- The adapter self-fires `tool_list_changed` on the mcphub
            -- State bus so the CodeCompanion bridge re-scans and exposes
            -- the new tools in chat — no extra nudge needed here.
            -- Guarded with pcall so a missing/broken nvu.nvim checkout doesn't
            -- break the whole mcphub config (and CodeCompanion startup).
            local ok, err = pcall(require, 'mcphub._native.edit')
            if not ok then
                vim.notify(
                    'mcphub._native.edit failed to load: ' .. tostring(err),
                    vim.log.levels.WARN,
                    { title = 'nvu.edit' }
                )
            end
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
            -- Databricks workspace host. Serves both the AI Gateway
            -- (/ai-gateway/...) and the serving-endpoints REST API (/api/2.0/...).
            local DATABRICKS_AI_GATEWAY_URL = 'https://dbc-a5d4177a-49dc.cloud.databricks.com'

            -- Databricks model-serving OAuth token, kept fresh by the managed
            -- refresh_model_serving_token.sh hook (~/.config/llm-cli/hooks). The
            -- token is short-lived and rotated, so it is read fresh on every
            -- request rather than pulled once from the environment.
            local MODEL_SERVING_TOKEN_PATH = vim.fn.expand('~/.databricks/model-serving-token.json')

            --- Read the current bearer token from the model-serving token file.
            --- @return string|nil token The OAuth access token, or nil if unavailable.
            local function read_model_serving_token()
                if vim.fn.filereadable(MODEL_SERVING_TOKEN_PATH) == 0 then
                    return nil
                end
                local ok, content = pcall(vim.fn.readfile, MODEL_SERVING_TOKEN_PATH)
                if not ok or not content or #content == 0 then
                    return nil
                end
                local decoded_ok, data = pcall(vim.json.decode, table.concat(content, '\n'))
                if not decoded_ok or type(data) ~= 'table' then
                    return nil
                end
                return data.access_token
            end

            -- Per-model output-token ceilings. Neither the serving-endpoints API
            -- nor the /v1/models list reports max_tokens (both omit it or return
            -- 0); the only API-truth source is the validation error you get by
            -- overshooting. These values were read off those errors on
            -- 2026-07-23. Anything not listed falls back to DEFAULT_MAX_TOKENS.
            local DEFAULT_MAX_TOKENS = 128000
            local MODEL_MAX_TOKENS = {
                ['databricks-claude-haiku-4-5'] = 200000,
            }

            -- Effort levels the gateway accepts for adaptive thinking
            -- (output_config.effort). The serving-endpoints capabilities block
            -- reports anthropic_reasoning=false for every Claude model, which is
            -- wrong: the native /v1/messages path does return thinking content
            -- for these efforts (verified 2026-07-23). So the support list is
            -- hardcoded rather than derived from the (lying) capabilities API.
            local SUPPORTED_EFFORTS = { 'low', 'medium', 'high', 'xhigh', 'max' }

            -- Static fallback catalogue, used when the serving-endpoints fetch
            -- fails (no token, offline, request error). Mirrors the ModelChoice
            -- shape the base `anthropic` adapter consumes.
            local FALLBACK_MODELS = {
                ['databricks-claude-opus-4-8'] = {
                    formatted_name = 'Claude Opus 4.8',
                    meta = { max_tokens = DEFAULT_MAX_TOKENS },
                    opts = { has_vision = true, can_reason = true, reasoning = { supported = SUPPORTED_EFFORTS } },
                },
                ['databricks-claude-sonnet-4-6'] = {
                    formatted_name = 'Claude Sonnet 4.6',
                    meta = { max_tokens = DEFAULT_MAX_TOKENS },
                    opts = { has_vision = true, can_reason = true, reasoning = { supported = SUPPORTED_EFFORTS } },
                },
            }

            -- Module-local cache for the fetched model catalogue.
            local model_cache = { models = nil, expires = 0 }
            local MODEL_CACHE_TTL = 300  -- seconds

            --- Fetch the Claude chat models from the Databricks serving-endpoints API.
            --- Returns a ModelChoice map (id -> { formatted_name, meta, opts }) or nil on failure.
            --- @return table<string, table>|nil
            local function fetch_gateway_models()
                local token = read_model_serving_token()
                if not token or token == '' then
                    return nil
                end

                local ok, Curl = pcall(require, 'plenary.curl')
                if not ok then
                    return nil
                end

                local response = Curl.get(DATABRICKS_AI_GATEWAY_URL .. '/api/2.0/serving-endpoints', {
                    headers = { ['Authorization'] = 'Bearer ' .. token },
                    timeout = 5000,
                })
                if not response or response.status ~= 200 then
                    return nil
                end

                local decoded_ok, data = pcall(vim.json.decode, response.body)
                if not decoded_ok or type(data) ~= 'table' or type(data.endpoints) ~= 'table' then
                    return nil
                end

                local models = {}
                for _, endpoint in ipairs(data.endpoints) do
                    local entity = endpoint.config
                        and endpoint.config.served_entities
                        and endpoint.config.served_entities[1]
                    local fm = entity and entity.foundation_model
                    local caps = endpoint.capabilities or {}
                    -- Keep only Anthropic chat models reachable via /v1/messages.
                    if fm
                        and fm.model_class == 'claude'
                        and endpoint.task == 'llm/v1/chat'
                        and vim.tbl_contains(fm.api_types or {}, 'anthropic/v1/messages')
                    then
                        models[endpoint.name] = {
                            formatted_name = fm.display_name or endpoint.name,
                            meta = { max_tokens = MODEL_MAX_TOKENS[endpoint.name] or DEFAULT_MAX_TOKENS },
                            opts = {
                                has_vision = caps.image_input or false,
                                -- Reasoning support is hardcoded (see SUPPORTED_EFFORTS);
                                -- the capabilities block under-reports it.
                                can_reason = true,
                                reasoning = { supported = SUPPORTED_EFFORTS },
                            },
                        }
                    end
                end

                if vim.tbl_isempty(models) then
                    return nil
                end
                return models
            end

            --- Return the Claude model catalogue, cached with a short TTL and
            --- falling back to the static list when discovery is unavailable.
            --- @return table<string, table>
            local function get_gateway_models()
                if model_cache.models and model_cache.expires > os.time() then
                    return model_cache.models
                end
                local fetched = fetch_gateway_models()
                if fetched then
                    model_cache.models = fetched
                    model_cache.expires = os.time() + MODEL_CACHE_TTL
                    return fetched
                end
                return FALLBACK_MODELS
            end

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
                        name = 'Databricks AI Gateway (Anthropic)',
                        is_available = function()
                            local token = read_model_serving_token()
                            return token ~= nil and token ~= ''
                        end,
                    },
                    {
                        name = 'Databricks Anthropic',
                        is_available = function()
                            local key = vim.env.DATABRICKS_ANTHROPIC_API_KEY
                            return key ~= nil and key ~= ''
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
                                schema = {
                                    model = {
                                        -- Static `choices` (rather than inheriting the base
                                        -- `anthropic` adapter's function, which fetches GET
                                        -- https://api.anthropic.com/v1/models). Our
                                        -- DATABRICKS_ANTHROPIC_API_KEY is only accepted by the
                                        -- Databricks gateway, not by api.anthropic.com directly,
                                        -- so that fetch 401s ("API key is invalid") and spams the
                                        -- log. A static list keeps this adapter inert unless a
                                        -- genuinely direct Anthropic key is configured.
                                        default = 'claude-opus-4-8',
                                        choices = {
                                            ['claude-opus-4-8'] = {
                                                formatted_name = 'Claude Opus 4.8',
                                            },
                                            ['claude-sonnet-4-6'] = {
                                                formatted_name = 'Claude Sonnet 4.6',
                                            },
                                        },
                                    },
                                    -- Pin the output token budget explicitly. The base adapter's
                                    -- `max_tokens` default derives from the async model catalogue
                                    -- (`meta.max_tokens`), but on a cold cache that fetch hasn't
                                    -- completed when the first chat's settings render, so it falls
                                    -- back to a tiny 4096. Setting it here makes the ceiling
                                    -- deterministic (128k = Opus 4.8's API-reported max).
                                    max_tokens = {
                                        default = 128000,
                                    },
                                    -- Pin the reasoning effort. Like `max_tokens`, the base
                                    -- adapter's `effort` default is derived from the async model
                                    -- catalogue. But `effort` is also *gated* by an `enabled`
                                    -- function that checks the same catalogue for reasoning
                                    -- support; on a cold cache that returns false and the key is
                                    -- dropped from the settings block entirely (so `default` never
                                    -- applies). Override `enabled` to always-true since every
                                    -- Opus/Sonnet model we use supports effort, and pin the default.
                                    effort = {
                                        default = 'xhigh',
                                        enabled = function() return true end,
                                    },
                                },
                            })
                        end,
                        -- Databricks AI Gateway adapter, extending the base `anthropic`
                        -- adapter over the gateway's native /v1/messages endpoint.
                        -- The native path (unlike the mlflow OpenAI-compatible one) both
                        -- authenticates with a Bearer token and returns thinking content,
                        -- so the base adapter's reasoning/effort handling works unchanged.
                        ['Databricks AI Gateway (Anthropic)'] = function()
                            local anthropic = require('codecompanion.adapters.http.anthropic')
                            return require'codecompanion.adapters'.extend('anthropic', {
                                formatted_name = 'Databricks AI Gateway (Anthropic)',
                                env = {
                                    -- Resolve the bearer token from the model-serving token file
                                    -- on every request so a rotated token is always picked up.
                                    api_key = function()
                                        return read_model_serving_token()
                                    end,
                                },
                                url = DATABRICKS_AI_GATEWAY_URL .. '/ai-gateway/anthropic/v1/messages',
                                headers = {
                                    ['content-type'] = 'application/json',
                                    -- Gateway authenticates with a Bearer token. The base adapter's
                                    -- x-api-key header is still sent (tbl_deep_extend can't drop a
                                    -- key) but the gateway ignores it when Authorization is present.
                                    ['Authorization'] = 'Bearer ${api_key}',
                                    ['anthropic-version'] = '2023-06-01',
                                },
                                handlers = {
                                    -- Repair truncated tool-call argument JSON before the base
                                    -- adapter's form_messages runs: it decodes each tool_use's
                                    -- `arguments` string and silently discards the whole call on a
                                    -- parse failure (common when a stream is cut off by max_tokens).
                                    -- ensure_valid_json_args completes the truncated JSON so the
                                    -- call survives.
                                    form_messages = function(self, messages)
                                        for _, message in ipairs(messages) do
                                            if message.tools and message.tools.calls then
                                                for _, call in ipairs(message.tools.calls) do
                                                    if call['function'] then
                                                        call['function'].arguments = ensure_valid_json_args(
                                                            call['function'].arguments
                                                        )
                                                    end
                                                end
                                            end
                                        end
                                        return anthropic.handlers.form_messages(self, messages)
                                    end,
                                },
                                schema = {
                                    model = {
                                        default = 'databricks-claude-opus-4-8',
                                        -- Discover the live Claude catalogue from the Databricks
                                        -- serving-endpoints API, with a static fallback. Provides
                                        -- formatted_name, per-model max_tokens, vision, and the
                                        -- (hardcoded) supported reasoning efforts.
                                        choices = function()
                                            return get_gateway_models()
                                        end,
                                    },
                                    -- Default the reasoning effort to xhigh. The base adapter
                                    -- gates `effort` on the model catalogue's reasoning.supported
                                    -- list, which get_gateway_models() populates for every model.
                                    effort = {
                                        default = 'xhigh',
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
                                -- Replace CodeCompanion's built-in tools system prompt. The stock
                                -- one (config.lua) instructs the model to edit via an
                                -- `insert_edit_into_file` tool that does not exist in this setup
                                -- (we edit through the `neovim__*` MCP tools) and to otherwise
                                -- "print out a code block" — both of which conflict with our real
                                -- editing contract and were a source of tool-naming confusion.
                                -- This version keeps the useful agentic guidance (gather context,
                                -- prefer parallel calls, don't narrate tool names) and adds an
                                -- explicit "only call tools that exist" rule.
                                system_prompt = {
                                    enabled = true,
                                    replace_main_system_prompt = false,
                                    ---@param _ { ctx: CodeCompanion.SystemPrompt.Context, tools: string[] }
                                    ---@return string
                                    prompt = function(_)
                                        return [[<toolUseInstructions>
You have a set of tools for retrieving context and performing actions. Use them to answer the user's question or complete the task.
Only ever call a tool that actually appears in your available tool list. Never invent a tool name, and never write out a JSON code block of tool inputs instead of issuing a real tool call.
Gather context before acting: don't assume the state of the code or the workspace — read the relevant files first. You don't need to re-read a file that is already provided in context.
Call tools repeatedly, and in parallel when the calls are independent, until you have done everything you can to complete the request. Don't give up unless the task genuinely can't be done with the tools you have.
When a tool takes a file path, use the exact path the user or a previous tool gave you.
Follow each tool's JSON schema exactly and include all required properties.
Don't announce tool names to the user (say "I'll edit the file", not "I'll use the X tool"), and don't repeat yourself after a tool call — pick up where you left off.
</toolUseInstructions>]]
                                    end,
                                },
                                default_tools = {
                                    'memory',
                                    'kgmemory',
                                    'neovim',  -- all tools from the Neovim MCP server
                                    'neovim_context',  -- provide context on open buffers, cursor pos, active buffer
                                    -- fff servers are deliberately NOT listed here.  The project-scoped
                                    -- ones are created on demand by `.project.lua` and named
                                    -- `fff_<project>_<hash>` (see `lua/project/mcp.lua`), so no static
                                    -- list can name them.  `sync_fff_tools()` below rewrites the `fff*`
                                    -- entries of this very table from the hub's connected servers.
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
                            ---Replace CodeCompanion's built-in (Copilot-derived) system prompt
                            ---entirely with a lean, harness-specific one.
                            ---
                            ---Why replace rather than extend: the stock prompt carries generic
                            ---assistant filler that Opus 4.8 auto-calibrates around anyway, plus a
                            ---code-EDIT convention (```` {path} … `...existing code...` blocks) that
                            ---directly conflicts with our MCP `neovim__*` edit flow. Combined with
                            ---the tools prompt's reference to a non-existent `insert_edit_into_file`
                            ---tool, that produced three competing edit instructions — a literal
                            ---source of tool-naming confusion. We drop all of it and keep only what
                            ---the model genuinely can't infer: this chat buffer's Markdown rendering
                            ---constraints, and the dynamic environment context. The real editing
                            ---contract (`neovim__*` tools) lives in `neovim_additions`, appended last.
                            ---@param ctx CodeCompanion.SystemPrompt.Context language, cwd, date, nvim_version, os, project_root
                            ---@return string
                            system_prompt = function(ctx)
                                local base_prompt = table.concat({
                                    'You are an AI programming assistant working inside the Neovim text editor.',
                                    '',
                                    'Your responses render in a Markdown buffer with live markview rendering, so:',
                                    '- Do not use H1 or H2 headers.',
                                    '- Wrap filenames, paths, and code symbols in backticks.',
                                    '- Use four-backtick code fences with a correct language ID (e.g. ````lua).',
                                    '- Do not wrap your whole response in a code fence.',
                                    '',
                                    'Additional context:',
                                    string.format('- All non-code prose must be written in the %s language.', ctx.language),
                                    string.format('- The current working directory is %s.', ctx.cwd),
                                    string.format('- The current date is %s.', ctx.date),
                                    string.format('- The Neovim version is %s.', ctx.nvim_version),
                                    string.format('- The user is on a %s machine; prefer system-appropriate commands.', ctx.os),
                                }, '\n')

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
                rules = {
                    opts = {
                        chat = {
                            -- Load the autoload rule groups (e.g. `default`) into the prompt library so
                            -- prompts that name no rules still pick up the autoload groups.
                            autoload_groups_in_prompt_library = true,
                        },
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
                    -- Event bus from nvu library: turns silent editor state changes (e.g. a manual
                    -- :cd/:lcd/:tcd) into a system message injected into every live chat's stack, so
                    -- the LLM is told when the cwd moves under it instead of reasoning against a stale
                    -- root (registers a sink that fans out via Chat:add_message).
                    event_bus = {
                        callback = 'codecompanion._extensions.event_bus',
                        opts = {},
                    },
                    -- MCP tool output size guard: spills oversized tool responses to disk and replaces
                    -- the inline payload with a short summary + path + usage hints (rg/jq/head).
                    -- Catches every MCP server uniformly via the single mcphub output handler.
                    -- Defaults: 20k tokens / 96 KB / 2000 lines (whichever trips first).
                    mcp_size_guard = {
                        callback = 'codecompanion._extensions.mcp_size_guard',
                        opts = {
                            -- Bypass the size guard for tools whose contract is to deliver content
                            -- or perform structured edits — spilling those is counter-productive
                            -- (a `read_with_fingerprint` whose payload is spilled defeats the whole
                            -- point of getting the content into the LLM's working set).
                            -- Execution tools (execute_command, execute_lua) stay guarded: their
                            -- output is opaque and often huge (rg dumps, vim.inspect of big tables).
                            skip = {
                                'neovim__apply_edit',
                                'neovim__delete_items',
                                'neovim__edit_file',
                                'neovim__list_directory',
                                'neovim__move_item',
                                'neovim__read_with_fingerprint',
                                'neovim__write_file',
                            },
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

            -- Extend (don't override) the built-in `default` rules preset with global
            -- instruction files from the home directory. This MUST run *after* `cc.setup{}`
            -- because setup rebuilds `M.config` from `vim.deepcopy(defaults)` (see
            -- codecompanion/config.lua:1348), wiping out any pre-setup mutations.
            do
                local rules_files = require'codecompanion.config'.config.rules.default.files
                table.insert(rules_files, '~/AGENTS.md')
                table.insert(rules_files, { path = '~/CLAUDE.md', parser = 'claude' })
            end

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
                            width = require'nvu.layout'.adaptive_extent{
                                frac = 0.7, extent = vim.o.columns, min = 80, max = 200,
                            },
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
                require('codecompanion.action_palette').refresh_cache(context)
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
                    description = 'All Databricks MCP servers',
                    servers = {
                        'databricks_client_v2',
                        'databricks_confluence',
                        'databricks_debug_copilot',
                        'databricks_devportal',
                        'databricks_genie',
                        'databricks_glean',
                        'databricks_google',
                        'databricks_jira',
                        'databricks_logs_summariser',
                        'databricks_observability',
                        'databricks_pagerduty',
                        'databricks_safe',
                        'databricks_slack',
                        'databricks_storage_console',
                        'databricks_testman',
                        'databricks_github',
                    },
                },
                ['db_dev'] = {
                    description = 'Full developer toolkit',
                    servers = {
                        'databricks_confluence',
                        'databricks_devportal',
                        'databricks_glean',
                        'databricks_jira',
                        'databricks_safe',
                        'databricks_github',
                    },
                },
                ['db_comms'] = {
                    description = 'Incident investigation: PagerDuty, Slack, Jira, platform, Confluence',
                    servers = {
                        'databricks_slack',
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

            -- Keep the `fff*` entries of `default_tools` in sync with the hub's connected servers.
            --
            -- Project-scoped fff servers are created on the fly by `.project.lua` (see
            -- `lua/project/mcp.lua`) and named `fff_<project>_<hash>`, so they cannot be listed statically.
            -- CodeCompanion reads `default_tools` when a chat is created (`chat/init.lua`), so rewriting
            -- that live table is enough for every chat opened afterwards.
            local function sync_fff_tools()
                local tools = require('codecompanion.config').interactions.chat.tools.opts.default_tools
                if not tools then return end

                for i = #tools, 1, -1 do
                    if type(tools[i]) == 'string' and tools[i]:match('^fff') then table.remove(tools, i) end
                end
                for _, server in ipairs((require('mcphub.state').server_state or {}).servers or {}) do
                    local name = server.name
                    if type(name) == 'string' and name:match('^fff') and server.status == 'connected' then
                        table.insert(tools, name)
                    end
                end
            end

            -- Project-scoped fff servers persist in the hub's config file across restarts, so once per
            -- session drop the ones whose project is gone and disable the ones this session has not asked
            -- for (see `lua/project/mcp.lua`).  `sweep()` reports false until the hub config is loaded, so
            -- this keeps trying on later events.
            local project_servers_swept = false
            local function sweep_project_servers()
                if project_servers_swept then return end
                local ok, project_mcp = pcall(require, 'project.mcp')
                if not ok then return end

                local swept_ok, swept = pcall(project_mcp.sweep)
                project_servers_swept = swept_ok and swept or false
            end

            -- When MCPHub finishes registering tools/resources (may happen after chat is already open),
            -- rebuild meta-groups and refresh tools + editor_context (variables) on all open chats.
            -- The mcphub CC extension's initial vim.schedule(M.register) often runs before the hub
            -- is ready, so the first `servers_updated` event is the earliest reliable point where
            -- MCP tools and variables become available.
            require('mcphub').on({ 'servers_updated', 'tool_list_changed', 'resource_list_changed' },
                vim.schedule_wrap(function()
                    build_meta_groups()
                    sweep_project_servers()
                    sync_fff_tools()
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
