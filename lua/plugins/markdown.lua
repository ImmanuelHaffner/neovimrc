return {
    {
        'euclio/vim-markdown-composer',
        -- Only load on local instances (servername starts with '/'), not over SSH, and only when the
        -- Rust server has actually been built.  Test the built artefact rather than
        -- `executable('markdown-composer')`: the binary is invoked by absolute path and never lands on
        -- $PATH, so a PATH probe would keep the plugin dormant even after a successful build.
        cond = function()
            local is_local = (vim.v.servername or ''):sub(1, 1) == '/'
            local is_ssh = vim.env.SSH_TTY ~= nil or vim.env.SSH_CONNECTION ~= nil
            local binary = vim.g.markdown_composer_binary
                or (vim.fn.stdpath('data') .. '/lazy/vim-markdown-composer/target/release/markdown-composer')
            return is_local and not is_ssh and vim.fn.executable(binary) == 1
        end,
        -- The plugin's hooks are not crash-safe.  `s:onServerExit` tests `exists(s:job)` — the job
        -- *value*, not the name `'s:job'` — so when the Rust server dies (it panics; see the plugin's
        -- own `error.log`) `s:job` is never unlet.  Every later `BufEnter` then notifies a dead channel
        -- (`E475: Channel doesn't exist`) while `s:startServer()` early-returns forever, so the preview
        -- never recovers and the errors break any tooling that loads a `.md` buffer.
        --
        -- Replace those hooks with `silent!`-wrapped equivalents: live preview still works while a
        -- server is alive, a dead one stays silent, and starting it is explicit (`:ComposerStart`).
        init = function()
            -- Only read by the hook stripped below, but keep the intent explicit.
            vim.g.markdown_composer_autostart = 0
        end,
        config = function()
            local group = vim.api.nvim_create_augroup('ComposerGuard', { clear = true })
            -- Whether the preview server still answers.  Deliberately a bare `pcall` and NOT
            -- `silent!`: the `!` makes the E475 raised inside the plugin's `s:sendBuffer` non-aborting,
            -- so `pcall` would report success *and* the message would still be echoed (verified both
            -- ways).  A bare `pcall` is silent and tells us the truth.  Once the server is gone the
            -- plugin cannot restart it (`s:job` is never unlet, so `s:startServer()` early-returns),
            -- so further attempts are pure waste — stop until the next markdown buffer re-arms us.
            local alive = true
            vim.api.nvim_create_autocmd({ 'BufEnter', 'TextChanged', 'TextChangedI' }, {
                group = group,
                pattern = { '*.md', '*.mkd', '*.markdown' },
                callback = function()
                    if not alive then return end
                    alive = pcall(vim.cmd, 'ComposerUpdate')
                end,
                desc = 'Crash-safe vim-markdown-composer refresh',
            })
            -- The plugin's `after/ftplugin` re-creates its augroup on *every* markdown FileType, so a
            -- single clear does not stick — re-strip it each time.  This is also the natural retry
            -- point: re-arm here, so a dead server costs at most one failed call per markdown buffer
            -- rather than one per keystroke.
            vim.api.nvim_create_autocmd('FileType', {
                group = group,
                pattern = { 'markdown', 'pandoc' },
                callback = function()
                    pcall(vim.api.nvim_clear_autocmds, { group = 'markdown-composer' })
                    alive = true
                end,
                desc = 'Strip vim-markdown-composer hooks (not crash-safe; see comment above)',
            })
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
        lazy = false,
        priority = 49,
        -- ft = 'markdown' -- If you decide to lazy-load anyway
        dependencies = {
            'nvim-tree/nvim-web-devicons',
        },
        opts = {
            markdown = {
                code_blocks = {
                    -- Pin style so `block_on_wrap` is honored under `wrap`; upstream v28.3.0's
                    -- default `style` function returns 'simple' whenever wrap is on, which
                    -- short-circuits the `block_on_wrap` logic in the code_blocks renderer.
                    style = 'block',
                    block_on_wrap = 'adaptive',
                },
                tables = {
                    parts = {
                        top =       { '┌', '─', '┐', '┬' },
                        header =    { '│', '│', '│' },
                        separator = { '├', '─', '┤', '┼' },
                        row =       { '│', '│', '│' },
                        bottom =    { '└', '─', '┘', '┴' },
                        overlap =   { '├', '━', '┤', '┿' },
                        align_left = '╼',
                        align_right = '╾',
                        align_center = { '╴', '╶' },
                    },
                },
            },
            preview = {
                enable_hybrid_mode = true,
                debounce = 300,  -- ms after cursor stops before re-rendering
                modes = { 'n' },  -- only render in normal mode
                hybrid_modes = { 'n' },  -- but in hybrid mode
                edit_range = { 0, 0 },  -- and don't render the cursor line
                filetypes = { 'markdown', 'codecompanion', 'mdx', },
                ignore_buftypes = {},  -- to avoid 'nofile'
                max_buf_lines = 5000,  -- allow rendering in longer CC chats (default 1000)
            },
        },
        config = function(_, opts)
            require('markview').setup(opts)

            -- Keymap to toggle markview's hybrid mode.
            local has_wk, wk = pcall(require, 'which-key')
            if has_wk then
                wk.add{
                    { '<leader>m', group = 'Markview…' },
                    { '<leader>mt', function() require('markview.actions').hybridToggle() end,
                        desc = 'Toggle markview hybrid mode' },
                }
            else
                vim.keymap.set('n', '<leader>mt',
                    function() require('markview.actions').hybridToggle() end,
                    { desc = 'Toggle markview hybrid mode' })
            end

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
