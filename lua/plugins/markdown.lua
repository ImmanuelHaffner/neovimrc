return {
    {
        'euclio/vim-markdown-composer',
        -- Only load on local instances (servername starts with '/') and not over SSH
        cond = function()
            local is_local = (vim.v.servername or ''):sub(1, 1) == '/'
            local is_ssh = vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil
            return is_local and not is_ssh
        end,
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
        'ImmanuelHaffner/markview.nvim',
        branch = 'dev',
        dev = true,
        lazy = false,      -- Recommended
        priority = 49,
        -- ft = 'markdown' -- If you decide to lazy-load anyway
        dependencies = {
            'nvim-tree/nvim-web-devicons',
        },
        opts = {
            markdown = {
                tables = {
                    parts = {
                        top =       { "┌", "─", "┐", "┬" },
                        header =    { "│", "│", "│" },
                        separator = { "├", "─", "┤", "┼" },
                        row =       { "│", "│", "│" },
                        bottom =    { "└", "─", "┘", "┴" },
                        overlap =   { "├", "━", "┤", "┿" },
                        align_left = "╼",
                        align_right = "╾",
                        align_center = { "╴", "╶" },
                    },
                },
            },
            preview = {
                enable_hybrid_mode = true,
                modes = { 'n' },  -- only render in normal mode
                hybrid_modes = { 'n' },  -- but in hybrid mode
                edit_range = { 0, 0 },  -- and don't render the cursor line
                draw_range = { 200, 200 },  -- render ±200 lines around cursor (default ~vim.o.lines)
                filetypes = { 'markdown', 'codecompanion', 'mdx', },
                ignore_buftypes = {},  -- to avoid 'nofile'
                max_buf_lines = 5000,  -- allow rendering in longer CC chats (default 1000)
            },
        },
    },
    {
        -- Good enough syntax highlight for MDX in Neovim using Treesitter.
        'davidmh/mdx.nvim',
        dependencies = {'nvim-treesitter/nvim-treesitter'}
    },
}
