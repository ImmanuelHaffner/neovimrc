return {
    { 'euclio/vim-markdown-composer',
        build = { 'cargo build --release', ':UpdateRemotePlugins' }
    },
    {
        'MeanderingProgrammer/render-markdown.nvim',
        dependencies = {
            'nvim-treesitter/nvim-treesitter',
            'nvim-tree/nvim-web-devicons',
        },
        enabled = false,
        ---@module 'render-markdown'
        ---@type render.md.UserConfig
        opts = {},
    },
    {
        'OXY2DEV/markview.nvim',
        lazy = false,      -- Recommended
        -- ft = 'markdown' -- If you decide to lazy-load anyway
        dependencies = {
            'nvim-treesitter/nvim-treesitter',
            'nvim-tree/nvim-web-devicons'
        },
        opts = {
            preview = {
                enable_hybrid_mode = true,
                modes = { 'n' },  -- only render in normal mode
                hybrid_modes = { 'n' },  -- but in hybrid mode
                edit_range = { 0, 0 },  -- and don't render the cursor line
            },
        },
    },
}
