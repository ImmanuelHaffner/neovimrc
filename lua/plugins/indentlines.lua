return {
    { 'lukas-reineke/indent-blankline.nvim',
        dependencies = {
            'nvim-treesitter/nvim-treesitter',
        },
        main = 'ibl',
        config = function()
            local ibl = require'ibl'
            local highlight = {
                'RainbowRed',
                'RainbowYellow',
                'RainbowBlue',
                'RainbowOrange',
                'RainbowGreen',
                'RainbowViolet',
                'RainbowCyan',
            }

            local hooks = require 'ibl.hooks'
            -- create the highlight groups in the highlight setup hook, so they are reset
            -- every time the colorscheme changes
            hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
                vim.api.nvim_set_hl(0, 'RainbowRed', { fg = '#E06C75' })
                vim.api.nvim_set_hl(0, 'RainbowYellow', { fg = '#E5C07B' })
                vim.api.nvim_set_hl(0, 'RainbowBlue', { fg = '#61AFEF' })
                vim.api.nvim_set_hl(0, 'RainbowOrange', { fg = '#D19A66' })
                vim.api.nvim_set_hl(0, 'RainbowGreen', { fg = '#98C379' })
                vim.api.nvim_set_hl(0, 'RainbowViolet', { fg = '#C678DD' })
                vim.api.nvim_set_hl(0, 'RainbowCyan', { fg = '#56B6C2' })
            end)

            -- Stable rainbow coloring: color each indent guide by its ABSOLUTE indent
            -- level, not by ibl's viewport-relative counter.
            --
            -- Why this is needed: ibl only renders the visible viewport and colors guides
            -- with a per-line counter that restarts at 1 on every rendered line (see
            -- ibl/virt_text.lua `indent_index`). When a shallow enclosing level scrolls out
            -- of view, the deepest visible guide is recomputed as "level 1" and recolored.
            -- Result: guide colors flip as you scroll.
            --
            -- Fix: in the VIRTUAL_TEXT hook we recompute each guide's color from its absolute
            -- display column (col / shiftwidth), which never changes with scrolling. We add
            -- back `leftcol` so it also holds under horizontal scroll (ibl trims left cells
            -- via fix_horizontal_scroll before this hook runs).
            local function is_rainbow(hl)
                return type(hl) == 'string' and hl:match('^Rainbow') ~= nil
            end

            hooks.register(hooks.type.VIRTUAL_TEXT, function(_, bufnr, _, virt_text)
                local sw = vim.api.nvim_get_option_value('shiftwidth', { buf = bufnr })
                local ts = vim.api.nvim_get_option_value('tabstop', { buf = bufnr })
                if sw == 0 then sw = ts end
                if sw == 0 then sw = 1 end

                -- Horizontal-scroll offset of the window showing this buffer.
                local leftcol = 0
                local win = vim.fn.win_findbuf(bufnr)[1]
                if win then
                    leftcol = vim.api.nvim_win_call(win, function()
                        return vim.fn.winsaveview().leftcol or 0
                    end)
                end

                -- `col` tracks the display column of each virtual-text cell (0-based).
                local col = leftcol
                for _, cell in ipairs(virt_text) do
                    local hls = cell[2]
                    if type(hls) == 'table' then
                        for idx, hl in ipairs(hls) do
                            if is_rainbow(hl) then
                                local level = math.floor(col / sw)  -- absolute indent level, 0-based
                                hls[idx] = highlight[(level % #highlight) + 1]
                            end
                        end
                    end
                    col = col + vim.fn.strdisplaywidth(cell[1] or '')
                end
                return virt_text
            end)

            ibl.setup{
                indent = {
                    char = '│',
                    highlight = highlight,
                },
                exclude = {
                    filetypes = {
                        'fbsqltest',
                        'fbplannertest',
                    },
                },
            }

            -- Disable indent guides wherever the Markdown renderer is rendering (markdown,
            -- codecompanion, mdx, Telescope previews, …).  Hooking the renderer's own attach and detach
            -- keeps the set of affected buffers matching its own, regardless of filetype.  Only markview
            -- ever detaches, so under render-markdown a buffer keeps its guides off for its lifetime.
            local group = vim.api.nvim_create_augroup('ibl_mdrender', { clear = true })
            local mdrender = require'mdrender'
            mdrender.on_attach(group, function(bufnr) ibl.setup_buffer(bufnr, { enabled = false }) end)
            mdrender.on_detach(group, function(bufnr) ibl.setup_buffer(bufnr, { enabled = true }) end)
        end,
    },
}
