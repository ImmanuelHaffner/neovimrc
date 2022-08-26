local M = {}

function M.select(cond, tru, fals)
    if cond then return tru else return fals end
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
    -- print(vim.inspect({start_row, start_col, end_row, end_col}))
    local lines = vim.api.nvim_buf_get_text(0, start_row - 1, start_col, end_row - 1, end_col + 1, {})
    -- print(vim.inspect(lines))
    return table.concat(lines, '\n')
end

function M.search_for_visual_selection(forward)
    local cursor_pos = vim.api.nvim_win_get_cursor(0)
    local selection = M.get_visual_selection()
    local escaped = vim.fn.escape(selection, '/\\')
    if forward then
        pcall(vim.cmd, '/' .. escaped)
    else
        pcall(vim.cmd, '?' .. escaped)
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

function M.shorten_path(path, max_len)
    if path == '' then return path end

    local len = path:len()
    local fields = M.split_str(path, '/')
    print('fields: ' .. vim.inspect(fields))

    -- Shorten fields until path is short enough
    for idx, field in ipairs(fields) do
        if len <= max_len then break end -- overall short enough
        if idx == #fields then break end -- don't shorten last field

        local short_field = field:sub(1, 1) .. ''
        local saved = field:len() - (short_field:len() - 2) -- subtract 2 for unicode char 
        len = len - saved
        print(idx .. ': ' .. field .. ' to ' .. short_field .. ', new len is ' .. len)
        fields[idx] = short_field
    end

    -- Reconstruct path
    local s, e = path:find('/', 1)
    local starts_with_sep = s == 1
    print('path starts with separator? ' .. tostring(starts_with_sep))
    local short_path = M.select(starts_with_sep, '/', '')
    short_path = short_path .. fields[1] -- first field
    for idx = 2, #fields do
        short_path = short_path .. '/' .. fields[idx]
    end
    return short_path
end

function M.shorten_absolute_path(path, max_len)
    local home_dir = os.getenv('HOME')
    local s, e = path:find(home_dir)
    if s == 1 then -- path is in HOME
        return '~' .. M.shorten_path(path:sub(e + 1, -1), max_len - 1)
    else
        return M.shorten_path(peth, max_len)
    end
end

function M.shorten_relative_path(path, max_len)
    print('shorten relative path ' .. path)
    local pwd = vim.fn.getcwd()
    if pwd == '/' then
        return M.shorten_absolute_path(path, max_len)
    end

    pwd = pwd .. '/'
    local s, e = path:find(pwd)
    if s == 1 then -- path is in CWD
        local rel_path = path:sub(e + 1, -1)
        print('actually shorten ' .. rel_path)
        return M.shorten_path(rel_path, max_len)
    else
        return M.shorten_path(path, max_len)
    end
end


return M
