return {
    { 'hedyhli/outline.nvim',
        lazy = false,
        keys = {
            { '<leader>lo', '<cmd>Outline<CR>', desc = 'Toggle outline' },
        },
        config = function()
            require'outline'.setup{
                outline_window = {
                    position = 'left',
                },
            }
        end,
    },
}
