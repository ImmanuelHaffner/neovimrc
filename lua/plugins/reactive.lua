return {
    { 'rasulomaroff/reactive.nvim',
        config = function()
            local reactive = require'reactive'
            reactive.add_preset{
                name = 'default',
                init = function()
                    -- making our cursor to use `MyCursor` highlight group
                    vim.opt.guicursor:append('a:MyCursor')
                end,
                lazy = false,
                priority = 100,
                modes = {
                    n = {
                        winhl = {
                            -- we use `winhl` because we want to highlight CursorLine only in a current window, not in all of them
                            -- if you want to change global highlights, use the `hl` field instead.
                            CursorLine = { bg = '#102947' },
                            CursorColumn = { bg = '#102947' },
                            CursorLineNr = { fg = '#0b1d33', bg = '#98c379', bold = true },
                        },
                    },
                    no = {
                        -- You can also specify winhl and hl that will be applied with every operator
                        winhl = {},
                        hl = {},
                        operators = {
                            d = {
                                winhl = {
                                    CursorLine = { bg = '#450a0a' },
                                },
                                hl = {
                                    MyCursor = { bg = '#fca5a5' },
                                },
                            },
                            y = {
                                winhl = {
                                    CursorLine = { bg = '#422006' },
                                },
                                hl = {
                                    MyCursor = { bg = '#fdba74' },
                                }
                            }
                        }
                    },
                    i = {
                        winhl = {
                            CursorLine = { bg = '#0b1d33' },
                            CursorLineNr = { fg = '#0b1d33', bg = '#61afef', bold = true },
                        },
                        hl = {
                            MyCursor = { bg = '#ff6b6b' },
                        },
                    },
                    [{ 'v', 'V', '\x16' }] = {
                        winhl = {
                            CursorLineNr = { fg = '#0b1d33', bg = '#c678dd', bold = true },
                        },
                    },
                    c = {
                        winhl = {
                            CursorLine = { bg = 'NONE' },
                            CursorLineNr = { fg = 'NONE', bg = 'NONE', bold = true },
                        },
                    },
                    ['R'] = {
                        winhl = {
                            CursorLineNr = { fg = 'NONE', bg = '#e06c75', bold = true },
                        },
                    }
                },
            }
        end,
    }
}
