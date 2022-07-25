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

return M
