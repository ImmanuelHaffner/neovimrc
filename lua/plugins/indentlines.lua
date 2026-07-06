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

            -- Disable indent guides wherever markview is rendering (markdown, codecompanion,
            -- mdx, Telescope previews, …). We hook markview's own attach/detach events so the
            -- set of affected buffers always matches markview's, regardless of filetype.
            local group = vim.api.nvim_create_augroup('ibl_markview', { clear = true })
            vim.api.nvim_create_autocmd('User', {
                pattern = 'MarkviewAttach',
                group = group,
                callback = function(args)
                    local bufnr = args.data and args.data.buffer
                    if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
                        ibl.setup_buffer(bufnr, { enabled = false })
                    end
                end,
            })
            vim.api.nvim_create_autocmd('User', {
                pattern = 'MarkviewDetach',
                group = group,
                callback = function(args)
                    local bufnr = args.data and args.data.buffer
                    if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
                        ibl.setup_buffer(bufnr, { enabled = true })
                    end
                end,
            })
        end,
    },
}
