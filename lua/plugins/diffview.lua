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
            local dv = require'diffview'
            require'which-key'.add{
                { '<leader>gd', group = 'Git Diffview…' },
                { '<leader>gdv', function() dv.open{ '-uno' } end, desc = 'Unstaged changes' },
                { '<leader>gdm', function() dv.open{ 'origin/HEAD...HEAD', '-uno' } end,
                    desc = 'Changes since merge-base' },
                { '<leader>gdh', function() dv.file_history(nil, { '%' }) end, desc = 'Current file history' },
                { '<leader>gdb', function() dv.file_history(nil, {}) end, desc = 'Current branch history' },
            }
        end,
    }
}
