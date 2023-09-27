return {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    setup = function()
        require'nvim-treesitter.configs'.setup{
            highlight = { enable = false },  -- use NeoVim's LSP-based semantic highlighting
            incremental_selection = { enable = false },
            indent = { enable = false },  -- again, rely on LSP-based formatting
        },
    end
}
