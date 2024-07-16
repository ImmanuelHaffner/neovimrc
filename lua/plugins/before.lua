return {
    { 'bloznelis/before.nvim',
        dependencies = {
            'nvim-telescope/telescope.nvim',
        },
        config = function()
            require('before').setup()
            require'telescope'.load_extension('before')
        end,
        keys = {
            { '[e', function() require'before'.jump_to_last_edit() end, desc = 'Jump to last edit location' },
            { ']e', function() require'before'.jump_to_next_edit() end, desc = 'Jump to next edit location' },
            { '<leader>e', function() require'before'.show_edits_in_quickfix() end, desc = 'Show edits in Quickfix window' },
            { '<leader>fe', function() require'before'.show_edits_in_telescope() end, desc = 'Show edits in Telescope' },
        },
    }
}
