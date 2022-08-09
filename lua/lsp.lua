local M = { }

function M.setup()
    local wk = require('which-key')
    local diag = vim.diagnostic
    local buf = vim.lsp.buf

    ----- Key bindings {{{----------------------------------------------------------------------------------------------
    wk.register({
        name = 'Sessions',
        l = { function() require('session_manager').load_session() end, "Load a session" }
    }, { prefix = '<Leader>' })

    -- Mappings. See `:help vim.diagnostic.*` for documentation on any of the below functions
    local opts = { noremap = true, silent = true }

    wk.register({
        name = 'LSP',
        ['?'] = { function() diag.open_float() end, 'Show diagnostic under cursor' },
        ['[d'] = { function() diag.goto_prev() end, 'Goto previous diagnostic' },
        [']d'] = { function() diag.goto_next() end, 'Goto next diagnostic' },
        ['<leader>d'] = { function() diag.setloclist() end, 'Show all diagnostics' }
    })

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

        -- Mappings. See `:help vim.lsp.*` for documentation on any of the below functions
        local bufopts = { noremap=true, silent=true, buffer=bufnr }

        wk.register({
            name = 'LSP',
            g = {
                d = { function() buf.declaration() end, 'Goto declaration' },
                D = { function() buf.definition() end, 'Goto definition' },
                i = { function() buf.implementation() end, 'Goto implementation' },
                t = { function() buf.type_definition() end, 'Goto type definition' },
            },
            k = { function() buf.hover() end, 'Tooltip for item under cursor' },
            ['rn'] = { function() buf.rename() end, 'Refactor rename item under cursor' },
            ['ca'] = { function() buf.code_action() end, 'Perform code action for item under cursor' },
            ['cf'] = { function() buf.formatting() end, 'Perform formatting (whole file)' },
            ['<tab>'] = { '<cmd>ClangdSwitchSourceHeader<cr>', 'Switch between source/header file' },
            ['s<tab>'] = { '<cmd>split<cr><cmd>ClangdSwitchSourceHeader<cr>', 'Open source/header file in horizontal split' },
            ['v<tab>'] = { '<cmd>vsplit<cr><cmd>ClangdSwitchSourceHeader<cr>', 'Open source/header file in vertical split' },
        }, { prefix = '<leader>', buffer = bufnr })

        -- vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
    end
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- Server configurations {{{-------------------------------------------------------------------------------------
    require('lspconfig')['clangd'].setup{
        on_attach = on_attach,
        capabilities = require'cmp_nvim_lsp'.update_capabilities(vim.lsp.protocol.make_client_capabilities()),
    }

    require('lspconfig')['ltex'].setup{
        on_attach = on_attach,
        capabilities = require'cmp_nvim_lsp'.update_capabilities(vim.lsp.protocol.make_client_capabilities()),
    }

    require('lspconfig')['texlab'].setup{
        on_attach = on_attach,
        capabilities = require'cmp_nvim_lsp'.update_capabilities(vim.lsp.protocol.make_client_capabilities()),
    }
    --}}}---------------------------------------------------------------------------------------------------------------

end

return M
