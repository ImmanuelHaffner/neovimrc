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
    },
    {
        -- This plugin provides jumps to *all* kinds of windows, including *floating* windows.  This is quite
        -- undesirable.  Load this plugin for NeoTree, but don't bind it.  Use `yorickpeterse/nvim-window` instead.
        's1n7ax/nvim-window-picker',
        name = 'window-picker',
        event = 'VeryLazy',
        version = '2.*',

        config = function()
            require'window-picker'.setup{
                hint = 'floating-big-letter',
                show_prompt = false,
                selection_chars='awftnuyorsei',
            }
        end,
    },
}
