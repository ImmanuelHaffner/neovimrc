return {
    { 'ray-x/lsp_signature.nvim',
        config = function()
            require'lsp_signature'.setup{
                bind = true, -- This is mandatory, otherwise border config won't get registered.
                handler_opts = { border = 'rounded' },
            }
        end,
    },
    { 'https://git.sr.ht/~whynothugo/lsp_lines.nvim',
        dependencies = { 'neovim/nvim-lspconfig' },
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
    { 'https://git.sr.ht/~p00f/clangd_extensions.nvim' },
    { 'neovim/nvim-lspconfig',
        dependencies = {
            'williamboman/mason-lspconfig.nvim',
            'folke/which-key.nvim',
            'https://git.sr.ht/~p00f/clangd_extensions.nvim',
        },
        config = function()
            local lsp = require'lspconfig'

            -- Use an on_attach function to only map the following keys
            -- after the language server attaches to the current buffer
            local on_attach = function(client, bufnr)
                -- Enable completion triggered by <c-x><c-o>
                vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

                if client.server_capabilities.goto_definition == true then
                    vim.api.nvim_buf_set_option(bufnr, "tagfunc", 'v:lua.vim.lsp.tagfunc')
                end

                if client.server_capabilities.document_formatting == true then
                    vim.api.nvim_buf_set_option(bufnr, 'formatexpr', 'v:lua.vim.lsp.formatexpr()')
                end


                -- Keymaps
                local wk = require'which-key'
                local buf = vim.lsp.buf
                wk.register({
                    name = 'LSP',
                    g = {
                        d = { function() buf.declaration() end, 'Goto declaration' },
                        D = { function() buf.definition() end, 'Goto definition' },
                        i = { function() buf.implementation() end, 'Goto implementation' },
                        t = { function() buf.type_definition() end, 'Goto type definition' },
                    },
                    h = {
                        h = { function() buf.hover() end, 'Tooltip for item under cursor' },
                        s = { function() buf.signature_help() end, 'Show signature help' },
                        r = { function() buf.references() end, 'Show references' },
                    },
                    ['rn'] = { function() buf.rename() end, 'Refactor rename item under cursor' },
                    ['ca'] = { function() buf.code_action() end, 'Perform code action for item under cursor' },
                    ['cf'] = { function() buf.formatting() end, 'Perform formatting (whole file)' },
                    ['<tab>'] = { '<cmd>ClangdSwitchSourceHeader<cr>', 'Switch between source/header file' },
                    ['s<tab>'] = { '<cmd>split<cr><cmd>ClangdSwitchSourceHeader<cr>', 'Open source/header file in horizontal split' },
                    ['v<tab>'] = { '<cmd>vsplit<cr><cmd>ClangdSwitchSourceHeader<cr>', 'Open source/header file in vertical split' },
                }, { prefix = '<leader>l', buffer = bufnr })
            end

            local capabilities = require'cmp_nvim_lsp'.default_capabilities()

            lsp['clangd'].setup{
                on_attach = function(client, bufnr)
                    on_attach(client, bufnr)
                    -- Clangd extensions
                    require("clangd_extensions.inlay_hints").setup_autocmd()
                    require("clangd_extensions.inlay_hints").set_inlay_hints()
                end,
                capabilities = capabilities,
            }

            lsp['ltex'].setup{
                on_attach = on_attach,
                capabilities = capabilities,
            }

            lsp['texlab'].setup{
                on_attach = on_attach,
                capabilities = capabilities,
            }

            lsp['pylsp'].setup{
                on_attach = on_attach,
                capabilities = capabilities,
                settings = {
                    pylsp = {
                        plugins = {
                            pycodestyle = {
                                ignore = { 'W391' },
                                maxLineLength = 120
                            }
                        }
                    }
                }
            }

            lsp['bashls'].setup{
                on_attach = on_attach,
                capabilities = capabilities,
            }
        end,
    },
}
