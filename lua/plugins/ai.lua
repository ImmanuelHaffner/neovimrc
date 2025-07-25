local utils = require'utils'

--- Parse a Cursor rule file.
--- @param file_path string
--- @return table header  The header of the rule.
--- @return table lines  The lines making the actual content of the rule.
local function parse_rule_file(file_path)
    local lines = vim.fn.readfile(file_path)
    local line_itr = next(lines, nil)
    local header = {}

    -- Skip any empty lines before file header or content.
    while line_itr and utils.trim(lines[line_itr]) == '' do
        line_itr = next(lines, line_itr)
    end

    -- Check whether rules file has header.
    if lines[line_itr] == '---' then
        line_itr = next(lines, line_itr)

        while line_itr and lines[line_itr] ~= '---' do
            local line = lines[line_itr]
            if utils.starts_with(line, 'description:') then
                header.description = utils.trim(line:sub(13, -1))
            elseif utils.starts_with(line, 'globs:') then
                header.globs = line:sub(7, -1)
            elseif utils.starts_with(line, 'alwaysApply:') then
                header.always_apply = utils.trim(line:sub(13, -1)) == 'true'
            else
                -- unrecognized line in header
            end
            line_itr = next(lines, line_itr)
        end
        line_itr = next(lines, line_itr)
    end

    -- Skip any empty lines before file content.
    while line_itr and utils.trim(lines[line_itr]) == '' do
        line_itr = next(lines, line_itr)
    end

    return header, {table.unpack(lines, line_itr)}
end


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
            model = 'claude-sonnet-4',
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
    { 'Davidyz/VectorCode',
        version = '0.7.10', -- optional, depending on whether you're on nightly or release
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
            }
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
            'Davidyz/VectorCode',
        },
        config = function()
            -- Check if Docker service is running
            local function check_docker_service()
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

            local cc = require'codecompanion'
            cc.setup{
                adapters = {
                    copilot = function()
                        return require'codecompanion.adapters'.extend('copilot', {
                            schema = {
                                model = {
                                    default = 'claude-sonnet-4',
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
                                    'neovim',  -- all tools from the Neovim MCP server
                                },
                            },
                            groups = {
                                ['dev'] = {
                                    description = "Default developer setup",
                                    tools = {
                                        'read_file',
                                        'file_search',
                                        'grep_search',
                                        'neovim',  -- all tools from the Neovim MCP server
                                    },
                                    opts = {
                                        collapse_tools = false, -- When true, show as a single group reference instead of individual tools
                                    },
                                },
                            },
                        },
                        opts = {
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
                display = {
                    action_palette = {
                        opts = {
                            show_default_actions = true,
                        }
                    },

                    chat = {
                        show_token_count = true,
                        show_settings = true,  -- when `true` prevents changing adapter/model

                        --- Customize how tokens are displayed
                        --- @param tokens number
                        --- @param _ CodeCompanion.Adapter
                        --- @return string
                        token_count = function(tokens, _)
                            return ' (' .. tokens .. ' tokens)'
                        end,
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

            local cc_group = vim.api.nvim_create_augroup('CodeCompanionHooks', {})

            -- Automatically attach current buffer to new chat
            vim.api.nvim_create_autocmd('User', {
                pattern = 'CodeCompanionChatCreated',
                group = cc_group,
                callback = function(request)
                    -- Render output nicely as Markdown
                    vim.treesitter.start(request.buf, 'markdown')
                    vim.b.colorcolumn = ''
                end,
            })
            -- Get the plugin root directory
            local plugin_root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h:h')
            -- Read the default system prompt.
            local prompt_path = plugin_root .. '/assets/code-companion-system-prompt.md'
            local default_system_prompt = table.concat(vim.fn.readfile(prompt_path), '\n')

            local function load_rules()
                local cc_config = require'codecompanion.config'
                -- Check if the directory exists
                local cursor_rules_dir = '.cursor/rules'
                if vim.fn.isdirectory(cursor_rules_dir) == 1 then
                    local rules = {}
                    local rules_always_applied = {}
                    local rule_files = vim.fn.glob(cursor_rules_dir .. '/*.mdc', false, true)

                    if #rule_files == 0 then return end

                    local additional_prompt = {'\n'}

                    -- Read all rules files and combine their content
                    for _, file_path in ipairs(rule_files) do
                        local header, content = parse_rule_file(file_path)
                        local basename = utils.basename(file_path)
                        local basename_wo_suffix = string.match(basename, '^(.*)%.%w+$')

                        if header.always_apply and #content > 0 then
                            table.insert(rules_always_applied, file_path)
                            additional_prompt = {table.unpack(additional_prompt), '\n', table.unpack(content)}
                        end

                        table.insert(rules, basename_wo_suffix)

                        -- Add rule to prompt library.
                        local description = header.description
                        if not description or #description == 0 then
                            description = string.sub(content[1], 0, 40)
                        end
                        local rule_name = basename_wo_suffix
                        if header.description and #header.description > 0 then
                            rule_name = string.sub(header.description, 1, 40)
                        end
                        cc_config.prompt_library[rule_name] = {
                            strategy = 'chat',
                            -- Set the description, if available, or use the head line.
                            description = description,
                            opts = {
                                user_prompt = true,
                            },
                            references = {
                                {
                                    type = 'file',
                                    path = { file_path },
                                },
                            },
                            -- Set the prompt text.
                            prompts = {
                                {
                                    role = 'user',
                                    content = ''
                                }
                            },
                        }
                    end

                    local new_system_prompt = default_system_prompt .. table.concat(additional_prompt, '\n')

                    -- Update CodeCompanion system prompt
                    cc_config.opts.system_prompt = function()
                        return new_system_prompt
                    end

                    vim.notify((
                        "CodeCompanion system prompt updated from %d Cursor rule%s.\n" ..
                        "Loaded %d rule%s into prompt library."
                    ):format(
                        #rules_always_applied,
                        #rules_always_applied == 1 and '' or 's',
                        #rules,
                        #rules == 1 and '' or 's'
                    ), vim.log.levels.INFO)

                    return
                end

                -- Check if Copilot instructions are available
                local copilot_instructions = '.github/copilot-instructions.md'
                if vim.fn.filereadable(copilot_instructions) == 1 then
                    local prompt_content = table.concat(vim.fn.readfile(copilot_instructions), '\n')
                    local new_system_prompt = default_system_prompt .. '\n\n' .. prompt_content
                    cc_config.opts.system_prompt = function()
                        return new_system_prompt
                    end
                    vim.api.nvim_echo({{
                        'CodeCompanion system prompt updated from \'.github/copilot-instructions.md\'',
                    }}, true, {})
                    return
                end
            end

            -- Remember for which CWD we recently loaded rules.
            local last_cwd_loaded = vim.uv.cwd()
            local prompt_library_clone = vim.deepcopy(require'codecompanion.config'.prompt_library)

            -- Check for `.github/copilot-instructions.md` file or `.cursor/rules` directory on directory change and
            -- update system prompt.
            vim.api.nvim_create_autocmd({ 'DirChanged', 'SessionLoadPost' }, {
                pattern = '*',
                callback = function()
                    local cwd = vim.uv.cwd()
                    if cwd == last_cwd_loaded then
                        return  -- already auto-loaded rules for this CWD
                    end
                    last_cwd_loaded = cwd

                    -- Reset prompt library
                    require'codecompanion.config'.prompt_library = vim.deepcopy(prompt_library_clone)

                    load_rules()
                end
            })

            -- Reload rules after writing.  Do not respect any timeout.
            vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
                pattern = { '.cursor/rules/*.mdc', },
                callback = load_rules,
            })
        end,
    },
}






