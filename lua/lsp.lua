local M = { }


function M.setup()
    local lsp_status = require'lsp-status'
    local navic = require'nvim-navic'

    lsp_status.register_progress()

    -- Only log errors by default to avoid log file growing too quickly.
    vim.lsp.set_log_level'error'

    -- Global LSP configuration (applied to all servers)
    vim.lsp.config('*', {
        -- Set default capabilities for all servers
        capabilities = vim.tbl_extend('keep',
            require'cmp_nvim_lsp'.default_capabilities(),
            lsp_status.capabilities
        ),
        -- Common root markers
        root_markers = { '.git' },
        -- Global on_attach that will be called for all servers
        on_attach = function(client, bufnr)
            -- Keymaps and UI setup
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
                    { '<leader>lcf', function() buf.format({ async = false }) end, desc = 'Perform formatting (whole file)' },
                },
            }

            lsp_status.on_attach(client)
            if client.server_capabilities.documentSymbolProvider then
                navic.attach(client, bufnr)
            end
        end,
    })

    -- Configure clangd
    vim.lsp.config.clangd = {
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
        filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'proto', 'yacc', 'lex' },
        root_markers = { 'compile_commands.json', 'compile_flags.txt', '.clangd', '.git' },
        init_options = {
            clangdFileStatus = true,
            fallbackFlags = {
                '-std=c++20',
                '-W',
                '-Wall',
                '-pedantic',
            },
        },
        handlers = lsp_status.extensions.clangd.setup(),
        on_attach = function(client, bufnr)
            -- Call the global on_attach first
            local global_config = vim.lsp.config['*']
            if global_config and global_config.on_attach then
                global_config.on_attach(client, bufnr)
            end

            -- Clangd-specific setup
            -- Clangd extensions (uncomment if needed)
            --require("clangd_extensions.inlay_hints").setup_autocmd()
            --require("clangd_extensions.inlay_hints").set_inlay_hints()
        end,
    }

    -- Configure ltex
    vim.lsp.config.ltex = {
        filetypes = { 'tex' },
        root_markers = { '.latexmkrc', 'latexmkrc', '.git' },
        on_attach = function(client, bufnr)
            -- Call the global on_attach first
            local global_config = vim.lsp.config['*']
            if global_config and global_config.on_attach then
                global_config.on_attach(client, bufnr)
            end

            -- ltex-specific setup
            require("ltex_extra").setup{
                load_langs = { 'en_US', 'de_DE' },
                path = '.ltex',
            }
        end,
    }

    -- Configure texlab
    vim.lsp.config.texlab = {
        filetypes = { 'tex', 'plaintex', 'bib' },
        root_markers = { '.latexmkrc', 'latexmkrc', '.git' },
    }

    -- Configure pylsp
    vim.lsp.config.pylsp = {
        filetypes = { 'python' },
        root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile', '.git' },
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

    -- Configure bashls
    vim.lsp.config.bashls = {
        filetypes = { 'sh', 'bash' },
        root_markers = { '.git' },
    }

    -- Configure lua_ls
    vim.lsp.config.lua_ls = {
        filetypes = { 'lua' },
        root_markers = { '.luarc.json', '.luarc.jsonc', '.git' },
    }

    -- Set up hover handler with rounded borders
    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
        border = "rounded",
    })

    -- Enable all configured LSP servers
    vim.lsp.enable({ 'clangd', 'ltex', 'texlab', 'pylsp', 'bashls', 'lua_ls' })
end

return M
