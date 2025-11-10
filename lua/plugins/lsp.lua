return {
    { 'ray-x/lsp_signature.nvim',
        config = function()
            require'lsp_signature'.setup{
                bind = true, -- This is mandatory, otherwise border config won't get registered.
                handler_opts = { border = 'rounded' },
                select_signature_key = '<C-n>',
            }
        end,
    },
    {
        'rachartier/tiny-inline-diagnostic.nvim',
        event = 'LspAttach', -- `VeryLazy` or `LspAttach`
        priority = 1000, -- needs to be loaded in first
        config = function()
            vim.diagnostic.config({
                virtual_text = false,
            })
            require'tiny-inline-diagnostic'.setup()
        end
    },
    { 'https://git.sr.ht/~whynothugo/lsp_lines.nvim',
        enabled = false, -- avoid for now as it does not play well with others
        config = function()
            require'lsp_lines'.setup()
            vim.diagnostic.config({
                virtual_text = false, -- Disable virtual_text since it's redundant due to lsp_lines.
            })
        end
    },
    { 'williamboman/mason.nvim',
        build = ':MasonUpdate',
        config = function()
            require'mason'.setup{
                automatic_installation = true -- automatically install servers listed in lspconfig
            }
        end,
    },
    { 'williamboman/mason-lspconfig.nvim', dependencies = { 'williamboman/mason.nvim' } },
    { 'nvim-lua/lsp-status.nvim',
        config = function()
            local lsp_status = require'lsp-status'
            lsp_status.config{
                diagnostics = false,
                show_filename = false,
                status_symbol = '',
                current_function = false,  -- we use navic for that
            }
        end
    },
    {
        'scalameta/nvim-metals',
        ft = { 'scala', 'sbt', 'java' },
        opts = function()
            local metals_config = require('metals').bare_config()
            local global_config = vim.lsp.config['*']
            if global_config and global_config.on_attach then
                metals_config.on_attach = global_config.on_attach
            end

            return metals_config
        end,
        config = function(self, metals_config)
            local nvim_metals_group = vim.api.nvim_create_augroup('nvim-metals', { clear = true })
            vim.api.nvim_create_autocmd('FileType', {
                pattern = self.ft,
                callback = function()
                    require('metals').initialize_or_attach(metals_config)
                end,
                group = nvim_metals_group,
            })
        end
    },
    {
        -- List of further plugins that don't need configuration.
        'barreiroleo/ltex_extra.nvim',
        'https://git.sr.ht/~p00f/clangd_extensions.nvim',
        'SmiteshP/nvim-navic',
    },
}
