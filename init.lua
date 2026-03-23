-- vim: set foldmethod=marker:

-- Workaround `unpack` deprecation
if not table.unpack then
    ---@diagnostic disable-next-line: deprecated
    table.unpack = unpack
end

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = 'https://github.com/folke/lazy.nvim.git'
  local out = vim.fn.system({ 'git', 'clone', '--filter=blob:none', '--branch=stable', lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
      { '\nPress any key to exit...' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Load our global config
require'config'.setup()

-- Load lazy.nvim
require'lazy'.setup{
    defaults = {
        lazy = false,
    },
    dev = {
        path = vim.fn.stdpath('data') .. '/lazy',
        fallback = true,
    },
    spec = {
        import = 'plugins'
    },
    change_detection = {
        notify = false,
    },
}

-- Load our neovim utilities (after loading plugins)
local Utils = require'utils'

-- Configure LSPs
require'lsp'.setup()

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
local LoadProjectConfig = vim.api.nvim_create_augroup('LoadProjectConfig', { clear = false })
vim.api.nvim_create_autocmd('DirChanged', {
    group = LoadProjectConfig,
    pattern = 'global',
    callback = Utils.load_project_config,
})
Utils.load_project_config()
---}}}------------------------------------------------------------------------------------------------------------------
