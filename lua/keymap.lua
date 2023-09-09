local M = { }

-- Remember last tab
vim.api.nvim_create_autocmd('TabLeave', { command = 'let g:lasttab = tabpagenr()' })

function M.setup()
    local Utils = require'utils'
    local ok, wk = pcall(require, 'which-key')
    if not ok then
        vim.print('Failed to load plugin \'which-key\'')
        return
    end

    -- Normal mode
    wk.register({
        ['<Esc>']  = { '<cmd>nohlsearch<cr>', 'Hide search results' },
        ['<BS>']   = { ':%s/\\s\\+$//<cr>:w<cr>', 'Remove trailing whitespaces' },
        ['<F3>']   = { function() Utils.toggle(vim.o, 'spell') end, 'Toggle spell' },
        ['<F4>']   = { function() Utils.toggle(vim.o, 'cursorcolumn') end, 'Toggle crosshair' },
        ['g<Tab>'] = { '<cmd>exe "tabn " . g:lasttab<cr>', 'Switch to previous tab' },
    }, { silent = true })

    -- Visual mode
    wk.register({
        ['<C-s>'] = { ':sort i<cr>', 'Sort selected lines' },
        ['<C-r>'] = { ':!tac<cr>', 'Revert selected lines' },
        ['*']     = { ':lua Utils.search_for_visual_selection(true)<cr>', 'Search for visual selection' },
        ['?']     = { ':lua Utils.search_for_visual_selection(false)<cr>', 'Reverse search for visual selection' },
    }, { silent = false, mode = 'v' })
end

return M
