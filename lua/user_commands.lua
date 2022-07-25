local M = { }

function M.setup()

    ----- Save session & quit {{{---------------------------------------------------------------------------------------
    vim.api.nvim_create_user_command('Q', function()
        require('session_manager').save_current_session()
        vim.cmd[[wqa]]
    end, {
        desc = 'save current session, write all files, quit'
    })
    --}}}---------------------------------------------------------------------------------------------------------------

end

return M
