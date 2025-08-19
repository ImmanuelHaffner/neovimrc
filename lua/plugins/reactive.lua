return {
    { 'rasulomaroff/reactive.nvim',
        config = function()
            local reactive = require'reactive'
            local colors = require'theme'.colors()
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
                            CursorLine = { bg = colors.blue13 },
                            CursorColumn = { bg = colors.blue13 },
                            CursorLineNr = { fg = colors.bg, bg = colors.green, bold = true },
                        },
                    },
                    no = {
                        -- You can also specify winhl and hl that will be applied with every operator
                        winhl = {},
                        hl = {},
                        operators = {
                            d = {
                                winhl = {
                                    CursorLine = { bg = '#450a0a' },  -- red shade
                                },
                                hl = {
                                    MyCursor = { bg = colors.red },
                                },
                            },
                            y = {
                                winhl = {
                                    CursorLine = { bg = '#422006' },  -- orange shade
                                },
                                hl = {
                                    MyCursor = { bg = colors.orange },
                                }
                            }
                        }
                    },
                    i = {
                        winhl = {
                            CursorLine = { bg = colors.tab_active_bg },
                            CursorLineNr = { fg = colors.bg, bg = colors.blue, bold = true },
                        },
                        hl = {
                            MyCursor = { bg = colors.red },
                        },
                    },
                    [{ 'v', 'V', '\x16' }] = {
                        winhl = {
                            CursorLineNr = { fg = colors.bg, bg = colors.purple3, bold = true },
                        },
                    },
                    c = {
                        winhl = {
                            CursorLine = { bg = 'NONE' },
                            CursorLineNr = { fg = colors.bg, bg = colors.red2, bold = true },
                        },
                    },
                    ['R'] = {
                        winhl = {
                            CursorLineNr = { fg = colors.bg, bg = colors.light_red, bold = true },
                        },
                    }
                },
            }
        end,
    }
}
