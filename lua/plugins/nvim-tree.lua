return {
    { 'kyazdani42/nvim-tree.lua',
        enabled = false,
        tag = 'nightly',
        dependencies = {
            'folke/which-key.nvim',
            'kyazdani42/nvim-web-devicons',
        },
        config = function()
            require'nvim-tree'.setup{
                view = { width = 40 },
            }
        end,
        keys = {
            { '<F2>', '<cmd>NvimTreeToggle<cr>', desc = 'Toggle NvimTree' },
        }
    },
}
