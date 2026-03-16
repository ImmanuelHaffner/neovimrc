return {
    {
        'atiladefreitas/dooing',
        commit = 'dc40b23e234f4f727b3f2519eb495b6088f848fb',
        dependencies = {
            'folke/which-key.nvim',
            {
                'ImmanuelHaffner/dooing-sync.nvim',
                tag = 'dev',
            }
        },
        config = function()
            -- Sync setup FIRST: pulls from Google Drive, merges, writes to save_path.
            require'dooing-sync'.setup{
                gdrive_folder_id = '1D_-7EtHBIk3zuZZXw1wqHBb_lwykDmcv',
                notify = 'changes',
            }

            -- Dooing setup SECOND: loads the now-current JSON.
            require'dooing'.setup{
                keymaps = {
                    toggle_window = false,
                    toggle_priority = 'x',
                },
                window = {
                    position = 'bottom-right',
                },
            }

            require'which-key'.add{
                { '<leader>tn', ':Dooing<cr>', desc = 'Open Todo notes' },
            }
        end,
    }
}
