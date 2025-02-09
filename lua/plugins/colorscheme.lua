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

                    " Highlight groups for nvim-cmp
                    hi! CmpItemAbbr guifg=#d6deeb guibg=NONE
                    hi! CmpItemAbbrMatch guifg=#82AAFF gui=bold
                    hi! CmpItemAbbrMatchFuzzy guifg=#82AAFF gui=bold
                    hi! CmpItemKindFunction guifg=#82AAFF guibg=NONE
                    hi! CmpItemKindMethod guifg=#82AAFF guibg=NONE
                    hi! CmpItemKindVariable guifg=#F78C6C guibg=NONE
                    hi! CmpItemKindProperty guifg=#F78C6C guibg=NONE
                    hi! CmpItemKindKeyword guifg=#C792EA guibg=NONE
                    hi! CmpItemKindSnippet guifg=#C792EA guibg=NONE
                    hi! CmpItemKindOperator guifg=#C792EA guibg=NONE
                    hi! CmpItemKindInterface guifg=#7FDBCA guibg=NONE
                    hi! CmpItemKindStruct guifg=#7FDBCA guibg=NONE
                    hi! CmpItemKindEnum guifg=#7FDBCA guibg=NONE
                    hi! CmpItemKindModule guifg=#d6deeb guibg=NONE
                    hi! CmpItemKindFile guifg=#d6deeb guibg=NONE
                    hi! CmpItemKindFolder guifg=#d6deeb guibg=NONE

                    " Highlight groups for vim-notify
                    hi! NotifyBackground guibg=#011627 guifg=#d6deeb blend=0
                    hi! NotifyERRORBorder guibg=#011627 guifg=#ef5350 blend=0
                    hi! NotifyWARNBorder guibg=#011627 guifg=#f78c6c blend=0
                    hi! NotifyINFOBorder guibg=#011627 guifg=#82AAFF blend=0
                    hi! NotifyDEBUGBorder guibg=#011627 guifg=#7FDBCA blend=0
                    hi! NotifyTRACEBorder guibg=#011627 guifg=#C792EA blend=0
                    hi! NotifyERRORBody guibg=#011627 guifg=#ef5350 blend=0
                    hi! NotifyWARNBody guibg=#011627 guifg=#f78c6c blend=0
                    hi! NotifyINFOBody guibg=#011627 guifg=#82AAFF blend=0
                    hi! NotifyDEBUGBody guibg=#011627 guifg=#7FDBCA blend=0
                    hi! NotifyTRACEBody guibg=#011627 guifg=#C792EA blend=0
                    ]]
                end,
            })

            -- Enable the colorscheme.  This call must be the last statement in `config()`
            vim.cmd.colorscheme'night-owl'
        end,
    },
}
