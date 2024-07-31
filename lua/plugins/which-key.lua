return {
    { 'folke/which-key.nvim',
        tag = 'v3.6.0',
        opts = {
            modes = {
                o = false, -- Operator pending mode
                c = false, -- Command mode
                t = false, -- Terminal mode
            }
        },
        keys = {
            {
                '<leader>?',
                function() require'which-key'.show{ global = false } end,
                desc = 'Buffer Local Keymaps (which-key)',
            }
        }
    }
}
