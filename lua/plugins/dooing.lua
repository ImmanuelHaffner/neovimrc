return {
    {
        'ImmanuelHaffner/dooing',
        dev = true,
        branch = 'dev',
        dependencies = {
            'folke/which-key.nvim',
            {
                'ImmanuelHaffner/dooing-sync.nvim',
                dev = true,
                branch = 'dev',
            }
        },
        config = function()
            require'dooing-sync'.setup{
                gdrive_folder_id = '1D_-7EtHBIk3zuZZXw1wqHBb_lwykDmcv',
                notify = 'changes',
                sync = {
                    sync_on_close = false,   -- sync before exiting (VimLeavePre)
                }
            }

            -- Dooing setup SECOND: loads the now-current JSON.
            require'dooing'.setup{
                keymaps = {
                    toggle_window = false,
                    toggle_priority = 'x',
                },
                window = {
                    position = 'bottom-right',
                    border = 'double',
                },
                quick_keys = true,
            }

            require'which-key'.add{
                { '<leader>tn', ':Dooing<cr>', desc = 'Open Todo notes' },
            }
        end,
    }
}
