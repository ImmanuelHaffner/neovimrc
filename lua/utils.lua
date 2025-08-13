local M = { }

local colors = require'theme'.colors()

function M.toggle(tbl, opt)
    tbl[opt] = not tbl[opt]
end

function M.starts_with(str, start)
    return start == "" or str:sub(1, #start) == start
end

function M.ends_with(str, ending)
    return ending == "" or str:sub(-#ending) == ending
end

function M.select(cond, tru, fals)
    if cond then return tru else return fals end
end

--- Removes leading and trailing white spaces from a string.
--- @param str string
--- @return string trimmed
function M.trim(str)
    return str:match '^%s*(.-)%s*$'
end

function M.is_buffer_empty()
    -- Check whether the current buffer is empty
    return vim.fn.empty(vim.fn.expand('%:t')) == 1
end

function M.has_width_gt(cols)
    -- Check if the windows width is greater than a given number of columns
    return vim.fn.winwidth(0) / 2 > cols
end

function M.get_visual_selection()
    local start_row, start_col = unpack(vim.api.nvim_buf_get_mark(0, '<'))
    local end_row,   end_col   = unpack(vim.api.nvim_buf_get_mark(0, '>'))
    local lines = vim.api.nvim_buf_get_text(0, start_row - 1, start_col, end_row - 1, end_col + 1, {})
    return table.concat(lines, '\n')
end

function M.search_for_visual_selection(forward)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local selection = M.get_visual_selection()
    local escaped = vim.fn.escape(selection, '/\\')
    if forward then
        pcall(vim.cmd, '/\\V' .. escaped)
    else
        pcall(vim.cmd, '?\\V' .. escaped)
    end
    vim.api.nvim_win_set_cursor(0, cursor_pos)
end

function M.split_str(str, sep)
    if sep == nil then
        sep = '%s' -- split on white-space
    end
    local fields = {}
    for field in string.gmatch(str, "([^"..sep.."]+)") do
        table.insert(fields, field)
    end
    return fields
end

function M.basename(path)
    return string.match(path, '/([^/]+)$')
end

function M.shorten_path(path, max_len)
    if path == nil or path == '' then return path end

    local len = path:len()
    local fields = M.split_str(path, '/')

    -- Shorten fields until path is short enough
    for idx, field in ipairs(fields) do
        if len <= max_len then break end -- overall short enough
        if idx == #fields then break end -- don't shorten last field

        local PATH_SHORTEN_SYMBOL = '…'  -- symbol to shorten path: …, 
        local short_field = field:sub(1, 1) .. PATH_SHORTEN_SYMBOL
        local saved = field:len() - (short_field:len() - 2) -- subtract 2 for unicode char 
        len = len - saved
        fields[idx] = short_field
    end

    -- Reconstruct path
    local s, _ = path:find('/', 1)
    local starts_with_sep = s == 1
    local short_path = M.select(starts_with_sep, '/', '')
    short_path = short_path .. fields[1] -- first field
    for idx = 2, #fields do
        short_path = short_path .. '/' .. fields[idx]
    end
    return short_path
end

function M.shorten_absolute_path(path, max_len)
    if path == nil or path == '' then return path end
    local home_dir = os.getenv('HOME')
    local s, e = path:find(home_dir, 1, true) -- plain search
    if s == 1 then -- path is in HOME
        return '~' .. M.shorten_path(path:sub(e + 1, -1), max_len - 1)
    else
        return M.shorten_path(path, max_len)
    end
end

function M.shorten_relative_path(path, max_len)
    if path == nil or path == '' then return path end
    local cwd = vim.fn.getcwd() .. '/'
    local s, e = path:find(cwd, 1, true) -- plain search
    if s == 1 then -- path is in CWD
        local rel_path = path:sub(e + 1, -1)
        return M.shorten_path(rel_path, max_len)
    elseif path:sub(1, 1) == '~' then -- path starts with '~'
        return M.shorten_path(path:sub(3, -1), max_len)
    elseif path:sub(1, 1) == '/' then -- path starts with '/'
        return M.shorten_absolute_path(path, max_len)
    else
        return M.shorten_path(path, max_len)
    end
end

-- Returns true iff quickfix window was opened and is now visible and focused
function M.toggle_quickfix()
    local curr_tab = vim.api.nvim_get_current_tabpage()
    local wins = vim.api.nvim_tabpage_list_wins(curr_tab)
    -- If quickfix window exists, close it.
    for _, winid in ipairs(wins) do
        local win_info = vim.fn.getwininfo(winid)[1]
        if win_info['quickfix'] == 1 then
            vim.cmd[[cclose]]
            return false
        end
    end

    -- Quickfix window does not exist.  If there is content, open quickfix window.
    vim.cmd[[copen]]
    return true
end

function M.get_vim_mode_info()
    local vim_modes = {
        ['n']   = { colors.green,       'NORMAL' },
        ['i']   = { colors.blue,        'INSERT' },
        ['c']   = { colors.red2,        'COMMAND' },
        ['t']   = { colors.yellow,      'TERMINAL' },
        ['v']   = { colors.purple3,     'VISUAL' },
        ['']  = { colors.purple3,     'V-BLOCK' },
        ['V']   = { colors.purple3,     'V-LINE' },
        ['R']   = { colors.light_red,   'REPLACE' },
        ['s']   = { colors.light_red,   'SELECT' },
        ['S']   = { colors.light_red,   'S-LINE' },
        ['']  = { colors.light_red,   'S-BLOCK' },
        ['r']   = { colors.cyan4,       'PROMPT' },
        ['!']   = { colors.dark_red,    'SHELL' },
    }

    local mode = vim.fn.mode(1) or ''

    -- Check for OPERATOR PENDING mode.
    if mode:sub(1, 2) == 'no' then
        return { colors.orange, 'OPERATOR' }
    end

    local chr = mode:sub(1, 1) or 0
    local current_mode = vim_modes[chr]
    return current_mode or { colors.dark_red, 'UNKNOWN ' .. mode }
end

--- Checks whether there is a buffer that is currently visible in a window and that satisfies `pred`.
--- @param pred function a predicate that returns `true` if the buffer satisfies some condition and `false` otherwise
--- @return boolean  `true` if any buffer satisfies `pred`
function M.any_visible_buffer(pred)
    local tabpages = vim.api.nvim_list_tabpages()
    for _, tabid in ipairs(tabpages) do
        local windows = vim.api.nvim_tabpage_list_wins(tabid)
        for _, winid in ipairs(windows) do
            local bufid = vim.api.nvim_win_get_buf(winid)
            if pred(bufid) then return true end
        end
    end
    return false
end

--- Checks whether this is a local nvim instance.
--- @return boolean `true` if this is a local nvim instance, `false` otherwise
function M.is_local_nvim()
    return os.getenv'DISPLAY' ~= nil and M.starts_with(vim.v.servername, '/')
end

--- Checks whether the UI is connected to a headless server.
--- Can be used to conditionally enable plugins.
--- @return boolean `true` if the UI is connected to a headless server, `false` otherwise
function M.is_headless_server()
    return not M.is_local_nvim()
end

function M.get_highlight_group(name)
    if vim.fn.hlexists(name) ~= 1 then
        return nil
    end
    local syn_id = vim.fn.synIDtrans(vim.fn.hlID(name))

    return {
        bg = vim.fn.synIDattr(syn_id, 'bg'),
        fg = vim.fn.synIDattr(syn_id, 'fg'),
        sp = vim.fn.synIDattr(syn_id, 'sp'),
        bold = vim.fn.synIDattr(syn_id, 'bold') == 1,
        italic = vim.fn.synIDattr(syn_id, 'italic') == 1,
        inverse = vim.fn.synIDattr(syn_id, 'inverse') == 1,
        underline = vim.fn.synIDattr(syn_id, 'underline') == 1,
        undercurl = vim.fn.synIDattr(syn_id, 'undercurl') == 1,
        underdouble = vim.fn.synIDattr(syn_id, 'underdouble') == 1,
        underdotted = vim.fn.synIDattr(syn_id, 'underdotted') == 1,
        underdashed = vim.fn.synIDattr(syn_id, 'underdashed') == 1,
        strikethrough = vim.fn.synIDattr(syn_id, 'strikethrough') == 1,
    }
end

return M
