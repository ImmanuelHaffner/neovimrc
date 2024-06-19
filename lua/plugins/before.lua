return {
    { 'bloznelis/before.nvim',
        dependencies = {
            'folke/which-key.nvim',
            'nvim-telescope/telescope.nvim',
        },
        config = function()
            local before = require('before')
            before.setup()
            require'telescope'.load_extension('before')

            local wk = require'which-key'
            wk.register({
                ['['] = {
                    e = { before.jump_to_last_edit, 'Jump to last edit location' },
                },
                [']'] = {
                    e = { before.jump_to_next_edit, 'Jump to next edit location' },
                },
                ['<leader>'] = {
                    e = { before.show_edits_in_quickfix, 'Show edits in Quickfix window' },
                    f = {
                        e = { before.show_edits_in_telescope, 'Show edits in Telescope' },
                    }
                }
            }, { silent = true })
        end
}
}
