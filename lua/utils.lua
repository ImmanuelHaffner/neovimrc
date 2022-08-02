local M = {}

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

function M.shorten_path(path, max_len)
    local home_dir = os.getenv('HOME')
    local short_path = ''

    -- rewrite $HOME to '~'
    local s, e = path:find(home_dir)
    local is_in_home = s == 1
    if is_in_home then
        path = path:sub(e + 1, -1)
        short_path = '~'
    end

    local len = path:len()
    local pos = 1
    while true do
        local s, e = path:find('/[^/]+', pos) -- find next field
        if s == nil then
            break
        end

        local field = path:sub(s, e) -- extract field

        -- Never shorten the last field
        if e == path:len() then
            short_path = short_path .. field
            break
        end

        -- Shorten the field
        local short_field = field:sub(1, 2) .. ''
        local saved = field:len() - (short_field:len() - 2) -- subtract 2 for unicode char 

        -- Select short or full field
        if len > max_len and saved > 0 then
            len = len - saved
            short_path = short_path .. short_field
        else
            short_path = short_path .. field
        end

        pos = e + 1
    end

    return short_path
end

return M
