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
        config = function(_, opts)
            require('markview').setup(opts)

            -- Render markview in Telescope preview windows with hybrid mode disabled.
            --
            -- Markview never attaches to Telescope preview buffers on its own because:
            --   1. Telescope uses `eventignore="all"` when placing buffers (no BufEnter/BufWinEnter)
            --   2. Setting filetype/syntax via API fires FileType/Syntax but not OptionSet
            -- Markview only listens on BufAdd/BufEnter/BufWinEnter/OptionSet — none of which fire.
            --
            -- We fix this with two hooks:
            --   a) Monkey-patch telescope's putils.highlighter (called after file content is loaded)
            --   b) FileType autocmd for previewers that set filetype explicitly (e.g. CodeCompanion)

            local md_filetypes = { markdown = true, codecompanion = true }

            --- Attach markview to a Telescope preview buffer with hybrid mode disabled.
            ---@param bufnr integer
            local function markview_attach_preview(bufnr)
                if not vim.api.nvim_buf_is_valid(bufnr) then return end
                local has_actions, mv_actions = pcall(require, 'markview.actions')
                if not has_actions then return end
                local mv_state = require('markview.state')
                if mv_state.can_attach(bufnr) then
                    mv_actions.attach(bufnr, { enable = true, hybrid_mode = false })
                else
                    -- Already attached (reused buffer) — ensure hybrid mode stays off and re-render
                    mv_state.set_buffer_state(bufnr, { enable = true, hybrid_mode = false })
                    mv_actions.render(bufnr)
                end
            end

            -- (a) Patch telescope's previewer highlighter to attach markview after file content loads.
            --     This catches find_files, live_grep, and any picker using buffer_previewer_maker.
            local ok_putils, putils = pcall(require, 'telescope.previewers.utils')
            if ok_putils then
                local original_highlighter = putils.highlighter
                putils.highlighter = function(bufnr, ft, opts)
                    original_highlighter(bufnr, ft, opts)
                    if md_filetypes[ft] then
                        markview_attach_preview(bufnr)
                    end
                end
            end

            -- (b) FileType autocmd for previewers that set filetype explicitly (e.g. CodeCompanion).
            --     These don't go through putils.highlighter, so we detect them via FileType + winhl.
            vim.api.nvim_create_autocmd('FileType', {
                pattern = vim.tbl_keys(md_filetypes),
                group = vim.api.nvim_create_augroup('markview_telescope_preview', { clear = true }),
                callback = function(args)
                    local bufnr = args.buf
                    if vim.bo[bufnr].buftype ~= 'nofile' then return end
                    for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
                        if (vim.wo[win].winhl or ''):find('TelescopePreviewNormal') then
                            vim.schedule(function() markview_attach_preview(bufnr) end)
                            return
                        end
                    end
                end,
            })
        end,
    },
    {
        -- Good enough syntax highlight for MDX in Neovim using Treesitter.
        'davidmh/mdx.nvim',
        dependencies = {'nvim-treesitter/nvim-treesitter'}
    },
}
