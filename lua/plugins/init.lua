local path = vim.api.nvim_get_runtime_file('lua/plugins', false)
if path[1] == nil then
    vim.print('Failed to locate plugin directory.')
    return { }
end

local plugins = { }

for _, file in ipairs(vim.fn.readdir(path[1], [[v:val =~ '\.lua$']])) do
    if file ~= 'init.lua' then
        local module = file:gsub('%.lua$', '')
        local ok, table = pcall(require, 'plugins.' .. module)
        if ok then
            vim.list_extend(plugins, table)
        else
            vim.print('Failed to load module \'' .. vim.inspect(module) .. '\'')
        end
    end
end

return plugins
