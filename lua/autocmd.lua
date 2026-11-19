local M = { }

function M.setup()
    local general_settings_group = vim.api.nvim_create_augroup('General settings', { clear = true })

    ----- FileType based autocommands {{{-------------------------------------------------------------------------------
    vim.api.nvim_create_autocmd('FileType', {
        callback = function(args)
            if vim.o.filetype == 'qf' or vim.bo[args.buf].buftype == 'quickfix' then
                -- Configure quickfix window
                vim.wo.colorcolumn = '0'  -- no color column
                vim.cmd[[wincmd J]]
                vim.cmd[[resize 10]]
            elseif vim.o.filetype == 'help' then
                -- Configure Neovim help
                vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = args.buf })
            end
        end,
        group = general_settings_group,
        desc = 'Place Quickfix window at the very bottom',
    })
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- Soft-wrapped prose {{{----------------------------------------------------------------------------------------
    -- Prose is soft-wrapped, never hard-wrapped, against the code defaults in `config.lua` (`nowrap`, `textwidth=120`,
    -- `colorcolumn=121`).  `wrap` and `colorcolumn` are window-local, so setting them once on `FileType` is not enough:
    -- a buffer loaded while hidden (`bufload()`, as the MCP file tools do) runs `FileType` in the autocmd window, and
    -- when it is shown later it inherits the displaying window's global values.  Hence `BufWinEnter` re-applies them.
    -- They are set local-only, so the next buffer shown in that window gets the code defaults back.
    local prose_filetypes = {
        'markdown', 'mdx', 'pandoc', 'text', 'tex', 'plaintex', 'rst', 'asciidoc', 'org', 'norg', 'typst',
    }
    local function wrap_prose(buf)
        if not vim.tbl_contains(prose_filetypes, vim.bo[buf].filetype) then return end
        vim.bo[buf].textwidth = 0
        for _, win in ipairs(vim.fn.win_findbuf(buf)) do
            local wo = vim.wo[win][0]
            wo.wrap = true
            wo.colorcolumn = ''
        end
    end
    vim.api.nvim_create_autocmd({ 'FileType', 'BufWinEnter' }, {
        callback = function(args) wrap_prose(args.buf) end,
        group = general_settings_group,
        desc = 'Soft-wrap prose buffers',
    })
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- Remove comment leader on o/O {{{------------------------------------------------------------------------------
    vim.api.nvim_create_autocmd('BufEnter', {
        callback = function()
            vim.opt.formatoptions:remove{ 'o' }
        end,
        group = general_settings_group,
        desc = 'Disable New Line Comment',
    })
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- Show tip on launch {{{----------------------------------------------------------------------------------------
    -- vim.api.nvim_create_autocmd('VimEnter', {
    --     group = vim.api.nvim_create_augroup('vimtip', {clear=true}),
    --     callback = function()
    --         local job = require'plenary.job'
    --         job:new({
    --             command = 'curl',
    --             args = { 'https://vtip.43z.one' },
    --             on_exit = function(j, exit_code)
    --                 local res = table.concat(j:result())
    --                 if exit_code ~= 0 then
    --                     res = 'Error fetching tip: ' .. res
    --                 end
    --                 vim.notify(res, 2, { title = 'Tip!' })
    --             end,
    --         }):start()
    --     end,
    -- })
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- Reload changed files {{{--------------------------------------------------------------------------------------
    -- Triger `autoread` when files changes on disk
    -- https://unix.stackexchange.com/questions/149209/refresh-changed-content-of-file-opened-in-vim/383044#383044
    -- https://vi.stackexchange.com/questions/13692/prevent-focusgained-autocmd-running-in-command-line-editing-mode
    vim.api.nvim_create_autocmd({'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI'}, {
        command = "if mode() !~ '\v(c|r.?|!|t)' && getcmdwintype() == '' | checktime | endif",
        group = general_settings_group,
    })

    -- Notification after file change
    -- https://vi.stackexchange.com/questions/13091/autocmd-event-for-autoread
    vim.api.nvim_create_autocmd({'FileChangedShellPost'}, {
        command = "echohl WarningMsg | echo 'File changed on disk. Buffer reloaded.' | echohl None",
    })
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- Fix Telescope entering buffer in insert mode {{{--------------------------------------------------------------
    -- See https://github.com/nvim-telescope/telescope.nvim/issues/2027#issuecomment-1561836585
    vim.api.nvim_create_autocmd('WinLeave', {
        callback = function()
            if vim.bo.ft == 'TelescopePrompt' and vim.fn.mode() == 'i' then
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'i', false)
            end
        end,
        group = general_settings_group,
    })
    --}}}---------------------------------------------------------------------------------------------------------------
end

return M
