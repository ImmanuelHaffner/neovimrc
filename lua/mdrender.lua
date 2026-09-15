--- Renderer-agnostic bridge to the live Markdown renderer.
---
--- Two plugins can fill that role — `render-markdown.nvim` and `markview.nvim` — and the specs in
--- `lua/plugins/markdown.lua` declare both, with at most one of them enabled.  Every integration
--- point (Telescope previews, indent guides, CodeCompanion streaming, the toggle keymap) therefore
--- has to work with either, so all renderer-specific calls are funnelled through this module and
--- switching renderer is an `enabled` flip on those two specs with no further edit.
---
--- A disabled lazy.nvim plugin is absent from the runtimepath, which makes `pcall(require, …)` an
--- exact presence probe; neither module runs its `setup()` as a side effect of being required, so
--- probing costs nothing and commits to nothing.

local M = {}

--- `User` event announcing that the renderer attached to a buffer, passed as `data.buffer`.
--- `markview` publishes `MarkviewAttach` itself; for `render-markdown` we publish this from its
--- `on.attach` hook.  Consumers subscribe through `M.on_attach` and stay renderer-agnostic.
M.attach_event = 'MarkdownRenderAttach'

---@type 'render-markdown'|'markview'|nil
local backend = nil

--- Which renderer is installed, or `nil` if neither is.  Memoized once one resolves; a negative
--- result is deliberately not cached, so a probe from before the plugin loaded cannot stick.
---@return 'render-markdown'|'markview'|nil
function M.backend()
    if not backend then
        if pcall(require, 'render-markdown') then
            backend = 'render-markdown'
        elseif pcall(require, 'markview') then
            backend = 'markview'
        end
    end
    return backend
end

--- Announce that the renderer attached to `bufnr`; see `M.attach_event`.
---@param bufnr integer
function M.emit_attach(bufnr)
    vim.api.nvim_exec_autocmds('User', { pattern = M.attach_event, data = { buffer = bufnr } })
end

--- Run `callback(bufnr)` whenever the renderer attaches to a buffer.
---@param group integer|string  augroup to own the autocmd
---@param callback fun(bufnr: integer)
function M.on_attach(group, callback)
    vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = { M.attach_event, 'MarkviewAttach' },
        callback = function(args)
            local bufnr = args.data and args.data.buffer
            if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
                callback(bufnr)
            end
        end,
        desc = 'Markdown renderer attached to a buffer',
    })
end

--- Run `callback(bufnr)` when the renderer detaches from a buffer.
---
--- Only `markview` ever detaches; `render-markdown` holds a buffer until it is wiped, so under it
--- this never fires.  Whatever `M.on_attach` does must therefore be safe to leave in place for the
--- lifetime of the buffer rather than relying on this to undo it.
---@param group integer|string  augroup to own the autocmd
---@param callback fun(bufnr: integer)
function M.on_detach(group, callback)
    vim.api.nvim_create_autocmd('User', {
        group = group,
        pattern = 'MarkviewDetach',
        callback = function(args)
            local bufnr = args.data and args.data.buffer
            if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
                callback(bufnr)
            end
        end,
        desc = 'Markdown renderer detached from a buffer',
    })
end

--- Render `bufnr` as a preview: rendered in every mode, and with no raw-markup cursor line, since a
--- preview is read rather than edited.
---
--- Telescope preview buffers are `nofile`, which is how the `render-markdown` side gets both of
--- those properties declaratively (see `overrides.buftype.nofile` in its spec), leaving only the
--- render itself to trigger from here because Telescope suppresses the events it listens on.
---@param bufnr integer
function M.preview(bufnr)
    local which = M.backend()
    if which == 'render-markdown' then
        -- Deferred: Telescope moves the buffer into its preview window asynchronously, and a render
        -- is skipped outright while the buffer is not displayed anywhere.
        vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(bufnr) then return end
            require'render-markdown'.render{ buf = bufnr }
            -- A one-off render deliberately bypasses the plugin's attach path, so nothing else
            -- announces this buffer.
            M.emit_attach(bufnr)
        end)
    elseif which == 'markview' then
        -- Synchronous, unlike above: markview's own `OptionSet` handler attaches with the global
        -- `hybrid_mode = true` default as soon as the filetype is set, so the override has to land
        -- before it gets a chance to render.
        if not vim.api.nvim_buf_is_valid(bufnr) then return end
        local actions = require'markview.actions'
        local state = require'markview.state'
        if state.can_attach(bufnr) then
            actions.attach(bufnr, { enable = true, hybrid_mode = false })
        else
            -- Reused buffer, already attached: keep hybrid mode off and re-render.
            state.set_buffer_state(bufnr, { enable = true, hybrid_mode = false })
            actions.render(bufnr)
        end
    end
end

--- Suspend rendering of `bufnr`, e.g. while an LLM streams into it.
---@param bufnr integer
function M.disable(bufnr)
    local which = M.backend()
    if which == 'render-markdown' then
        -- The public `set_buf` only ever addresses the current buffer; the manager behind it takes
        -- the explicit one we need.
        require'render-markdown.core.manager'.set_buf(bufnr, false)
    elseif which == 'markview' then
        require'markview.actions'.disable(bufnr)
    end
end

--- Resume rendering of `bufnr`.
---@param bufnr integer
function M.enable(bufnr)
    local which = M.backend()
    if which == 'render-markdown' then
        require'render-markdown.core.manager'.set_buf(bufnr, true)
    elseif which == 'markview' then
        require'markview.actions'.enable(bufnr)
    end
end

--- Toggle whether the cursor line shows raw markup instead of rendered output.  The scope differs
--- by renderer: `render-markdown` toggles the given buffer, `markview`'s hybrid mode is global.
---@param bufnr? integer  defaults to the current buffer
function M.toggle_raw_cursor_line(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    local which = M.backend()
    if which == 'render-markdown' then
        local anti_conceal = require'render-markdown.state'.get(bufnr).anti_conceal
        anti_conceal.enabled = not anti_conceal.enabled
        require'render-markdown'.render{ buf = bufnr }
    elseif which == 'markview' then
        require'markview.actions'.hybridToggle()
    end
end

---@type boolean
local configured = false

--- Install the renderer-independent integration: the toggle keymap and rendering inside Telescope
--- previews.  Called from whichever renderer spec is enabled, so it runs exactly once.
function M.setup()
    if configured then return end
    configured = true

    local has_wk, wk = pcall(require, 'which-key')
    if has_wk then
        wk.add{
            { '<leader>m', group = 'Markdown…' },
            { '<leader>mt', function() M.toggle_raw_cursor_line() end,
                desc = 'Toggle raw markup on the cursor line' },
        }
    else
        vim.keymap.set('n', '<leader>mt', function() M.toggle_raw_cursor_line() end,
            { desc = 'Toggle raw markup on the cursor line' })
    end

    -- Render Markdown in Telescope preview windows.
    --
    -- Neither renderer attaches to a Telescope preview buffer on its own because:
    --   1. Telescope uses `eventignore="all"` when placing buffers (no BufEnter/BufWinEnter)
    --   2. Setting filetype/syntax via the API fires FileType/Syntax but not OptionSet
    -- and those are the events they listen on.  Two hooks cover the previewers in use:
    --   a) a patch of telescope's `putils.highlighter`, which runs once file content is loaded
    --   b) a FileType autocmd for previewers that set the filetype explicitly (e.g. CodeCompanion)

    local md_filetypes = { markdown = true, codecompanion = true }

    -- (a) catches find_files, live_grep, and any picker using `buffer_previewer_maker`.
    local ok_putils, putils = pcall(require, 'telescope.previewers.utils')
    if ok_putils then
        local original_highlighter = putils.highlighter
        putils.highlighter = function(bufnr, ft, opts)
            original_highlighter(bufnr, ft, opts)
            if md_filetypes[ft] then
                M.preview(bufnr)
            end
        end
    end

    -- (b) these don't go through `putils.highlighter`, so detect them via FileType + winhl.
    vim.api.nvim_create_autocmd('FileType', {
        pattern = vim.tbl_keys(md_filetypes),
        group = vim.api.nvim_create_augroup('mdrender_telescope_preview', { clear = true }),
        callback = function(args)
            local bufnr = args.buf
            if vim.bo[bufnr].buftype ~= 'nofile' then return end
            for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
                if (vim.wo[win].winhl or ''):find('TelescopePreviewNormal') then
                    vim.schedule(function() M.preview(bufnr) end)
                    return
                end
            end
        end,
        desc = 'Render Markdown in Telescope preview buffers',
    })
end

return M
