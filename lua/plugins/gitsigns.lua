return {
    { 'lewis6991/gitsigns.nvim',
        branch = 'main',
        dependencies = { 'folke/which-key.nvim' },
        config = function()
            require'gitsigns'.setup{
                signs = {
                    add          = { text = '┃' },
                    change       = { text = '┃' },
                    delete       = { text = '␡' },
                    topdelete    = { text = '␡' },
                    changedelete = { text = '✎' },
                    untracked    = { text = '┆' },
                },
                signs_staged = {
                    add          = { text = '┃' },
                    change       = { text = '┃' },
                    delete       = { text = '␡' },
                    topdelete    = { text = '␡' },
                    changedelete = { text = '✎' },
                    untracked    = { text = '┆' },
                },
                signs_staged_enable = true,
                on_attach = function(bufnr)
                    local gs = require'gitsigns'
                    local wk = require'which-key'

                    -- Navigation
                    wk.add({
                        { ']h', function()
                                if vim.wo.diff then return ']c' end
                                vim.schedule(function() gs.nav_hunk'next' end)
                                return '<Ignore>'
                            end,
                            desc = 'Next Git hunk'
                        },
                        { '[h', function()
                                if vim.wo.diff then return ']c' end
                                vim.schedule(function() gs.nav_hunk'prev' end)
                                return '<Ignore>'
                            end,
                            desc = 'Previous Git hunk'
                        },
                    }, { buffer = bufnr })

                    -- Actions
                    wk.add({
                        { '<leader>g', group = 'Git' },
                        { '<leader>gs', group = 'Gitsign' },
                        {
                            mode = { 'n', 'v' },
                            { '<leader>gss', gs.stage_hunk, desc = 'Stage hunk' },
                            { '<leader>gsr', gs.reset_hunk, desc = 'Reset hunk' },
                        },
                        { '<leader>gsu', gs.stage_hunk, desc = 'Undo stage hunk' },
                        { '<leader>gsS', gs.stage_buffer, desc = 'Stage buffer' },
                        { '<leader>gsR', gs.reset_buffer, desc = 'Reset buffer' },
                        { '<leader>gsp', gs.preview_hunk, desc = 'Preview hunk' },
                        { '<leader>gsb', function() gs.blame_line{full=false} end, desc = 'Blame current line' },
                        { '<leader>gsd', gs.diffthis, desc = 'Diff current hunk' },
                        { '<leader>gsD', function() gs.diffthis'~' end, desc = 'Diff current file' },
                        {
                            { '<leader>gst', group = 'Toggles' },
                            { '<leader>gstb', gs.toggle_current_line_blame, desc = 'Toggle current line blame' },
                            { '<leader>gstd', gs.preview_hunk_inline, desc = 'Toggle deleted' },
                        },
                    }, { buffer = bufnr })
                end
            }
        end,
    },
}
