return {
    { 'overcache/NeoSolarized', priority = 1000, config = function() --[[ vim.cmd.colorscheme('NeoSolarized') ]] end },
    { 'binhtran432k/dracula.nvim', priority = 1000, config = function() --[[ vim.cmd.colorscheme('dracula') ]] end, },
    { 'oxfist/night-owl.nvim',
        priority = 1000,
        config = function()
            vim.cmd.colorscheme'night-owl'
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
            vim.opt.fillchars:append{ diff = ' ' }
        end,
    },
}
