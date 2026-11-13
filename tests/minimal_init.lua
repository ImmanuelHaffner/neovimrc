-- Headless init for `make test`.
--
-- `-u` keeps `~/.config/nvim` at the front of 'runtimepath', so without the prepend below `require` would
-- load the *deployed* copy of this configuration instead of the working tree under test.

local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
vim.opt.rtp:prepend(root)

-- Plugins come from lazy's directory, so the mcphub fork is tested as its working copy.
local lazy = vim.fn.stdpath('data') .. '/lazy'
for _, plugin in ipairs{ 'plenary.nvim', 'mcphub.nvim' } do
    vim.opt.rtp:append(lazy .. '/' .. plugin)
end

vim.opt.rtp:append(root .. '/deps/mini.nvim')
require('mini.test').setup()
