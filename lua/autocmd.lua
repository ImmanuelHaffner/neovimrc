local M = { }

function M.setup()
    ----- Remove comment leader on o/O {{{------------------------------------------------------------------------------
    vim.api.nvim_create_autocmd('BufEnter', {
        callback = function()
            vim.opt.formatoptions:remove { 'o' }
        end,
        desc = 'Disable New Line Comment',
    })
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- Show tip on launch {{{----------------------------------------------------------------------------------------
    vim.api.nvim_create_autocmd('VimEnter', {
        group = vim.api.nvim_create_augroup('vimtip', {clear=true}),
        callback = function()
            local job = require'plenary.job'
            job:new({
                command = 'curl',
                args = { 'https://vtip.43z.one' },
                on_exit = function(j, exit_code)
                    local res = table.concat(j:result())
                    if exit_code ~= 0 then
                        res = 'Error fetching tip: ' .. res
                    end
                    vim.notify(res, 2, { title = 'Tip!' })
                end,
            }):start()
        end,
    })
    --}}}---------------------------------------------------------------------------------------------------------------
end

return M
