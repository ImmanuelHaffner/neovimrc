-- Work tools that live in my personal experiments repository, loaded from its working copy.  The repository is
-- private, so this entry names only where the copy lives, and is enabled only on machines that have it.
local dir = vim.fn.expand('~/experimental-immanuel-haffner/nvim')

return {
    {
        name = 'experimental-review',
        dir = dir,
        enabled = vim.uv.fs_stat(dir) ~= nil,
        cmd = { 'PrFanout', 'PrFanoutLoad' },
    },
}
