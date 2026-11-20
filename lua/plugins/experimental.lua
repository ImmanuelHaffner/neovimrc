-- The AI factory (`:Factory`), which lives in my personal experiments repository and is loaded from its working
-- copy.  The repository is private, so this entry names only where the copy lives, and is enabled only on machines
-- that have it.
local dir = vim.fn.expand('~/experimental-immanuel-haffner/nvim')

return {
    {
        name = 'factory',
        dir = dir,
        enabled = vim.uv.fs_stat(dir) ~= nil,
        cmd = { 'Factory' },
    },
}
