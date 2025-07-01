local Utils = require'utils'

return {
    { 'euclio/vim-markdown-composer',
        enabled = Utils.is_local_nvim,
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
        opts = {
            file_types = { 'codecompanion' },
        },
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
                filetypes = { 'markdown', 'codecompanion', 'mdx', },
                ignore_buftypes = {},  -- to avoid 'nofile'
                -- filetypes = { 'markdown' },
            },
        },
    },
    {
        -- Good enough syntax highlight for MDX in Neovim using Treesitter.
        'davidmh/mdx.nvim',
        config = true,
        dependencies = {'nvim-treesitter/nvim-treesitter'}
    },
}
