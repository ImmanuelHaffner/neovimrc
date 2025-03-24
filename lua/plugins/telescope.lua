return {
    { 'nvim-telescope/telescope-fzf-native.nvim',
        build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build',
    },
    { 'nvim-telescope/telescope.nvim',
        dependencies = {
            'folke/which-key.nvim',
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope-fzf-native.nvim',
            'nvim-telescope/telescope-ui-select.nvim',
            'tknightz/telescope-termfinder.nvim',
        },
        config = function()
            local ts = require'telescope'
            local entry_display = require'telescope.pickers.entry_display'
            local builtins = require'telescope.builtin'
            local previewers = require'telescope.previewers'

            local function custom_git_entry_maker(entry)
                local commit_hash, author, date, message = entry:match("^(%S+) (.-) (%d%d%d%d%-%d%d%-%d%d) (.+)$")

                if not commit_hash or not author or not date or not message then
                    return nil -- Skip malformed entries
                end

                local formatter = entry_display.create{
                    separator = ' ',
                    items = {
                        { width = 10 }, -- Commit hash
                        { width = 20 }, -- Author (custom color)
                        { width = 10 }, -- Date (custom color)
                        { width = 2 },  -- Separator
                        { remaining = true } -- Commit message
                    }
                }

                local display = function()
                    return formatter{
                        { commit_hash:sub(1, 10), 'TelescopePreviewLink' },     -- First column: commit hash
                        { author, 'TelescopeResultsNumber' },                   -- Second column: author name
                        { date, 'TelescopeResultsIdentifier'  },                -- Third column: date
                        { '⨠ ' },
                        { message },                                            -- Fourth column: commit message
                    }
                end

                return {
                    value = commit_hash,
                    ordinal = entry,
                    display = display,
                }
            end


            ts.setup{
                defaults = {
                    dynamic_preview_title = true,
                    mappings = {
                        n = {
                            ['<c-x>'] = require('telescope.actions').delete_buffer
                        },
                        i = {
                            ["<C-h>"] = "which_key",
                            ['<c-x>'] = require('telescope.actions').delete_buffer
                        },
                    },
                },
                pickers = {
                    find_files = {
                        prompt_prefix = '󰱼 ',  -- alternatives: 󰱽 󰮗 󰈞 󰱼 🔍
                        hidden = true,
                    },
                    git_files = {
                        prompt_prefix = '  ',
                    },
                    git_branches = {
                        prompt_prefix = ' ',
                    },
                    git_commits = {
                        prompt_prefix = ' ',  -- alternatives:    
                        git_command = { 'git', 'log', '--pretty=%H %an %ad %s', '--date=short' },
                        entry_maker = custom_git_entry_maker,
                        previewer = previewers.new_termopen_previewer{
                            dyn_title = function(self, entry)
                                return 'Git commit: ' .. entry.value
                            end,
                            get_command = function(entry, status)
                                return {
                                    'env', 'LESS=', 'GIT_PAGER=delta --paging=always --pager=less',
                                    'git', '--paginate', 'show', '--color=never',  entry.value
                                }
                            end,
                        },
                    },
                    git_bcommits = {
                        prompt_prefix = '  ',
                        git_command = { 'git', 'log', '--pretty=%H %an %ad %s', '--date=short' },
                        entry_maker = custom_git_entry_maker,
                        previewer = previewers.new_termopen_previewer{
                            dyn_title = function(self, entry)
                                return 'Git commit: ' .. entry.value
                            end,
                            get_command = function(entry, status)
                                return {
                                    'env', 'LESS=', 'GIT_PAGER=delta --paging=always --pager=less',
                                    'git', '--paginate', 'show', '--color=never',  entry.value, '--', entry.current_file
                                }
                            end,
                        },
                    },
                    git_bcommits_range = {
                        prompt_prefix = '  ',
                        previewer = previewers.new_termopen_previewer{
                            dyn_title = function(self, entry)
                                return 'Git commit: ' .. entry.value
                            end,
                            get_command = function(entry, status)
                                return {
                                    'env', 'LESS=', 'GIT_PAGER=delta --paging=always --pager=less',
                                    'git', '--paginate', 'show', '--color=never',  entry.value, '--', entry.current_file
                                }
                            end,
                        },
                    },
                    buffers = {
                        prompt_prefix = ' ',
                        sort_lastused = true,
                        sort_mru = true,
                    },
                    live_grep = {
                        prompt_prefix = ' ',
                    },
                },

                extensions = {
                    ['fzf'] = {
                        fuzzy = true,                    -- false will only do exact matching
                        override_generic_sorter = true,  -- override the generic sorter
                        override_file_sorter = true,     -- override the file sorter
                        case_mode = 'smart_case',        -- or "ignore_case" or "respect_case"
                    },
                    ['ui-select'] = {
                        require'telescope.themes'.get_dropdown { }
                    },
                }
            }
            ts.load_extension'fzf'
            ts.load_extension'ui-select'
            local termfinder = require'telescope'.load_extension'termfinder'

            local wk = require'which-key'
            wk.add{
                { '<leader>f', group = 'Telescope' },
                { '<leader>ff', function() builtins.find_files() end, desc = 'Find file' },
                { '<leader>fb', function() builtins.buffers() end, desc = 'Select buffer' },
                { '<leader>fc', function() builtins.tags() end, desc = 'Select ctag' },
                { '<leader>fl', function() builtins.live_grep() end, desc = 'Live grep' },
                {
                    { '<leader>fg', group = 'Find Git …' },
                    { '<leader>fgf', function() builtins.git_files() end, desc = 'Find file tracked in Git' },
                    { '<leader>fgb', function() builtins.git_branches() end, desc = 'Find Git branch' },
                    { '<leader>fgc', function() builtins.git_commits() end, desc = 'Find Git commit' },
                    { '<leader>fgh', function() builtins.git_bcommits() end, desc = 'Find buffer\'s Git commit (history)' },
                },
                {
                    { '<leader>fs', group = 'Code search …' },
                    { '<leader>fst', function() builtins.lsp_type_definitions() end, desc = 'Find types' },
                    { '<leader>fss', function()
                            builtins.lsp_dynamic_workspace_symbols{prompt_prefix='󱃖 '}
                        end,
                        desc = 'Find symbols'
                    },
                    { '<leader>fsd', function()
                            builtins.diagnostics{ severity_limit = vim.diagnostic.severity.WARN, prompt_prefix=' ' }
                        end,
                        desc = 'Search diagnostics'
                    },
                },
                { '<leader>fr', function() builtins.resume() end, desc = 'Resume' },
                { '<leader>f\\', function() termfinder.find{prompt_prefix=' '} end, desc = 'Find terminal' },
            }
            wk.add{
                mode = { 'v' },
                { '<leader>fgh', function() builtins.git_bcommits_range() end, desc = 'Find line\'s Git commit (history)' },
            }
        end
    },
}
