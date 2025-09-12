local M = { }

function M.zen()
    -- Clear regular search
    vim.cmd[[nohlsearch]]

    -- Clear notifications
    local has_notify, notify = pcall(require, 'notify')
    if has_notify then notify.dismiss() end

    -- Hide search from galaxyline
    local has_gl, gl = pcall(require, 'galaxyline')
    if has_gl then
        gl._mysection.search_active = false
        gl.load_galaxyline()  -- force redraw
    end

    -- Close all Noice windows
    local curr_tab = vim.api.nvim_get_current_tabpage()
    local windows = vim.api.nvim_tabpage_list_wins(curr_tab)

    -- Iterate in reverse to avoid issues with window IDs changing during closure
    for i = #windows, 1, -1 do
        local win = windows[i]
        if vim.api.nvim_win_is_valid(win) then
            local buf = vim.api.nvim_win_get_buf(win)
            local filetype = vim.api.nvim_buf_get_option(buf, 'filetype')
            if filetype == 'noice' then
                vim.api.nvim_win_close(win, false)
            end
        end
    end
end

function M.setup()
    local Utils = require'utils'
    local has_wk, wk = pcall(require, 'which-key')
    if not has_wk then
        vim.print('Failed to load plugin \'which-key\'')
        return
    end

    -- Normal mode
    wk.add{
        { '<Esc>', M.zen, desc = 'Zen. Hide search results and close noisy windows.' },
        { '<BS>', ':%s/\\s\\+$//<cr>:w<cr>', desc = 'Remove trailing whitespaces' },
        { '<F3>', function() Utils.toggle(vim.wo, 'spell') end, desc = 'Toggle spell' },
        { '<F4>', function() Utils.toggle(vim.wo, 'cursorcolumn') end, desc = 'Toggle crosshair' },
        { '<F7>', function()
            if Utils.toggle_quickfix() then
                vim.fn.feedkeys('G', 'n')  -- scroll to end
            end
        end, desc = 'Toggle QuickFix window' },
        { '<C-q>', function()
            local tab_count = #vim.api.nvim_list_tabpages()
            if tab_count > 1 then
                vim.cmd[[tabclose]]
            end
        end, desc = 'Close tab' },
        { '<space>q', '<cmd>only<cr>', desc = 'Close other windows' },
        -- Don't use ]c and [c; these are reserved for navigating diff chunks
        { ']l', '<cmd>cnext<cr>', desc = 'Next clist item' },
        { '[l', '<cmd>cprevious<cr>', desc = 'Previous clist item' },
        { '<space>hi', '<cmd>Inspect<cr>', desc = 'Show highlight groups under cursor' },
        { '<C-h>', function()
            vim.cmd('help ' .. vim.fn.expand'<cword>')
        end, desc = 'Show :help for word under cursor' },
    }

    -- Visual mode
    wk.add{
        mode = { 'v' },
        { '<C-s>', ':sort i<cr>', desc = 'Sort selected lines' },
        { '<C-r>', ':!tac<cr>', desc = 'Revert selected lines' },
        { '*', ':lua Utils.search_for_visual_selection(true)<cr>', desc = 'Search for visual selection' },
        { '?', ':lua Utils.search_for_visual_selection(false)<cr>', desc = 'Reverse search for visual selection' },
    }

    -- Terminal mode
    wk.add{
        mode = { 't' },
        { '<C-l>', function()
            vim.fn.feedkeys('', 'n')
            local sb = vim.bo.scrollback
            vim.bo.scrollback = 1
            vim.bo.scrollback = sb
        end, desc = 'Clear terminal' },
        {
            expr = true,
            { '<C-v>', function()
                local next_char_code = vim.fn.getchar()
                local next_char = vim.fn.nr2char(next_char_code)
                return '<C-\\><C-N>"'..next_char..'pi'
            end, desc = 'Access registers' },
        }
    }
end

return M
