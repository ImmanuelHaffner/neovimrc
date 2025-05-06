return {
    { 'hamidi-dev/kaleidosearch.nvim',
        dependencies = {
            -- 'tpope/vim-repeat',       -- optional for dot-repeatability
            -- 'stevearc/dressing.nvim', -- optional for nice input
            'folke/which-key.nvim',
        },

        config = function()
            local ks = require'kaleidosearch'
            ks.setup{}

            require'which-key'.add{
                { '<leader>/', group = 'Search…' },
                { '<leader>//', function() ks.prompt_and_search() end, desc = 'Multiple words' },
                { '<leader>/n', function() ks.add_new_word() end, desc = 'Add word' },
                { '<leader>/t', function() ks.toggle_word_or_selection() end, desc = 'Toggle word' },
            }
        end,
    },
}
