return {
    { 'overcache/NeoSolarized', priority = 1000, config = function() --[[ vim.cmd.colorscheme('NeoSolarized') ]] end },
    { 'binhtran432k/dracula.nvim', priority = 1000, config = function() --[[ vim.cmd.colorscheme('dracula') ]] end, },
    { 'oxfist/night-owl.nvim',
        priority = 1000,
        config = function()
            vim.cmd.colorscheme'night-owl'
            vim.cmd[[
                highlight! DiffAdd guifg=#859900 guibg=#002b36
                highlight! DiffDelete guifg=#848586 guibg=#331c1c
                highlight! DiffChange guifg=#b58900 guibg=#002b36 gui=NONE cterm=NONE
                highlight! DiffText guifg=NONE guibg=NONE gui=undercurl guisp=#b58900
                highlight! ColorColumn guibg=#331c1c
                highlight! CursorColumn guibg=#2d3a4a
                highlight! CursorLine guibg=#2d3a4a
            ]]
            vim.opt.fillchars:append{ diff = ' ' }
        end,
    },
}
