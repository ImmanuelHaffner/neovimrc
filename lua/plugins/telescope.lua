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

            require'which-key'.register({
                name = 'Telescope',
                f = { function() require('telescope.builtin').find_files() end, 'Find file' },
                b = { function() require('telescope.builtin').buffers() end, 'Select buffer' },
                c = { function() require('telescope.builtin').tags() end, 'Select ctag' },
                g = {
                    name = 'Find Git ...',
                    f = { function() require('telescope.builtin').git_files() end, 'Find file tracked in Git' },
                    b = { function() require('telescope.builtin').git_branches() end, 'Find Git branch' },
                    c = { function() require('telescope.builtin').git_commits() end, 'Find Git commit' },
                    h = { function() require('telescope.builtin').git_bcommits() end, 'Find buffer\'s Git commit (history)' },
                },
            }, { prefix = '<leader>f' })
        end
    },
}
