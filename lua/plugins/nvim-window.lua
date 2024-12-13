return {
    {
        'yorickpeterse/nvim-window',
        opts = {
            chars = {
                -- For Colemak Mod-DH
                'a', 'w', 'f', 't', 'n', 'u', 'y', 'o', 'r', 's', 'e', 'i',
            },
        },
        keys = {
            { '<leader><leader>', function() require'nvim-window'.pick() end, desc = 'Jump to window' },
        },
    }
}
