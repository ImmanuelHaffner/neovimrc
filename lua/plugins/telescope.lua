local Utils = require 'utils'

local jump_to_line = function(self, bufnr, entry)
    local utils = require 'telescope.utils'
    local ns_previewer = vim.api.nvim_create_namespace 'telescope.previewers'
    pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns_previewer, 0, -1)

    if entry.lnum and entry.lnum > 0 then
        local lnum, lnend = entry.lnum - 1, (entry.lnend or entry.lnum) - 1

        local col, colend = 0, -1
        -- Both col delimiters should be provided for them to take effect.
        -- This is to ensure that column range highlighting was opted in, as `col`
        -- is already used to determine the buffer jump position elsewhere.
        if entry.col and entry.colend then
            col, colend = entry.col - 1, entry.colend - 1
        end

        for i = lnum, lnend do
            pcall(
                utils.hl_range,
                bufnr,
                ns_previewer,
                "TelescopePreviewLine",
                { i, i == lnum and col or 0 },
                { i, i == lnend and colend or -1 }
            )
        end

        local middle_ln = math.floor(lnum + (lnend - lnum) / 2)
        pcall(vim.api.nvim_win_set_cursor, self.state.winid, { middle_ln + 1, 0 })
        if bufnr ~= nil then
            vim.api.nvim_buf_call(bufnr, function()
                vim.cmd "norm! zz"
            end)
        end
    end
end

local function buffer_previewer(self, entry)
    local from_entry = require 'telescope.from_entry'
    local conf = require'telescope.config'.values

    -- builtin.buffers: bypass path validation for terminal buffers that don't have appropriate path
    local has_buftype = entry.bufnr and vim.api.nvim_buf_is_valid(entry.bufnr) and vim.bo[entry.bufnr].buftype ~= ""
    or false
    local p
    if not has_buftype then
        p = from_entry.path(entry, true, false)
        if p == nil or p == "" then
            return
        end
    end

    -- Workaround for unnamed buffer when using builtin.buffer
    if entry.bufnr and (p == "[No Name]" or has_buftype) then
        local lines = vim.api.nvim_buf_get_lines(entry.bufnr, 0, -1, false)
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        -- schedule so that the lines are actually there and can be jumped onto when we call jump_to_line
        vim.schedule(function()
            jump_to_line(self, self.state.bufnr, entry)
        end)
    else
        conf.buffer_previewer_maker(p, self.state.bufnr, {
            bufname = self.state.bufname,
            winid = self.state.winid,
            callback = function(bufnr)
                jump_to_line(self, bufnr, entry)
            end,
        })
    end
end

return {
    { 'nvim-telescope/telescope-fzf-native.nvim',
        build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5 && cmake --build build --config Release && cmake --install build --prefix build',
    },
    { 'nvim-telescope/telescope.nvim',
        dependencies = {
            'folke/which-key.nvim',
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope-fzf-native.nvim',
            'nvim-telescope/telescope-ui-select.nvim',
            'tknightz/telescope-termfinder.nvim',
        },
        config = function()
            local ts = require'telescope'
            local entry_display = require'telescope.pickers.entry_display'
            local builtins = require'telescope.builtin'
            local from_entry = require 'telescope.from_entry'
            local previewers = require'telescope.previewers'
            local devicons = require'nvim-web-devicons'

            local function custom_file_entry_maker(opts)
                opts = opts or {}
                local utils = require('telescope.utils')
                local max_len = opts.max_len or 60

                return function(entry)
                    local filename = utils.path_tail(entry)
                    local display_path = Utils.shorten_relative_path(entry, max_len)
                    local glyph, hl_group = devicons.get_icon(filename)

                    local display_formatter = entry_display.create{
                        separator = ' ',
                        items = {
                            { width = 1 },  -- Icon
                            { remaining = true } -- Path
                        }
                    }

                    local display_func = function()
                        return display_formatter{
                            { glyph or '', hl_group },
                            { display_path }
                        }
                    end

                    return {
                        value = entry,
                        ordinal = entry,
                        display = display_func,
                        filename = filename,
                        path = entry,
                    }
                end
            end

            local function custom_git_entry_maker(entry)
                local commit_hash, author, date, message = entry:match("^(%S+) (.-) (%d%d%d%d%-%d%d%-%d%d) (.+)$")

                if not commit_hash or not author or not date or not message then
                    return nil -- Skip malformed entries
                end

                local formatter = entry_display.create{
                    separator = ' ',
                    items = {
                        { width = 10 }, -- Commit hash
                        { width = 20 }, -- Author (custom color)
                        { width = 10 }, -- Date (custom color)
                        { width = 1 },  -- Separator
                        { remaining = true } -- Commit message
                    }
                }

                local display = function()
                    return formatter{
                        { commit_hash:sub(1, 10), 'TelescopePreviewLink' },     -- First column: commit hash
                        { author, 'TelescopeResultsNumber' },                   -- Second column: author name
                        { date, 'TelescopeResultsIdentifier'  },                -- Third column: date
                        { '│' },
                        { message },                                            -- Fourth column: commit message
                    }
                end

                return {
                    value = commit_hash,
                    ordinal = entry,
                    display = display,
                }
            end

            ts.setup{
                defaults = {
                    dynamic_preview_title = true,
                    mappings = {
                        n = {
                            ['<c-x>'] = require('telescope.actions').delete_buffer
                        },
                        i = {
                            ["<C-h>"] = "which_key",
                            ['<c-x>'] = require('telescope.actions').delete_buffer
                        },
                    },
                },
                pickers = {
                    find_files = {
                        prompt_prefix = '󰱼 ',  -- alternatives: 󰱽 󰮗 󰈞 󰱼 🔍
                        hidden = true,
                        no_ignore = true,
                        entry_maker = custom_file_entry_maker{max_len = 80},
                        previewer = previewers.new_buffer_previewer{
                            define_preview = buffer_previewer,
                            get_buffer_by_name = function(_, entry)
                                return from_entry.path(entry, false, false)
                            end,
                            title = 'Find files',
                            dyn_title = function(self, entry)
                                return Utils.shorten_relative_path(entry.value, 100)
                            end,
                        },
                    },
                    git_files = {
                        prompt_prefix = '  ',
                        entry_maker = custom_file_entry_maker{max_len = 80},
                        previewer = previewers.new_buffer_previewer{
                            define_preview = buffer_previewer,
                            get_buffer_by_name = function(_, entry)
                                return from_entry.path(entry, false, false)
                            end,
                            title = 'Git files',
                            dyn_title = function(self, entry)
                                return Utils.shorten_relative_path(entry.value, 100)
                            end,
                        },
                    },
                    git_branches = {
                        prompt_prefix = ' ',
                    },
                    git_commits = {
                        prompt_prefix = ' ',  -- alternatives:    
                        git_command = { 'git', 'log', '--pretty=%H %an %ad %s', '--date=short' },
                        entry_maker = custom_git_entry_maker,
                        previewer = previewers.new_termopen_previewer{
                            dyn_title = function(self, entry)
                                return 'Git commit: ' .. entry.value
                            end,
                            get_command = function(entry, status)
                                return {
                                    'env', 'LESS=', 'GIT_PAGER=delta --paging=always --pager=less',
                                    'git', '--paginate', 'show', '--color=never',  entry.value
                                }
                            end,
                        },
                    },
                    git_bcommits = {
                        prompt_prefix = '  ',
                        git_command = { 'git', 'log', '--pretty=%H %an %ad %s', '--date=short' },
                        entry_maker = custom_git_entry_maker,
                        previewer = previewers.new_termopen_previewer{
                            dyn_title = function(self, entry)
                                return 'Git commit: ' .. entry.value
                            end,
                            get_command = function(entry, status)
                                return {
                                    'env', 'LESS=', 'GIT_PAGER=delta --paging=always --pager=less',
                                    'git', '--paginate', 'show', '--color=never',  entry.value, '--', entry.current_file
                                }
                            end,
                        },
                    },
                    git_bcommits_range = {
                        prompt_prefix = '  ',
                        previewer = previewers.new_termopen_previewer{
                            dyn_title = function(self, entry)
                                return 'Git commit: ' .. entry.value
                            end,
                            get_command = function(entry, status)
                                return {
                                    'env', 'LESS=', 'GIT_PAGER=delta --paging=always --pager=less',
                                    'git', '--paginate', 'show', '--color=never',  entry.value, '--', entry.current_file
                                }
                            end,
                        },
                    },
                    buffers = {
                        prompt_prefix = ' ',
                        sort_lastused = true,
                        sort_mru = true,
                    },
                    live_grep = {
                        prompt_prefix = ' ',
                    },
                },

                extensions = {
                    ['fzf'] = {
                        fuzzy = true,                    -- false will only do exact matching
                        override_generic_sorter = true,  -- override the generic sorter
                        override_file_sorter = true,     -- override the file sorter
                        case_mode = 'smart_case',        -- or "ignore_case" or "respect_case"
                    },
                    ['ui-select'] = {
                        require'telescope.themes'.get_dropdown { }
                    },
                }
            }
            ts.load_extension'fzf'
            ts.load_extension'ui-select'
            local termfinder = require'telescope'.load_extension'termfinder'

            local wk = require'which-key'
            wk.add{
                { '<leader>f', group = 'Telescope' },
                { '<leader>ff', function() builtins.find_files() end, desc = 'Find file' },
                { '<leader>fb', function() builtins.buffers() end, desc = 'Select buffer' },
                { '<leader>fc', function() builtins.tags() end, desc = 'Select ctag' },
                { '<leader>fl', function() builtins.live_grep() end, desc = 'Live grep' },
                {
                    { '<leader>fg', group = 'Find Git …' },
                    { '<leader>fgf', function() builtins.git_files() end, desc = 'Find file tracked in Git' },
                    { '<leader>fgb', function() builtins.git_branches() end, desc = 'Find Git branch' },
                    { '<leader>fgc', function() builtins.git_commits() end, desc = 'Find Git commit' },
                    { '<leader>fgh', function() builtins.git_bcommits() end, desc = 'Find buffer\'s Git commit (history)' },
                },
                {
                    { '<leader>fs', group = 'Code search …' },
                    { '<leader>fst', function() builtins.lsp_type_definitions() end, desc = 'Find types' },
                    { '<leader>fss', function()
                            builtins.lsp_dynamic_workspace_symbols{prompt_prefix='󱃖 '}
                        end,
                        desc = 'Find symbols'
                    },
                    { '<leader>fsd', function()
                            builtins.diagnostics{ severity_limit = vim.diagnostic.severity.WARN, prompt_prefix=' ' }
                        end,
                        desc = 'Search diagnostics'
                    },
                },
                { '<leader>fr', function() builtins.resume() end, desc = 'Resume' },
                { '<leader>f\\', function() termfinder.find{prompt_prefix=' '} end, desc = 'Find terminal' },
            }
            wk.add{
                mode = { 'v' },
                { '<leader>fgh', function() builtins.git_bcommits_range() end, desc = 'Find line\'s Git commit (history)' },
            }
        end
    },
}
