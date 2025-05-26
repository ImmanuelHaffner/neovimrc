local M = { }

function M.setup()

    vim.api.nvim_create_user_command('BufDeleteWindowless', function ()
        local bufinfos = vim.fn.getbufinfo({buflisted = true})
        local count = 0
        vim.tbl_map(function (bufinfo)
            if bufinfo.changed == 0 and (not bufinfo.windows or #bufinfo.windows == 0) then
                -- print(('Deleting buffer %d : %s'):format(bufinfo.bufnr, bufinfo.name))
                vim.api.nvim_buf_delete(bufinfo.bufnr, {force = false, unload = false})
                count = count + 1
            end
        end, bufinfos)
        if count ~= 0 then
            vim.print(('Deleted %d buffer%s'):format(count, count ~= 1 and 's' or ''))
        end
    end, { desc = 'Delete all buffers not shown in a window'})

end

return M
