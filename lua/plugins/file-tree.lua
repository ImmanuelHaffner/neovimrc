--- Show neo-tree and reveal current file.
--- @param toggle boolean whether to toggle the neo-tree
local function show_neo_tree(toggle)
    local reveal_file = vim.fn.expand'%:p'
    if reveal_file == '' then
        reveal_file = vim.fn.getcwd()
    else
        local f = io.open(reveal_file, 'r')
        if f then
            f.close(f)
        else
            reveal_file = vim.fn.getcwd()
        end
    end
    require'neo-tree.command'.execute{
        action = 'focus',          -- OPTIONAL, this is the default value
        toggle = toggle,
        source = 'filesystem',     -- OPTIONAL, this is the default value
        position = 'left',         -- OPTIONAL, this is the default value
        reveal_file = reveal_file, -- path to file or folder to reveal
        reveal_force_cwd = true,   -- change cwd without asking if needed
    }
end


return {
    {
        'nvim-neo-tree/neo-tree.nvim',
        branch = 'v3.x',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
            'MunifTanjim/nui.nvim',
            '3rd/image.nvim', -- Optional image support in preview window: See `# Preview Mode` for more information
            'folke/which-key.nvim', -- help popup for the <leader>… mappings inside the tree window
        },
        lazy = false,
        config = function()
            local neotree = require'neo-tree'
            neotree.setup{
                -- Git status annotations (added / modified / untracked / staged marks and
                -- git-status colours on filenames) are genuinely useful, so we keep them ON
                -- — explicitly, so it's a deliberate choice rather than an inherited default.
                --
                -- Performance: with this enabled, neo-tree runs `git status` against the whole
                -- worktree root on every filesystem navigate/refresh. On very large monorepos
                -- (e.g. Databricks `universe`, ~17M LOC) that repo-wide status is the dominant
                -- cost. Two things keep it tolerable:
                --   * `filesystem.async_directory_scan = 'always'` (below) keeps the directory
                --     *scan* off the UI thread, so opening/revealing never freezes the editor.
                --   * `git_status_async = true` (neo-tree default) batches status processing
                --     (batch_size 1000, batch_delay 10ms, max_lines 10000) so it never blocks.
                -- Escape hatches if a repo ever becomes painful:
                --   * `git_status_scope_to_path = true` — scope status to the browsed dir, or
                --   * `enable_git_status = false`       — drop tree annotations and read git
                --     state on demand via the Git source (`:Neotree git_status`).
                enable_git_status = true,
                filesystem = {
                    async_directory_scan = 'always',  -- never scan synchronously → no UI freeze on huge dirs
                    cwd_target = {
                        -- 'none' = never push neo-tree's root onto Neovim's cwd. It IS handled at
                        -- runtime (manager.get_params_for_cwd), but is missing from neo-tree's own
                        -- type defs / :checkhealth list — hence the diagnostic suppression below.
                        ---@diagnostic disable-next-line: assign-type-mismatch
                        sidebar = 'none',             -- panel modes (left/right/top/bottom/float): never change CWD implicitly
                        ---@diagnostic disable-next-line: assign-type-mismatch
                        current = 'none',             -- 'current' full-window takeover mode: same
                    },
                },
                window = {
                    mappings = {
                        -- Our <leader> is <Space>, which neo-tree binds to `toggle_node` by default.
                        -- That collides twice over: (1) pressing <Space> and pausing collapses the
                        -- node instead of waiting for the rest of a <leader> combo, and (2) which-key
                        -- refuses to install its <Space> *trigger* in a buffer where <Space> is
                        -- already mapped (which-key/triggers.lua → is_mapped), so the help popup
                        -- never appeared here. 'none' (also 'nop'/'noop') is how neo-tree drops a
                        -- default mapping (ui/renderer.lua → set_buffer_mappings, skip_this_mapping).
                        -- Expand/collapse stays on <cr> (open), C (close_node), z (close_all_nodes).
                        ['<space>'] = 'none',

                        -- `desc` is forwarded onto the buffer-local keymap, so it doubles as the
                        -- which-key label and neo-tree's own help text (`?` → show_help). Without it
                        -- the three cd entries below would all just read `cd_here`.
                        ['<F2>'] = { 'close_window', desc = 'Close neo-tree' },
                        ['<leader>p'] = { 'image_wezterm', desc = 'Preview image (WezTerm)' },
                        -- Explicit CWD relocation to the node under the cursor (see `cd_here` below).
                        ['<leader>cd'] = { 'cd_here', config = { scope = 'cd'  }, desc = ':cd  → node (global)' },
                        ['<leader>ct'] = { 'cd_here', config = { scope = 'tcd' }, desc = ':tcd → node (tab)' },
                        ['<leader>cl'] = { 'cd_here', config = { scope = 'lcd' }, desc = ':lcd → node (prior win)' },
                    },
                },
                commands = {
                    image_wezterm = function(state)
                        local node = state.tree:get_node()
                        if node.type == 'file' then
                            require'image_preview'.PreviewImage(node.path)
                        end
                    end,

                    -- Explicitly relocate the working directory to the node under the cursor.
                    -- Deliberate action, decoupled from navigation (cwd_target = 'none' above).
                    -- Scope comes from the mapping's `config.scope`:
                    --   'cd'  -> :cd  global  (whole session)
                    --   'tcd' -> :tcd tab     (current tab)          [default if unset]
                    --   'lcd' -> :lcd window  (the file window we came from; focus is on the
                    --            neo-tree window, so we target neo-tree's prior window)
                    -- With bind_to_cwd = true (default), :cd/:tcd re-root the tree via DirChanged;
                    -- :lcd changes only the other window's local cwd and leaves the tree as-is.
                    cd_here = function(state)
                        local node = state.tree:get_node()
                        if not node then return end
                        local dir = node.type == 'directory' and node.path or vim.fn.fnamemodify(node.path, ':h')
                        local scope = (state.config or {}).scope or 'tcd'
                        local esc = vim.fn.fnameescape(dir)
                        if scope == 'lcd' then
                            local win = neotree.get_prior_window()
                            if win <= 0 then
                                vim.notify('neo-tree: no prior window to :lcd', vim.log.levels.WARN)
                                return
                            end
                            vim.api.nvim_win_call(win, function() vim.cmd('lcd ' .. esc) end)
                        else
                            vim.cmd(scope .. ' ' .. esc)  -- 'cd' or 'tcd'
                        end
                        vim.notify('neo-tree: ' .. scope .. ' → ' .. dir)
                    end,
                },
            }

            -- Label the buffer-local <leader>c prefix for which-key, so the popup shows a proper
            -- group name instead of a bare key list; the leaf labels come from each mapping's `desc`
            -- above. which-key keys groups by buffer, so this has to run for every neo-tree buffer —
            -- FileType fires before the window is entered, i.e. before which-key builds its keymap
            -- tree for that buffer (which it does on BufEnter).
            vim.api.nvim_create_autocmd('FileType', {
                group = vim.api.nvim_create_augroup('neo-tree-which-key', { clear = true }),
                pattern = 'neo-tree',
                callback = function(args)
                    if vim.b[args.buf].neo_tree_wk then return end  -- register once per buffer
                    local ok, wk = pcall(require, 'which-key')
                    if not ok then return end
                    vim.b[args.buf].neo_tree_wk = true
                    wk.add{ { '<leader>c', group = 'cwd → node', buffer = args.buf } }
                end,
            })
        end,
        keys = {
            {
                '<F2>',
                function()
                    -- local reveal_file = vim.fn.expand'%:p'
                    -- if reveal_file == '' then
                    --     reveal_file = vim.fn.getcwd()
                    -- else
                    --     local f = io.open(reveal_file, 'r')
                    --     if f then
                    --         f.close(f)
                    --     else
                    --         reveal_file = vim.fn.getcwd()
                    --     end
                    -- end
                    -- require'neo-tree.command'.execute{
                    --     action = 'focus',          -- OPTIONAL, this is the default value
                    --     toggle = true,
                    --     source = 'filesystem',     -- OPTIONAL, this is the default value
                    --     position = 'left',         -- OPTIONAL, this is the default value
                    --     reveal_file = reveal_file, -- path to file or folder to reveal
                    --     reveal_force_cwd = true,   -- change cwd without asking if needed
                    -- }
                    show_neo_tree(true)
                end,
                desc = 'Toggle Neo-tree (filesystem)'
            },
            {
                '<S-F2>',
                function()
                    show_neo_tree(false)
                end,
                desc = 'Open Neo-tree (filesystem)'
            },
        }
    },
    {
        'kyazdani42/nvim-tree.lua',
        enabled = false,
        tag = 'nightly',
        dependencies = {
            'folke/which-key.nvim',
            'nvim-tree/nvim-web-devicons',
        },
        config = function()
            require'nvim-tree'.setup{
                view = { width = 40 },
            }
        end,
        keys = {
            { '<F2>', '<cmd>NvimTreeToggle<cr>', desc = 'Toggle NvimTree' },
        }
    }
}
