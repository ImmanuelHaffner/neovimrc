local function make_env_string(env)
    local str = 'env '
    for key, value in pairs(env) do
        str = str .. tostring(key) .. '="' .. tostring(value) .. '" '
    end
    return str
end

local function goto_previous_tab(previous_tab)
    if previous_tab == nil then return end
    vim.schedule(function()
        local current_tab = vim.api.nvim_get_current_tabpage()

        if current_tab ~= previous_tab then
            -- Check if previous tab still exists and is different from current
            local tab_exists = false
            for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
                if tab == previous_tab then
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

            -- Function to get SSH_AUTH_SOCK value based on platform and existing environment
            local function get_ssh_auth_sock()
                -- First check if SSH_AUTH_SOCK is already set in environment
                local existing_ssh_auth_sock = vim.env.SSH_AUTH_SOCK
                if existing_ssh_auth_sock and existing_ssh_auth_sock ~= '' then
                    return existing_ssh_auth_sock
                end

                -- If not set, determine platform-specific default
                local uname = vim.fn.system('uname -s'):gsub('\n', '')
                if uname == 'Darwin' then
                    -- macOS: ssh-agent (dealing with weirdly inconsistent socket path)
                    local possible_sockets = vim.fn.glob('/private/tmp/com.apple.launchd.*/Listeners', false, true)

                    if #possible_sockets > 1 then
                        vim.notify('Found multiple possible ssh-agent sockets; you should probably investigate this.', vim.log.levels.WARN)
                    end

                    for _, possible_socket in ipairs(possible_sockets) do
                        if vim.fn.filereadable(possible_socket) == 1 then
                            return possible_socket
                        end
                    end

                    -- Fallback if no socket found
                    return nil
                else
                    -- Linux/other Unix systems typically use XDG_RUNTIME_DIR
                    return '$XDG_RUNTIME_DIR/ssh-agent.socket'
                end
            end

            local custom_env = {
                ['GPG_TTY'] = '$(tty)',
                ['SSH_AUTH_SOCK'] = get_ssh_auth_sock(),
                ['NVIM_LISTEN_ADDRESS'] = tostring(vim.v.servername),
            }
            local env_string = make_env_string(custom_env)

            local lazygit = Terminal:new{
                cmd = env_string .. ' lazygit',
                dir = 'git_dir',
                direction = 'tab',
                -- function to run on opening the terminal
                on_open = function(term)
                    -- Install keymaps
                    local function close()
                        vim.api.nvim_win_close(term.window, false)
                        goto_previous_tab(term.previous_tab)
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

            local claude_code = Terminal:new{
                cmd = 'llm agent claude',
                dir = vim.fn.getcwd(),
                direction = 'tab',
                on_open = function(term)
                    vim.wo[term.window].scrolloff = 0
                    vim.wo[term.window].sidescrolloff = 0
                    vim.wo[term.window].spell = false  -- no spell checking
                    vim.cmd[[nohlsearch]]  -- no search highlighting (until next search)
                    vim.cmd[[startinsert!]]
                    vim.fn.setcursorcharpos(1, 1)
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
                    vim.wo[term.window].spell = false  -- no spell checking
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
                    vim.wo[term.window].spell = false  -- no spell checking
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
                    vim.wo[term.window].spell = false  -- no spell checking
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
                { '<leader>rc', function() claude_code:toggle() end, desc = 'Claude Code' },
                { '<leader>rr', function() ranger:toggle() end, desc = 'File Ranger' },
                { '<leader>rt', function() float_term:toggle() end, desc = 'Floating Terminal' },
                { '<leader>rp', function() ipython:toggle() end, desc = 'IPython Interpreter' },
            }
        end,
    },
}
