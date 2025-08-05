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
        event = 'VeryLazy', -- Or `LspAttach`
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
    { 'neovim/nvim-lspconfig',
        dependencies = {
            'williamboman/mason-lspconfig.nvim',
            'folke/which-key.nvim',
            'https://git.sr.ht/~p00f/clangd_extensions.nvim',
            'nvim-lua/lsp-status.nvim',
            'barreiroleo/ltex_extra.nvim',
            'SmiteshP/nvim-navic',
        },
        config = function()
            local lsp = require'lspconfig'
            local lsp_status = require'lsp-status'
            local navic = require'nvim-navic'

            lsp_status.register_progress()

            -- Only log errors by default to avoid log file growing too quickly.
            vim.lsp.set_log_level'error'

            -- Use an on_attach function to only map the following keys
            -- after the language server attaches to the current buffer
            local on_attach = function(client, bufnr)
                -- Enable completion triggered by <c-x><c-o>
                vim.api.nvim_set_option_value('omnifunc', 'v:lua.vim.lsp.omnifunc', { buf = bufnr })

                if client.server_capabilities.goto_definition == true then
                    vim.api.nvim_set_option_value('tagfunc', 'v:lua.vim.lsp.tagfunc', { buf = bufnr })
                end

                if client.server_capabilities.document_formatting == true then
                    vim.api.nvim_set_option_value('formatexpr', 'v:lua.vim.lsp.formatexpr()', { buf = bufnr })
                end

                -- Keymaps {{{------------------------------------------------------------------------------------------
                local opts = { buffer = bufnr, noremap = true, silent = true }
                local wk = require'which-key'
                local buf = vim.lsp.buf
                local diag = vim.diagnostic

                -- Diagnostics navigation
                vim.keymap.set('n', '?', vim.diagnostic.open_float, opts)
                vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
                vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)
                wk.add{
                    {
                        buffer = bufnr,
                        { '?', vim.diagnostic.open_float, desc = 'Show diagnostic under cursor' },
                        { '[d', vim.diagnostic.goto_prev, desc = 'Goto previous diagnostic' },
                        { ']d', diag.goto_next, desc = 'Goto next diagnostic' },
                    }
                }

                -- LSP commands
                wk.add{
                    buffer = bufnr,
                    { '<leader>l', group = 'LSP' },
                    { '<leader>ld', diag.setloclist, desc = 'Show all diagnostics' },
                    { '<leader>lr', buf.rename, desc = 'Refactor rename item under cursor' },
                    {
                        { '<leader>ls', group = 'Open source/header file …' },
                        { '<leader>ls<CR>', '<cmd>ClangdSwitchSourceHeader<cr>', desc = 'Switch between source/header file' },
                        { '<leader>lss', '<cmd>split<cr><cmd>ClangdSwitchSourceHeader<cr>', desc = 'Open source/header file in horizontal split' },
                        { '<leader>lsv', '<cmd>vsplit<cr><cmd>ClangdSwitchSourceHeader<cr>', desc = 'Open source/header file in vertical split' },
                    },
                    {
                        { '<leader>lg', group = 'Goto …' },
                        { '<leader>lgd', buf.declaration, desc = 'Goto declaration' },
                        { '<leader>lgD', buf.definition, desc = 'Goto definition' },
                        { '<leader>lgi', buf.implementation, desc = 'Goto implementation' },
                        { '<leader>lgt', buf.type_definition, desc = 'Goto type definition' },
                    },
                    {
                        { '<leader>lh', 'Help …' },
                        { '<leader>lhh', buf.hover, desc = 'Tooltip for item under cursor' },
                        { '<leader>lhs', buf.signature_help, desc = 'Show signature help' },
                        { '<leader>lhr', buf.references, desc = 'Show references' },
                    },
                    {
                        { '<leader>lc', 'Code …' },
                        { '<leader>lca', buf.code_action, desc = 'Perform code action for item under cursor' },
                        { '<leader>lcf', buf.formatting, desc = 'Perform formatting (whole file)' },
                    },
                }
                --}}}---------------------------------------------------------------------------------------------------

                lsp_status.on_attach(client)
                if client.server_capabilities.documentSymbolProvider then
                    navic.attach(client, bufnr)
                end
            end

            local capabilities = require'cmp_nvim_lsp'.default_capabilities()
            capabilities = vim.tbl_extend('keep', capabilities, lsp_status.capabilities)

            lsp['clangd'].setup{
                on_attach = function(client, bufnr)
                    on_attach(client, bufnr)
                    -- Clangd extensions
                    --require("clangd_extensions.inlay_hints").setup_autocmd()
                    --require("clangd_extensions.inlay_hints").set_inlay_hints()
                end,
                capabilities = capabilities,
                handlers = lsp_status.extensions.clangd.setup(),
                init_options = {
                    clangdFileStatus = true,
                    fallbackFlags = {
                        '-std=c++20',
                        '-W',
                        '-Wall',
                        '-pedantic',
                    },
                },
                filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'proto', 'yacc', 'lex', },
                cmd = {
                    'clangd',
                    '--pretty',
                    '--background-index',
                    '--background-index-priority=low',
                    '--clang-tidy',
                    '--completion-style=bundled',
                    '--fallback-style=GNU',
                    '--header-insertion=iwyu',
                    '--enable-config',
                    '--malloc-trim',
                    '--pch-storage=memory',
                },
            }

            lsp['ltex'].setup{
                on_attach = function(client, bufnr)
                    on_attach(client, bufnr)
                    require("ltex_extra").setup{
                        load_langs = { 'en_US', 'de_DE', },
                        path = '.ltex',
                    }
                end,
                capabilities = capabilities,
                filetypes = { 'tex', },
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

            lsp['lua_ls'].setup{
                on_attach = on_attach,
                capabilities = capabilities,
            }

            vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
                border = "rounded",
            })
        end,
    },
}
