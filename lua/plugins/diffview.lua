return {
    { 'sindrets/diffview.nvim',
        dependencies = {
            'folke/which-key.nvim',
        },
        config = function()
            require'diffview'.setup{
                file_panel = {
                    win_config = function()
                        return {
                            width = vim.o.columns and math.floor(0.2 * vim.o.columns) or 60,  -- 20% of total width
                        }
                    end,
                },
            }

            -- vim.opt.fillchars:append{ diff = '␥' }  -- alternatives: ␥╱
            require'which-key'.add{
                { '<leader>gd', group = 'Git Diffview…' },
                { '<leader>gdv', '<cmd>DiffviewOpen -uno<cr>', desc = 'Diffview for tracked files' },
                { '<leader>gdm', '<cmd>DiffviewOpen origin/HEAD...HEAD -uno<cr>', desc = 'Diffview to main branch' },
                { '<leader>gdh', '<cmd>DiffviewFileHistory %<cr>', desc = 'Current file history' },
                { '<leader>gdb', '<cmd>DiffviewFileHistory<cr>', desc = 'Current branch history' },
            }
        end,
    }
}
