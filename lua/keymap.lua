local M = { }

function M.setup()
    local Utils = require'utils'
    local has_wk, wk = pcall(require, 'which-key')
    if not has_wk then
        vim.print('Failed to load plugin \'which-key\'')
        return
    end

    -- Normal mode
    wk.add{
        { '<Esc>', function()
            -- Clear regular search
            vim.cmd[[nohlsearch]]

            -- Clear kaleidosearch
            local has_ks, ks = pcall(require, 'kaleidosearch')
            if has_ks then ks.clear_all_highlights() end

            -- Clear notifications
            local has_notify, notify = pcall(require, 'notify')
            if has_notify then notify.dismiss() end
        end, desc = 'Zen. Hide search results.' },
        { '<BS>', ':%s/\\s\\+$//<cr>:w<cr>', desc = 'Remove trailing whitespaces' },
        { '<F3>', function() Utils.toggle(vim.o, 'spell') end, desc = 'Toggle spell' },
        { '<F4>', function() Utils.toggle(vim.o, 'cursorcolumn') end, desc = 'Toggle crosshair' },
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
