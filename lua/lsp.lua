local M = { }

local function setup_metals()
    -- Configure metals
    local wk = require'which-key'
    local metals = require'metals'
    local metals_config = metals.bare_config()
    metals_config.settings = {
        defaultBspToBuildTool = true,
        javaHome = '/usr/lib/jvm/temurin-25-jdk-amd64',
        showImplicitArguments = true,
        fallbackScalaVersion = '2.13.16',

        -- Databricks custom version
        serverVersion = "9.9.9-DATABRICKS-LAUNCHER-1",

        -- We set our metals wrapper script here, which acts as an executable for the databricks JAR file
        useGlobalExecutable = false,
        metalsBinaryPath = vim.fn.expand('~/.local/bin/dbmetals'),
    }

    metals_config.init_options.statusBarProvider = 'off'
    -- metals is started by nvim-metals rather than `vim.lsp.enable`, so it never goes
    -- through `vim.lsp.config` resolution and has to inherit the global `capabilities`
    -- explicitly. It needs no `on_attach` wiring: `LspAttach` fires for every client
    -- however it was started, so the global setup in `M.setup()` covers metals too.
    local global_config = vim.lsp.config['*']
    if global_config and global_config.capabilities then
        metals_config.capabilities = global_config.capabilities
    end
    metals_config.capabilities.workspace = metals_config.capabilities.workspace or {}
    metals_config.capabilities.workspace.semanticTokens = metals_config.capabilities.workspace.semanticTokens or {}
    metals_config.capabilities.workspace.semanticTokens.refreshSupport = true

    -- Override `find_root_dir` to simply use CWD
    metals_config.find_root_dir = function() return vim.fn.getcwd() end

    local nvim_metals_group = vim.api.nvim_create_augroup('nvim-metals', { clear = true })
    vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'scala', 'sbt', 'java' },
        callback = function(opts)
            -- Register the `scala` DAP adapter.  nvim-metals never does this itself, and
            -- without it neither our `dap.configurations.scala` entries nor the run/debug
            -- code lenses can start a session.  Upstream documents the call for metals'
            -- `on_attach`, which we no longer use; it only assigns an adapter function and
            -- is idempotent, so this hook is an equivalent site.
            metals.setup_dap()
            metals.initialize_or_attach(metals_config)
            wk.add({
                buffer = opts.buf,
                { '<leader>lhm', function() require'telescope'.extensions.metals.commands() end, desc = 'Metals Commands' }
            }, {
                silent = true
            })
        end,
        group = nvim_metals_group,
    })
end

function M.setup()
    local lsp_status = require'lsp-status'
    local navic = require'nvim-navic'
    local wk = require'which-key'

    lsp_status.register_progress()

    -- Only log errors by default to avoid log file growing too quickly.
    vim.lsp.log.set_level'error'

    -- Global LSP configuration (applied to all servers)
    vim.lsp.config('*', {
        -- Set default capabilities for all servers
        capabilities = vim.tbl_extend('keep',
            require'cmp_nvim_lsp'.default_capabilities(),
            lsp_status.capabilities
        ),
        -- Common root markers
        root_markers = { '.git' },
    })

    -- Global on-attach behaviour, installed as an `LspAttach` autocmd rather than as an
    -- `on_attach` field in the `'*'` config above.
    --
    -- Neovim resolves a server config as
    --     vim.tbl_deep_extend('force', config['*'], <rtp lsp/NAME.lua>, config[NAME])
    -- so `'*'` has the *lowest* precedence -- below the `lsp/NAME.lua` files shipped by
    -- nvim-lspconfig. Functions cannot be merged, so any server that ships its own
    -- `on_attach` silently replaces ours; nvim-lspconfig does precisely that for `texlab`
    -- and `clangd`, which used to cost `texlab` its statusline progress and its navic
    -- breadcrumbs. `LspAttach` fires for every client on every buffer, outside that
    -- precedence chain, so no upstream change can shadow it.
    --
    -- Note this runs once per attaching *client*, not once per buffer: a `.tex` buffer
    -- attaches both `ltex` and `texlab`, so the body below must stay idempotent.
    local lsp_attach_group = vim.api.nvim_create_augroup('user-lsp-attach', { clear = true })
    vim.api.nvim_create_autocmd('LspAttach', {
        group = lsp_attach_group,
        desc = 'Global LSP keymaps and UI setup for every attaching client',
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            if not client then return end
            local bufnr = args.buf

            -- Keymaps and UI setup
            local buf = vim.lsp.buf
            local diag = vim.diagnostic

            -- Diagnostics navigation
            wk.add{
                buffer = bufnr,
                { '?', vim.diagnostic.open_float, desc = 'Show diagnostic under cursor' },
                { '[d', function() vim.diagnostic.jump{ count=-1, float=true } end, desc = 'Goto previous diagnostic' },
                { ']d', function() vim.diagnostic.jump{ count=1, float=true } end, desc = 'Goto next diagnostic' },
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
                    { '<leader>lcl', vim.lsp.codelens.run, desc = 'Open code lens' },
                    { '<leader>lcf', function() buf.format({ async = false }) end, desc = 'Perform formatting (whole file)' },
                },
                {
                    { '<leader>lf', group = 'Find …' },
                    { '<leader>lfw', buf.workspace_symbol, desc = 'Workspace symbols' },
                    { '<leader>lfd', buf.document_symbol, desc = 'Document symbols' },
                    { '<leader>lfr', require('telescope.builtin').lsp_references, desc = 'References' },
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
        -- Deliberately no `on_attach` here: the global setup lives in the `LspAttach`
        -- autocmd above, and leaving this key unset lets nvim-lspconfig's own clangd
        -- `on_attach` register its buffer-local `LspClangdSwitchSourceHeader` and
        -- `LspClangdShowSymbolInfo`. The `<leader>ls*` keymaps call the global commands
        -- from clangd_extensions.nvim instead, so both remain available.
        -- Clangd extensions (uncomment if needed):
        --require("clangd_extensions.inlay_hints").setup_autocmd()
        --require("clangd_extensions.inlay_hints").set_inlay_hints()
    }

    -- Configure ltex
    vim.lsp.config.ltex = {
        filetypes = { 'tex' },
        root_markers = { '.latexmkrc', 'latexmkrc', '.git' },
        -- Global setup now comes from the `LspAttach` autocmd above, so this does only
        -- the ltex-specific part.
        on_attach = function()
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

    -- Enable all configured LSP servers
    vim.lsp.enable({ 'clangd', 'ltex', 'texlab', 'pylsp', 'bashls', 'lua_ls' })

    setup_metals()
end

return M
