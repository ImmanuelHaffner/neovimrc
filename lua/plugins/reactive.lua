return {
    {
        'rasulomaroff/reactive.nvim',
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

            -- reactive redraws synchronously on every ModeChanged.  `:normal` run inside `nvim_buf_call` or
            -- `nvim_win_call` while the user is in Insert mode flips i → n → i once per call, and the fold upkeep
            -- of CodeCompanion and MCPHub issues bursts of those whenever a tool finishes: one full redraw per
            -- flip, each re-highlighting the chat, stalled the editor for seconds.  Coalesce a burst into one
            -- apply for the mode it settles in, which then usually changes nothing and skips the redraw.
            local Highlight = require'reactive.highlight'
            local Snapshot = require'reactive.snapshot'
            local apply, pending = Highlight.apply, false
            Highlight.apply = function(self)
                if pending then return end
                pending = true
                vim.schedule(function()
                    pending = false
                    local mode = vim.api.nvim_get_mode().mode
                    if Snapshot.to ~= mode then
                        Snapshot:set_modes(Snapshot.to, mode)
                    end
                    local snap = Snapshot:gen()
                    apply(self, { hl = snap.hl, winhl = snap.winhl.current, winid = vim.api.nvim_get_current_win() })
                end)
            end
        end,
    }
}
