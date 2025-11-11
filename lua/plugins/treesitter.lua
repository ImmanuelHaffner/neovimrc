local function has_tree_sitter_cli()
    -- Check if tree-sitter CLI is available and working
    local handle = io.popen('tree-sitter --version 2>/dev/null')
    if not handle then
        return false
    end

    local result = handle:read('*a')
    local success = handle:close()

    -- Check if command executed successfully and returned version info
    local is_tree_sitter_cli_available = success and result and result:match('tree%-sitter') ~= nil
    vim.notify('tree-sitter CLI available? ' .. tostring(is_tree_sitter_cli_available))
    return is_tree_sitter_cli_available
end

return {
    { 'nvim-treesitter/nvim-treesitter',
        dependencies = {
            'OXY2DEV/markview.nvim',
        },
        lazy = false,
        build = ':TSUpdate',
        config = function()
            local ensure_installed = {
                'awk',
                'bash',
                'bibtex',
                'c',
                'cmake',
                'cpp',
                'diff',
                'dockerfile',
                'html',
                'htmldjango',
                'lua',
                'markdown',
                'markdown_inline',
                'nginx',
                'ninja',
                'python',
                'query',
                'regex',
                'requirements',
                'rust',
                'sql',
                'vim',
                'vimdoc',
                'xcompose',
                'xresources',
                'yaml',
                'zathurarc',
            }

            if has_tree_sitter_cli() then
                ensure_installed = {
                    table.unpack(ensure_installed),
                    -- List of grammars that require the tree-sitter CLI
                    'latex'
                }
            end

            require'nvim-treesitter'.setup()
            ---@diagnostic disable-next-line: missing-fields
            require'nvim-treesitter.configs'.setup{
                sync_install = false,
                auto_install = true,
                ignore_install = {},
                highlight = {
                    enable = true,
                    disable = function(lang, buf)
                        local clients = vim.lsp.get_clients({ bufnr = buf })
                        for _, client in ipairs(clients) do
                            if client.server_capabilities.semanticTokensProvider then
                                return true -- Disable Tree-sitter highlighting if LSP provides semantic tokens
                            end
                        end
                    end,
                },
                incremental_selection = { enable = false },
                indent = { enable = false },  -- again, rely on LSP-based formatting
                ensure_installed = ensure_installed,
            }
        end
    }
}
