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
