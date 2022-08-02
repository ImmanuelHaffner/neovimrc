local M = { }

local utils = require('lua/utils')

function M.setup()
    local has_wk, wk = pcall(require, 'which-key')
    local has_bufferline, bufferline = pcall(require, 'bufferline')

    ----- Global mappings {{{-------------------------------------------------------------------------------------------
    -- Select a session
    if has_wk then
        wk.register({
            name = 'Sessions',
            l = { function() require('session_manager').load_session() end, "Load a session" }
        }, { prefix = '<Leader>' })
    end

    -- Toggle spell checking
    vim.keymap.set('n', '<F3>', function()
        vim.opt.spell = not vim.o.spell
    end)

    -- Toggle cursor column
    vim.keymap.set('n', '<F4>', function()
        vim.o.cursorcolumn = not vim.o.cursorcolumn
    end)

    vim.keymap.set('n', '<F5>', ':AsyncRun -program=make<CR>')

    -- Sort visual lines
    vim.keymap.set('v', '<C-s>', ':sort i<CR>', { silent = true })

    -- Revert visual lines
    vim.keymap.set('v', '<C-r>', ':!tac<CR>', { silent = true })

    -- Switch to previous tab
    vim.api.nvim_create_autocmd('TabLeave', { command = 'let g:lasttab = tabpagenr()' })
    --vim.keymap.set('n', 'g<Tab>', ':exe "tabn ".g:lasttab<CR>', { silent = true })
    if has_wk then
        wk.register{
            name = 'Tabs',
            ['g<Tab>'] = { '<cmd>exe "tabn ".g:lasttab<cr>', 'Switch to previous tab' }
        }
    end

    -- Delete trailing whitespaces
    vim.keymap.set('n', '<BS>', ':%s/\\s\\+$//<CR>:w<CR>', { silent = true })

    vim.keymap.set('x', '*', ':lua require("lua/utils").search_for_visual_selection(true)<cr>', { silent = true })
    vim.keymap.set('x', '?', ':lua require("lua/utils").search_for_visual_selection(false)<cr>', { silent = true })
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- Plugin mappings {{{-------------------------------------------------------------------------------------------
    vim.keymap.set('n', '<C-c>', ":call nerdcommenter#Comment('n', 'toggle')<CR>", { silent = true })
    vim.keymap.set('v', '<C-c>', ":call nerdcommenter#Comment('x', 'toggle')<CR>", { silent = true })

    vim.keymap.set('n', '<F2>', ':NvimTreeToggle<CR>', { silent = true })

    if has_wk then
        wk.register({
            name = 'Telescope',
            f = { function() require('telescope.builtin').find_files() end, 'Find file' },
            g = {
                f = { function() require('telescope.builtin').git_files() end, 'Find file tracked in Git' },
                b = { function() require('telescope.builtin').git_branches() end, 'Find Git branch' },
                c = { function() require('telescope.builtin').git_commits() end, 'Find Git commit' },
                h = { function() require('telescope.builtin').git_bcommits() end, 'Find buffer\'s Git commit (history)' },
            },
        }, { prefix = 'f' })
    end

    if has_bufferline then
        if has_wk then
            wk.register({
                name = 'Bufferline',
                t = { '<cmd>BufferLineCycleNext<cr>', 'Goto next tab' },
                T = { '<cmd>BufferLineCyclePrev<cr>', 'Goto previous tab' },
            }, { prefix = 'g', silent = true })
        else
        end
    end
    --}}}---------------------------------------------------------------------------------------------------------------

end

return M
