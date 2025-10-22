local function make_env_string(env)
    local str = 'env '
    for key, value in pairs(env) do
        str = str .. tostring(key) .. '="' .. tostring(value) .. '" '
    end
    return str
end

return {
    {
        'akinsho/toggleterm.nvim',
        version = '*',
        dependencies = {
            'folke/which-key.nvim',
        },
        config = function()
            local toggleterm = require'toggleterm'
            toggleterm.setup{
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
                cmd = make_env_string({
                    ['GPG_TTY'] = '$(tty)',
                    ['SSH_AUTH_SOCK'] = '$XDG_RUNTIME_DIR/ssh-agent.socket',
                    ['NVIM_LISTEN_ADDRESS'] = tostring(vim.v.servername),
                }) .. ' lazygit',
                dir = 'git_dir',
                direction = 'tab',
                -- function to run on opening the terminal
                on_open = function(term)
                    -- Install keymaps
                    local function close()
                        vim.api.nvim_win_close(term.window, false)

                        if term.previous_tab then
                            vim.schedule(function()
                                local current_tab = vim.api.nvim_get_current_tabpage()

                                if current_tab ~= term.previous_tab then
                                    -- Check if previous tab still exists and is different from current
                                    local tab_exists = false
                                    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
                                        if tab == term.previous_tab then
                                            tab_exists = true
                                            break
                                        end
                                    end

                                    if tab_exists then
                                        vim.api.nvim_set_current_tabpage(term.previous_tab)
                                    end
                                end
                            end)
                        end
                    end
                    vim.api.nvim_buf_set_keymap(term.bufnr, 'i', '<C-q>', '', {noremap = true, silent = true, callback = close})
                    vim.api.nvim_buf_set_keymap(term.bufnr, 'n', '<C-q>', '', {noremap = true, silent = true, callback = close})
                    vim.api.nvim_buf_set_keymap(term.bufnr, 't', '<C-q>', '', {noremap = true, silent = true, callback = close})

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
                    vim.bo[term.bufnr].spell = false  -- no spell checking
                    vim.cmd[[nohlsearch]]  -- no search highlighting (until next search)
                    vim.cmd[[startinsert!]]
                end,
            }

            local float_term = Terminal:new{
                direction = 'float',
                float_opts = {
                    border = 'double',
                },
                on_open = function(term)
                    vim.bo[term.bufnr].spell = false  -- no spell checking
                    vim.cmd[[nohlsearch]]  -- no search highlighting (until next search)
                    vim.cmd[[startinsert!]]
                end,
            }

            local ipython = Terminal:new{
                cmd = 'ipython',
                direction = 'vertical',
                on_open = function(term)
                    local winid = vim.api.nvim_get_current_win()
                    vim.api.nvim_win_set_width(winid, 80)
                    vim.bo[term.bufnr].spell = false  -- no spell checking
                    vim.cmd[[startinsert!]]
                end,
            }

            require'which-key'.add{
                { '<leader>gl', function()
                    lazygit.previous_tab = vim.api.nvim_get_current_tabpage()
                    lazygit:toggle()
                end, desc = 'Lazygit' },
                { '<leader>ft', '<cmd>TermSelect<cr>', desc = 'Select toggle term' },

                { '<leader>r', group = 'Run command…' },
                { '<leader>rr', function() ranger:toggle() end, desc = 'File Ranger' },
                { '<leader>rt', function() float_term:toggle() end, desc = 'Floating Terminal' },
                { '<leader>rp', function() ipython:toggle() end, desc = 'IPython Interpreter' },
            }
        end,
    },
}
