return {
    { 'OXY2DEV/helpview.nvim',
        -- Lazy-load: only renders help buffers; avoids BufEnter overhead.
        ft = 'help',
        dependencies = {
            'nvim-tree/nvim-web-devicons',
        },
        opts = {
            preview = {
                icon_provider = 'devicons',
            }
        },
    },

}
