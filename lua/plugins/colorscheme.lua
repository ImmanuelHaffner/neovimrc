return {
    { 'overcache/NeoSolarized', priority = 1000, config = function() --[[ vim.cmd.colorscheme('NeoSolarized') ]] end },
    { 'binhtran432k/dracula.nvim', priority = 1000, config = function() --[[ vim.cmd.colorscheme('dracula') ]] end, },
    { 'oxfist/night-owl.nvim',
        priority = 1000,
        config = function()
            require'night-owl'.setup{
                -- These are the default settings
                bold = true,
                italics = true,
                underline = true,
                undercurl = true,
                transparent_background = false,
            }
            local palette = require'night-owl.palette'
            local function hl(id, name, def)
                vim.api.nvim_set_hl(id, name, def)
            end

            -- Tune the night-owl colorscheme
            vim.api.nvim_create_autocmd('ColorScheme', {
                pattern = 'night-owl',
                callback = function()
                    -- Don't show fill char for deleted diff sections.  We will color fill the space instead.
                    vim.opt.fillchars:append{ diff = ' ' }

                    -- Make comments a bit brighter, so they are easier to read.
                    hl(0, 'Comment', { fg = palette.gray5, italic = true })

                    -- Make string literals differ from special comments and keywords.
                    hl(0, 'String', { fg = palette.orange })

                    -- Miscellaneous
                    hl(0, 'ColorColumn', { bg = '#331c1c', })
                    hl(0, 'CursorColumn', { bg = '#2d3a4a', })
                    hl(0, 'CursorLine', { bg = '#2d3a4a', cterm = {}, underline = false })

                    -- Diff view
                    hl(0, 'DiffAdd', { fg = 'NONE', bg = '#0f2909', })  -- bg a dim green
                    hl(0, 'DiffDelete', { fg = 'NONE', bg = '#331c1c', })  -- bg a dim red
                    hl(0, 'DiffChange', { fg = 'NONE', bg = '#242418', })  -- bg a dim gray-ish yellow
                    hl(0, 'DiffText', { fg = 'NONE', bg = '#343400', })  -- bg a brighter yellow


                    -- Gitsign current line blame
                    hl(0, 'GitSignsCurrentLineBlame', { fg = palette.gray6, })

                    -- nvim-cmp
                    hl(0, 'CmpItemAbbr', { fg = palette.fg, bg = 'NONE', })
                    hl(0, 'CmpItemAbbrMatch', { fg = palette.blue, bold = true })
                    hl(0, 'CmpItemAbbrMatchFuzzy', { fg = palette.blue, bold = true })
                    hl(0, 'CmpItemKindFunction', { fg = palette.blue, bg = 'NONE', })
                    hl(0, 'CmpItemKindMethod', { fg = palette.blue, bg = 'NONE', })
                    hl(0, 'CmpItemKindVariable', { fg = palette.orange, bg = 'NONE', })
                    hl(0, 'CmpItemKindProperty', { fg = palette.orange, bg = 'NONE', })
                    hl(0, 'CmpItemKindKeyword', { fg = palette.magenta, bg = 'NONE', })
                    hl(0, 'CmpItemKindSnippet', { fg = palette.magenta, bg = 'NONE', })
                    hl(0, 'CmpItemKindOperator', { fg = palette.magenta, bg = 'NONE', })
                    hl(0, 'CmpItemKindInterface', { fg = palette.cyan2, bg = 'NONE', })
                    hl(0, 'CmpItemKindStruct', { fg = palette.cyan2, bg = 'NONE', })
                    hl(0, 'CmpItemKindEnum', { fg = palette.cyan2, bg = 'NONE', })
                    hl(0, 'CmpItemKindModule', { fg = palette.fg, bg = 'NONE', })
                    hl(0, 'CmpItemKindFile', { fg = palette.fg, bg = 'NONE', })
                    hl(0, 'CmpItemKindFolder', { fg = palette.fg, bg = 'NONE', })

                    -- vim-notify
                    hl(0, 'NotifyBackground', { fg = palette.fg, bg = palette.bg, blend = 100 })
                    hl(0, 'NotifyERRORBorder', { fg = palette.error_red, bg = palette.bg, blend = 100 })
                    hl(0, 'NotifyWARNBorder', { fg = palette.orange, bg = palette.bg, blend = 100 })
                    hl(0, 'NotifyINFOBorder', { fg = palette.blue, bg = palette.bg, blend = 100 })
                    hl(0, 'NotifyDEBUGBorder', { fg = palette.cyan2, bg = palette.bg, blend = 100 })
                    hl(0, 'NotifyTRACEBorder', { fg = palette.magenta, bg = palette.bg, blend = 100 })
                    hl(0, 'NotifyERRORBody', { fg = palette.error_red, bg = palette.bg, blend = 100 })
                    hl(0, 'NotifyWARNBody', { fg = palette.orange, bg = palette.bg, blend = 100 })
                    hl(0, 'NotifyINFOBody', { fg = palette.blue, bg = palette.bg, blend = 100 })
                    hl(0, 'NotifyDEBUGBody', { fg = palette.cyan2, bg = palette.bg, blend = 100 })
                    hl(0, 'NotifyTRACEBody', { fg = palette.magenta, bg = palette.bg, blend = 100 })
                end,
            })

            -- Enable the colorscheme.  This call must be the last statement in `config()`
            vim.cmd.colorscheme'night-owl'
        end,
    },
}
