return {
    { 'lewis6991/gitsigns.nvim',
        tag = 'v0.9.0',
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
                    wk.add{
                        group = 'Gitsign navigation',
                        { ']h', function()
                            if vim.wo.diff then return ']c' end
                            vim.schedule(function() gs.next_hunk() end)
                            return '<Ignore>'
                            end, desc = 'Next Git hunk'
                        },
                        { '[h', function()
                            if vim.wo.diff then return ']c' end
                            vim.schedule(function() gs.prev_hunk() end)
                            return '<Ignore>'
                            end, desc = 'Previous Git hunk' },
                    }

                    -- Actions
                    wk.add{
                        { '<leader>g', group = 'Git' },
                        { '<leader>gs', group = 'Gitsign' },
                        {
                            mode = { 'n', 'v' },
                            { '<leader>gss', gs.stage_hunk, desc = 'Stage hunk' },
                            { '<leader>gsr', gs.reset_hunk, desc = 'Reset hunk' },
                        },
                        { '<leader>gsu', gs.undo_stage_hunk, desc = 'Undo stage hunk' },
                        { '<leader>gsS', gs.stage_buffer, desc = 'Stage buffer' },
                        { '<leader>gsR', gs.reset_buffer, desc = 'Reset buffer' },
                        { '<leader>gsp', gs.preview_hunk, desc = 'Preview hunk' },
                        { '<leader>gsb', function() gs.blame_line{full=false} end, desc = 'Blame current line' },
                        { '<leader>gsd', gs.diffthis, desc = 'Diff current hunk' },
                        { '<leader>gsD', function() gs.diffthis('~') end, desc = 'Diff current file' },
                        {
                            { '<leader>gst', group = 'Toggles' },
                            { '<leader>gstb', gs.toggle_current_line_blame, desc = 'Toggle current line blame' },
                            { '<leader>gstd', gs.toggle_deleted, desc = 'Toggle deleted' },
                        },
                    }

                    -- Text object
                    wk.add{
                        group = 'Gitsign',
                        mode = { 'o', 'x' },
                        { 'gh', ':<C-U>Gitsigns select_hunk<CR>', desc = 'Gitsign select hunk' },
                    }
                end
            }
        end,
    },
}
