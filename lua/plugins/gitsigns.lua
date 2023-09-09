return {
    { 'lewis6991/gitsigns.nvim',
        tag = 'release',
        dependencies = { 'folke/which-key.nvim' },
        config = function()
            require'gitsigns'.setup{
                on_attach = function(bufnr)
                    local gs = package.loaded['gitsigns']
                    local wk = require'which-key'

                    local function map(mode, l, r, opts)
                        opts = opts or {}
                        opts.buffer = bufnr
                        vim.keymap.set(mode, l, r, opts)
                    end

                    -- Navigation
                    wk.register({
                        name = 'Gitsign navigation',
                        [']c'] = { function()
                            if vim.wo.diff then return ']c' end
                            vim.schedule(function() gs.next_hunk() end)
                            return '<Ignore>'
                            end, 'Next Git hunk' },
                        ['[c'] = { function()
                            if vim.wo.diff then return ']c' end
                            vim.schedule(function() gs.prev_hunk() end)
                            return '<Ignore>'
                            end, 'Previous Git hunk' },
                    }, { buffer = bufnr, expr = true })

                    -- Actions
                    wk.register({
                        name = 'Gitsign',
                        s = { gs.stage_hunk, 'Stage hunk' },
                        r = { gs.reset_hunk, 'Reset hunk' },
                        u = { gs.undo_stage_hunk, 'Undo stage hunk' },
                        S = { gs.stage_buffer, 'Stage buffer' },
                        R = { gs.reset_buffer, 'Reset buffer' },
                        p = { gs.preview_hunk, 'Preview hunk' },
                        b = { function() gs.blame_line{full=true} end, 'Blame current line' },
                        d = { gs.diffthis, 'Diff current hunk' },
                        D = { function() gs.diffthis('~') end, 'Diff current file' },
                        t = {
                            name = 'Toggles',
                            b = { gs.toggle_current_line_blame, 'Toggle current line blame' },
                            d = { gs.toggle_deleted, 'Toggle deleted' },
                        },
                    }, { prefix = '<leader>gs', buffer = bufnr })
                    -- Actions - Visual mode
                    wk.register({
                        name = 'Gitsign',
                        s = { gs.stage_hunk, 'Stage hunk' },
                        r = { gs.reset_hunk, 'Reset hunk' },
                    }, { mode = 'v', prefix = '<leader>gs', buffer = bufnr })

                    -- Text object
                    wk.register({
                        name = 'Gitsign',
                        ['gh'] = { ':<C-U>Gitsigns select_hunk<CR>', 'Gitsign select hunk' },
                    }, { mode = { 'o', 'x' }, buffer = bufnr })
                end
            }
        end,
    },
}
