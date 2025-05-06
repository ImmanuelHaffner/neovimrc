-- vim: set foldmethod=marker:

-- Workaround `unpack` deprecation
if not table.unpack then
    table.unpack = unpack
end

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- Load our global config
require'config'.setup()

-- Load our utilities
Utils = require'utils'

-- Build plugin table
local plugins = require('plugins')

-- Load lazy.nvim
local lazyopts = {
    defaults = {
        lazy = false,
    },
}
require("lazy").setup(plugins, lazyopts)

-- Load our keymap
require'keymap'.setup()

-- Load our functions
require'functions'.setup()

-- Install our autocmds
require'autocmd'.setup()

-- UI settings
vim.api.nvim_create_autocmd('UIEnter', {
    callback = function()
        if vim.g.neovide then
            require'neovide'.setup()
        end
    end
})

-- Support for project-specific config {{{------------------------------------------------------------------------------
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
---}}}------------------------------------------------------------------------------------------------------------------
