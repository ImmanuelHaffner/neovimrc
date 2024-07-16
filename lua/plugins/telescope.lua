return {
    { 'nvim-telescope/telescope-fzf-native.nvim',
        dependencies = { 'nvim-telescope/telescope.nvim' },
        build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build',
    },
    { 'nvim-telescope/telescope.nvim',
        tag = '0.1.2',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope-fzf-native.nvim',
            'nvim-telescope/telescope-ui-select.nvim',
            'folke/which-key.nvim',
        },
        config = function()
            local ts = require'telescope'
            ts.setup{
                extensions = {
                    ['fzf'] = {
                        fuzzy = true,                    -- false will only do exact matching
                        override_generic_sorter = true,  -- override the generic sorter
                        override_file_sorter = true,     -- override the file sorter
                        case_mode = 'smart_case',        -- or "ignore_case" or "respect_case"
                    },
                    ['ui-select'] = { require('telescope.themes').get_dropdown { } }
                }
            }
            ts.load_extension'fzf'
            ts.load_extension'ui-select'

            require'which-key'.add{
                { '<leader>f', group = 'Telescope' },
                { '<leader>ff', function() require('telescope.builtin').find_files() end, desc = 'Find file' },
                { '<leader>fb', function() require('telescope.builtin').buffers() end, desc = 'Select buffer' },
                { '<leader>fc', function() require('telescope.builtin').tags() end, desc = 'Select ctag' },
                { '<leader>fl', function() require('telescope.builtin').live_grep() end, desc = 'Live grep' },
                {
                    { '<leader>fg', group = 'Find Git …' },
                    { '<leader>fgf', function() require('telescope.builtin').git_files() end, desc = 'Find file tracked in Git' },
                    { '<leader>fgb', function() require('telescope.builtin').git_branches() end, desc = 'Find Git branch' },
                    { '<leader>fgc', function() require('telescope.builtin').git_commits() end, desc = 'Find Git commit' },
                    { '<leader>fgh', function() require('telescope.builtin').git_bcommits() end, desc = 'Find buffer\'s Git commit (history)' },
                },
                {
                    { '<leader>fs', group = 'Code search …' },
                    { '<leader>fst', function() require('telescope.builtin').lsp_type_definitions() end, desc = 'Find types' },
                    { '<leader>fss', function() require('telescope.builtin').lsp_dynamic_workspace_symbols() end, desc = 'Find symbols' },
                    { '<leader>fsd', function() require('telescope.builtin').diagnostics{ severity_limit = vim.diagnostic.severity.WARN } end, desc = 'Search diagnostics' },
                },
                { '<leader>fr', function() require('telescope.builtin').resume() end, desc = 'Resume' },
            }
        end
    },
}
