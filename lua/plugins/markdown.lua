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
        lazy = false,
        ---@module 'render-markdown'
        ---@type render.md.UserConfig
        opts = {
            file_types = { 'markdown', 'codecompanion', 'mdx' },
            -- Normal mode plus the command line, so opening `:` does not tear the rendering down.
            -- Insert and visual stay unrendered, which is where the raw markup is wanted anyway.
            render_modes = { 'n', 'c' },
            -- Show raw markup on the cursor line only — nothing above or below it.
            anti_conceal = { above = 0, below = 0 },
            code = {
                -- Background across the whole window rather than sized to the block.  A block-width
                -- background is not wrap-aware, so a wrapped line tears it open, and it suppresses
                -- `colorcolumn` and `cursorline` on every line it covers.
                width = 'full',
            },
            checkbox = {
                -- markview parity: the state's color covers the whole item rather than just its
                -- icon, and `[-]` reads as cancelled — greyed out and struck through.
                unchecked = {
                    icon = '󰄰 ',
                    highlight = 'RenderMarkdownUnchecked',
                    scope_highlight = 'RenderMarkdownUnchecked',
                },
                checked = {
                    icon = '󰗠 ',
                    highlight = 'RenderMarkdownChecked',
                    scope_highlight = 'RenderMarkdownChecked',
                },
                custom = {
                    todo = {
                        raw = '[-]',
                        rendered = '󰍶 ',
                        highlight = 'RenderMarkdownTodo',
                        scope_highlight = 'RenderMarkdownStriked',
                    },
                },
            },
            -- Leave the sign column to gitsigns and diagnostics; headings and code blocks are
            -- already marked up in the text itself.
            sign = { enabled = false },
            overrides = {
                buftype = {
                    -- Telescope preview buffers.  `nofile` renders in every mode by default; drop
                    -- anti-conceal as well, since a preview is read rather than edited.
                    nofile = { anti_conceal = { enabled = false } },
                },
            },
            on = {
                -- Republish as the renderer-agnostic attach event; see `lua/mdrender.lua`.
                attach = function(ctx) require'mdrender'.emit_attach(ctx.buf) end,
            },
        },
        config = function(_, opts)
            require'render-markdown'.setup(opts)
            require'mdrender'.setup()
        end,
    },
    {
        -- Superseded by render-markdown.nvim above, kept declared so that switching back costs one
        -- `enabled` flip on each of these two specs.  Everything that consumes a renderer goes
        -- through `lua/mdrender.lua`, which dispatches on whichever one is installed.
        'ImmanuelHaffner/markview.nvim',
        enabled = false,
        branch = 'dev',
        lazy = false,
        priority = 49,
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
            require'markview'.setup(opts)
            require'mdrender'.setup()
        end,
    },
    {
        -- Good enough syntax highlight for MDX in Neovim using Treesitter.
        'davidmh/mdx.nvim',
        dependencies = {'nvim-treesitter/nvim-treesitter'}
    },
}
