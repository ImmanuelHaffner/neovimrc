return {
    {
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
        keys = {
            { '<leader>w', group = 'Window picker' },
            { '<leader>ww', function() require'window-picker'.pick_window() end, desc = 'Jump to window' },
        },
    }
}
