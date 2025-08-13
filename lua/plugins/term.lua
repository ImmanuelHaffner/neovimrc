return {
    { 'akinsho/toggleterm.nvim',
        version = "*",
        dependencies = {
            'folke/which-key.nvim',
        },
        config = function()
            local term = require'toggleterm'
            term.setup{
                open_mapping = [[<c-\>]],
                shade_terminals = false,
                autochdir = true,
                auto_scroll = false,
                insert_mappings = false,
                terminal_mappings = false,
                float_opts = {
                    zindex = 200,
                },
            }

            local Terminal = require'toggleterm.terminal'.Terminal

            local lazygit = Terminal:new{
                cmd = 'env GPG_TTY=$(tty) SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket" lazygit',
                dir = 'git_dir',
                direction = 'tab',
                -- function to run on opening the terminal
                on_open = function(term)
                    -- Install keymaps
                    local cmd = ([[<cmd>lua vim.api.nvim_win_close(%d, false)<CR>]]):format(term.window)
                    vim.api.nvim_buf_set_keymap(term.bufnr, 'i', '<C-q>', cmd, {noremap = true, silent = true})
                    vim.api.nvim_buf_set_keymap(term.bufnr, 'n', '<C-q>', cmd, {noremap = true, silent = true})
                    vim.api.nvim_buf_set_keymap(term.bufnr, 't', '<C-q>', cmd, {noremap = true, silent = true})

                    vim.wo[term.window].scrolloff = 0
                    vim.wo[term.window].sidescrolloff = 0
                    vim.wo[term.window].spell = false  -- no spell checking
                    vim.cmd[[nohlsearch]]  -- no search highlighting (until next search)
                    vim.cmd[[startinsert!]]
                    vim.fn.setcursorcharpos(1, 1)
                end,
                  -- function to run on closing the terminal
                  on_close = function(term)
                      -- Cleanup keymaps
                      vim.api.nvim_buf_del_keymap(term.bufnr, 'i', '<C-q>')
                      vim.api.nvim_buf_del_keymap(term.bufnr, 'n', '<C-q>')
                      vim.api.nvim_buf_del_keymap(term.bufnr, 't', '<C-q>')

                      -- Schedule tab switch to happen after window cleanup
                      vim.schedule(function()
                          vim.cmd[[tabprevious]]
                      end)
                  end,
            }

            local ranger = Terminal:new{
                cmd = 'ranger',
                direction = 'float',
                float_opts = {
                    border = 'double',
                },
                -- function to run on opening the terminal
                on_open = function(term)
                    vim.wo.spell=false  -- no spell checking
                    vim.cmd[[nohlsearch]]  -- no search highlighting (until next search)
                    vim.api.nvim_buf_set_keymap(term.bufnr, 'n', 'q', '<cmd>close<CR>', {noremap = true, silent = true})
                    vim.cmd[[startinsert!]]
                end,
            }

            local float_term = Terminal:new{
                direction = 'float',
                float_opts = {
                    border = 'double',
                },
                on_open = function(term)
                    vim.wo.spell=false  -- no spell checking
                    vim.cmd[[nohlsearch]]  -- no search highlighting (until next search)
                    vim.api.nvim_buf_set_keymap(term.bufnr, 't', '<C-q>', '<cmd>close<CR>', {noremap = true, silent = true})
                    vim.cmd[[startinsert!]]
                end,
            }

            local ipython = Terminal:new{
                cmd = 'ipython',
                direction = 'vertical',
                on_open = function(term)
                    local winid = vim.api.nvim_get_current_win()
                    vim.api.nvim_win_set_width(winid, 80)
                    vim.api.nvim_buf_set_keymap(term.bufnr, "t", "<C-q>", "<cmd>close<CR>", {noremap = true, silent = true})
                    vim.cmd[[startinsert!]]
                end,
            }

            require'which-key'.add{
                { '<leader>gl', function() lazygit:toggle() end, desc = 'Lazygit' },
                { '<leader>ft', '<cmd>TermSelect<cr>', desc = 'Select toggle term' },

                { '<leader>r', group = 'Run command…' },
                { '<leader>rr', function() ranger:toggle() end, desc = 'File Ranger' },
                { '<leader>rt', function() float_term:toggle() end, desc = 'Floating Terminal' },
                { '<leader>rp', function() ipython:toggle() end, desc = 'IPython Interpreter' },
            }
        end,
    },
}
