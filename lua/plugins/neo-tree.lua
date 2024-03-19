return {
    { 'nvim-neo-tree/neo-tree.nvim',
        branch = 'v3.x',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
            'MunifTanjim/nui.nvim',
            '3rd/image.nvim', -- Optional image support in preview window: See `# Preview Mode` for more information
            'folke/which-key.nvim',
        },
        config = function()
            local neotree = require'neo-tree'
            neotree.setup{
                window = {
                    mappings = {
                        ['<F2>'] = 'close_window',
                    },
                },
            }
            require'which-key'.register({
                ['<F2>'] = { ':Neotree action=focus reveal<CR>', 'Open Neo-tree (filesystem)' },
            }, { silent = true })
        end
    },
}
