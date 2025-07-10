local utils = require 'utils'

--- List of filetypes that would be removed by saving the session.
local FRAGILE_FILETYPES = {
    'codecompanion',
    'DiffviewFiles',
    'mcphub',
    'neo-tree',
    'noice',
    'trouble',
}

--- List of buftypes that would be removed by saving the session.
local FRAGILE_BUFTYPES = {
    'quickfix',
    'terminal',
}

return {
    { 'Shatur/neovim-session-manager',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'folke/which-key.nvim',
        },
        config = function()
            local Path = require'plenary.path'
            local session_manager = require'session_manager'
            session_manager.setup{
                sessions_dir = Path:new(vim.fn.stdpath('data'), '.sessions'), -- The directory where the session files will be saved.
                path_replacer = '__', -- The character to which the path separator will be replaced for session files.
                colon_replacer = '++', -- The character to which the colon symbol will be replaced for session files.
                autoload_mode = require('session_manager.config').AutoloadMode.CurrentDir, -- Define what to do when Neovim is started without arguments. Possible values: Disabled, CurrentDir, LastSession
                autosave_last_session = true, -- Automatically save last session on exit and on session switch.
                autosave_ignore_not_normal = true, -- Plugin will not save a session when no buffers are opened, or all of them aren't writable or listed.
                autosave_ignore_dirs = { -- A list of directories where the session will not be autosaved.
                    vim.fn.expand('$HOME'),  -- don't save sessions in $HOME
                },
                autosave_ignore_filetypes = { -- All buffers of these file types will be closed before the session is saved.
                    'gitcommit',
                    'gitrebase',
                },
                -- autosave_ignore_buftypes = {
                --     'terminal',
                -- },
                autosave_only_in_session = true, -- Only autosave after a session is active.
                max_path_length = 0,  -- Shorten the display path if length exceeds this threshold. Use 0 if don't want to shorten the path at all.
            }

            local function save_and_exit()
                session_manager.save_current_session()
                -- Force-close all terminals
                for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                    if vim.bo[buf].buftype == 'terminal' then
                        vim.api.nvim_buf_delete(buf, { force = true })
                    end
                end
                vim.cmd[[wqa]]
            end

            -- Quit function
            vim.api.nvim_create_user_command('Q', save_and_exit, {})

            -- Keymap
            require'which-key'.add{
                { '<leader>s', group = 'Sessions' },
                { '<leader>sl', function() require('session_manager').load_session() end, desc = "Load a session" },
                { '<leader>ss', function()
                    require('session_manager').save_current_session()
                    vim.api.nvim_echo({{ 'Session saved.' }}, true, {})
                end, desc = "Save current session" },
                { '<leader>sd', function() require('session_manager').delete_session() end, desc = "Delete a session" },
            }

            -- Track the time in seconds since application launch when the session was saved for the last time.
            local last_session_save_time = vim.loop.uptime()

            vim.api.nvim_create_autocmd({ 'CursorHold' }, {
                callback = function()
                    local now = vim.loop.uptime()
                    local diff = now - last_session_save_time

                    -- Wait for timeout.
                    if diff < 120 then return end

                    -- Only save while in 'normal' mode.
                    if vim.fn.mode() ~= 'n' then return end

                    -- Only save if already in a session.
                    if not session_manager.current_dir_session_exists() then return end

                    -- Don't save when there is a visible buffer that is ephemeral and that would be removed by saving
                    -- the session.
                    local is_ephemeral_buffer = function(bufid)
                        local bufname = vim.api.nvim_buf_get_name(bufid)
                        local buftype = vim.api.nvim_get_option_value('buftype', { buf = bufid })
                        local buflisted = vim.api.nvim_get_option_value('buflisted', { buf = bufid })
                        local filetype = vim.api.nvim_get_option_value('filetype', { buf = bufid })

                        -- Don't save ephemeral buffers
                        if buflisted == true and buftype == '' and bufname == '' then return true end
                        -- Don't save certain filetypes
                        if vim.tbl_contains(FRAGILE_FILETYPES, filetype) then return true end
                        -- Don't save certain buftypes
                        if vim.tbl_contains(FRAGILE_BUFTYPES, buftype) then return true end
                    end
                    if utils.any_visible_buffer(is_ephemeral_buffer) then return end

                    last_session_save_time = now
                    session_manager.save_current_session()
                    vim.notify('Auto-saved current session.', vim.log.levels.INFO, { title = 'Session Manager' })
                end
            })
        end
    },
}
