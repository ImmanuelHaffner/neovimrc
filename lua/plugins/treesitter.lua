return {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
        require'nvim-treesitter'.setup{}
        require'nvim-treesitter.configs'.setup{
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
        }
    end
}
