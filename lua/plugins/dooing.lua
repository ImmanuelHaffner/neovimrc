return {
    {
        -- 'atiladefreitas/dooing',
        'ImmanuelHaffner/dooing',
        branch = 'dev',
        dev = true,
        dependencies = {
            'folke/which-key.nvim',
            {
                'ImmanuelHaffner/dooing-sync.nvim',
                branch = 'main',
                dev = true,
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
                    dimensions = function()
                        local nvul = require'nvu.layout'
                        return {
                            width = nvul.adaptive_extent{
                                frac = .6,
                                extent = vim.o.columns,
                                min = 30,
                                max = 120,
                            },
                            height = nvul.adaptive_extent{
                                frac = .7,
                                extent = vim.o.lines,
                                min = 10,
                            },
                        }
                    end,
                },
                ui = {
                    style = 'modern',
                },
                quick_keys = true,
            }

            require'which-key'.add{
                { '<leader>tn', ':Dooing<cr>', desc = 'Open Todo notes' },
            }
        end,
    }
}
