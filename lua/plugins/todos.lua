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
                },
            }
            -- Next todo
            vim.keymap.set("n", "]t", function()
                require("todo-comments").jump_next()
            end, { desc = "Next todo comment" })

            -- Previous todo
            vim.keymap.set("n", "[t", function()
                require("todo-comments").jump_prev()
            end, { desc = "Previous todo comment" })

            -- Search todo notes with telescope
            require'which-key'.register({
                name = 'Telescope',
                t = { '<cmd>TodoTelescope<cr>', 'Find todo notes' },
            }, { prefix = '<leader>f', silent = true })

            -- Show todo notes in trouble view
            require'which-key'.register({
                name = 'Todos',
                t = { '<cmd>TodoTrouble<cr>', 'todo notes in trouble view' },
            }, { prefix = '<leader>t', silent = true })
        end,
    },
}
