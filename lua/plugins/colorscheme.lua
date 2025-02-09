return {
    { 'overcache/NeoSolarized', priority = 1000, config = function() --[[ vim.cmd.colorscheme('NeoSolarized') ]] end },
    { 'binhtran432k/dracula.nvim', priority = 1000, config = function() --[[ vim.cmd.colorscheme('dracula') ]] end, },
    { 'oxfist/night-owl.nvim',
        priority = 1000,
        config = function()
            -- Don't show fill char for deleted diff sections.  We will color fill the space instead.
            vim.opt.fillchars:append{ diff = ' ' }

            -- Tune the night-owl color scheme
            vim.api.nvim_create_autocmd('ColorScheme', {
                pattern = 'night-owl',
                callback = function()
                    vim.cmd[[
                    " Highlight groups for diff view
                    hi! DiffAdd guifg=#859900 guibg=#002b36
                    hi! DiffDelete guifg=#848586 guibg=#331c1c
                    hi! DiffChange guifg=NONE guibg=#002b36 gui=NONE cterm=NONE
                    hi! DiffText guifg=NONE guibg=NONE gui=undercurl guisp=#b58900
                    hi! ColorColumn guibg=#331c1c
                    hi! CursorColumn guibg=#2d3a4a
                    hi! CursorLine guibg=#2d3a4a
                    ]]
                end,
            })

            -- Enable the colorscheme.  This call must be the last statement in `config()`
            vim.cmd.colorscheme'night-owl'
        end,
    },
}
