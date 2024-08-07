local M = { }

function M.setup()
    -- Remember last tab
    vim.api.nvim_create_autocmd('TabLeave', { command = 'let g:lasttab = tabpagenr()' })

    local Utils = require'utils'
    local ok, wk = pcall(require, 'which-key')
    if not ok then
        vim.print('Failed to load plugin \'which-key\'')
        return
    end

    -- Normal mode
    wk.add{
        { '<Esc>', '<cmd>nohlsearch<cr>', desc = 'Hide search results' },
        { '<BS>', ':%s/\\s\\+$//<cr>:w<cr>', desc = 'Remove trailing whitespaces' },
        { '<F3>', function() Utils.toggle(vim.o, 'spell') end, desc = 'Toggle spell' },
        { '<F4>', function() Utils.toggle(vim.o, 'cursorcolumn') end, desc = 'Toggle crosshair' },
        { '<F7>', function()
            if Utils.toggle_quickfix() then
                vim.fn.feedkeys('G', 'n')  -- scroll to end
            end
        end, desc = 'Toggle QuickFix window' },
        { 'g<Tab>', '<cmd>exe "tabn " . g:lasttab<cr>', desc = 'Switch to previous tab' },
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
