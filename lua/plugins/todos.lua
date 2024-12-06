return {
    { 'folke/todo-comments.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'folke/which-key.nvim',
            'nvim-treesitter/nvim-treesitter',
        },
        config = function()
            require'todo-comments'.setup{
                highlight = {
                    comments_only = true,  -- use treesitter to only consider notes in comments
                    pattern = [[.*<(KEYWORDS).{-}:]],
                    keyword = 'bg',
                },
            }

            local todo_comments = require'telescope'.load_extension'todo-comments'
            require'which-key'.add{
                { ']t', function() require'todo-comments'.jump_next() end, desc = 'Next todo comment' },
                { '[t', function() require'todo-comments'.jump_prev() end, desc = 'Next todo comment' },
                { '<leader>fn', function() todo_comments.todo{prompt_prefix=' '} end, desc = 'Find todo notes' },
                { '<leader>t', group = 'Todo …' },
                { '<leader>tt', '<cmd>TodoTrouble<cr>', desc = 'Todo notes in trouble view' },
            }
        end,
    },
}
