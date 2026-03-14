return {
    {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5 && cmake --build build --config Release && cmake --install build --prefix build',
    },
    {
        'nvim-telescope/telescope.nvim',
        dependencies = {
            'folke/which-key.nvim',
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope-fzf-native.nvim',
            'nvim-telescope/telescope-ui-select.nvim',
            'tknightz/telescope-termfinder.nvim',
            'ImmanuelHaffner/nvu.nvim',
            {
                'nvim-telescope/telescope-live-grep-args.nvim',
                version = 'v1.1.0',
            }
        },
        config = function()
            local ts = require'telescope'
            local builtins = require'telescope.builtin'

            ts.setup{
                defaults = {
                    dynamic_preview_title = true,
                    mappings = {
                        n = {
                            ['<C-x>'] = require('telescope.actions').delete_buffer
                        },
                        i = {
                            ['<C-h>'] = 'which_key',
                            ['<C-x>'] = require('telescope.actions').delete_buffer
                        },
                    },
                },
                -- Pickers are configured by adaptive_pickers extension

                extensions = {
                    ['fzf'] = {
                        fuzzy = true,                    -- false will only do exact matching
                        override_generic_sorter = true,  -- override the generic sorter
                        override_file_sorter = true,     -- override the file sorter
                        case_mode = 'smart_case',        -- or "ignore_case" or "respect_case"
                    },
                    ['ui-select'] = {
                        require'telescope.themes'.get_dropdown{}
                    },
                }
            }

            -- Load extensions (order matters: adaptive_pickers modifies picker config)
            ts.load_extension'adaptive_pickers'
            ts.load_extension'fzf'
            ts.load_extension'ui-select'
            ts.load_extension'live_grep_args'
            local termfinder = ts.load_extension'termfinder'

            local wk = require'which-key'
            wk.add{
                { '<leader>f', group = 'Telescope' },
                { '<leader>ff', function() builtins.find_files() end, desc = 'Find file' },
                { '<leader>fb', function() builtins.buffers() end, desc = 'Select buffer' },
                { '<leader>fc', function() builtins.tags() end, desc = 'Select ctag' },
                { '<leader>fl', function() ts.extensions.live_grep_args.live_grep_args() end, desc = 'Live grep' },
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
