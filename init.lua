-- vim: set foldmethod=marker:

require('lua/config').setup()           -- global configuration
require('lua/keymap').setup()           -- custom key bindings
require('lua/plugins').setup()          -- plugins
require('lua/plugins-conf').setup()     -- plugins configuration
require('lua/user_commands').setup()    -- user commands
require('lua/lsp').setup()              -- LSP server configurations

function load_project_config()
    if vim.fn.filereadable('.project.lua') == 1 then
        vim.cmd[[luafile .project.lua]]
    elseif vim.fn.filereadable('.project.vim') == 1 then
        vim.cmd[[source .project.vim]]
    end
end

local LoadProjectConfig = vim.api.nvim_create_augroup('LoadProjectConfig', {})
vim.api.nvim_create_autocmd('DirChanged', {
    group = LoadProjectConfig,
    pattern = 'global',
    callback = load_project_config,
})

load_project_config()
