return {
    { 'hrsh7th/nvim-cmp',
        dependencies = {
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-path',
            'hrsh7th/cmp-cmdline',
            'hrsh7th/cmp-omni',
            'petertriho/cmp-git',
            'https://git.sr.ht/~p00f/clangd_extensions.nvim',
        },
        config = function()
            local cmp = require'cmp'
            local types = require'cmp.types'
            cmp.setup{
                sources = cmp.config.sources({
                    { name = 'nvim_lsp' },
                    {
                        name = 'omni',
                        option = {
                            disable_omnifuncs = { 'v:lua.vim.lsp.omnifunc' }
                        }
                    },
                }, {
                    { name = 'buffer' },
                }),
                window = {
                    completion = cmp.config.window.bordered(),
                    documentation = cmp.config.window.bordered(),
                },
                mapping = cmp.mapping.preset.insert{
                    ['<C-b>'] = cmp.mapping.scroll_docs(8),
                    ['<C-f>'] = cmp.mapping.scroll_docs(-8),
                    ['<C-n>'] = cmp.mapping.select_next_item(),
                    ['<C-p>'] = cmp.mapping.select_prev_item(),
                    ['<C-e>'] = cmp.mapping.abort(),
                    ['<CR>']  = cmp.mapping.confirm({ select = false }),
                    ['<C-y>'] = cmp.mapping.confirm({ select = false }),
                    ['<C-Space>'] = cmp.mapping.complete(),
                },
                sorting = {
                    comparators = {
                        cmp.config.compare.offset,
                        cmp.config.compare.exact,
                        cmp.config.compare.recently_used,
                        require'clangd_extensions.cmp_scores',
                        cmp.config.compare.kind,
                        cmp.config.compare.sort_text,
                        cmp.config.compare.length,
                        cmp.config.compare.order,
                    },
                },
                formatting = {
                    -- format = function(entry, vim_item)
                    --     vim_item.abbr = string.sub(vim_item.abbr, 1, 40)
                    --     return vim_item
                    -- end
                    format = function(_, item)
                        local win_width = vim.api.nvim_win_get_width(0)

                        local truncate = function(str, frac)
                            if str == nil then return str end
                            local max_len = math.floor(frac * win_width)
                            if #str > max_len then
                                return vim.fn.strcharpart(str, 0, max_len - 1) .. '…'
                            else
                                return str
                            end
                        end

                        item.abbr = truncate(item.abbr, .2)
                        item.menu = truncate(item.menu, .3)

                        return item
                    end
                },
                completion = {
                    autocomplete = {
                        types.cmp.TriggerEvent.TextChanged,
                    },
                    keyword_length = 3,
                },
            }
            cmp.setup.filetype('gitcommit', {
                sources = cmp.config.sources({
                    { name = 'git' },
                }, {
                    { name = 'buffer' },
                })
            })
        end,
        keys = {
            {
                '<C-x><C-o>',
                function() require'cmp'.complete() end,
                desc = 'Auto-complete',
                mode = 'i',
            }
        }
    },
}
