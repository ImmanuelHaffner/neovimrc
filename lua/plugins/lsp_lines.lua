return {
    { 'https://git.sr.ht/~whynothugo/lsp_lines.nvim',
        dependencies = { 'neovim/nvim-lspconfig' },
        config = function()
            require'lsp_lines'.setup()
            vim.diagnostic.config({
                virtual_text = false, -- Disable virtual_text since it's redundant due to lsp_lines.
            })
        end
    },
}
