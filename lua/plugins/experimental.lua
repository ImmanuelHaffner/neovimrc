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
        -- Passed to require'factory'.setup; a task keeps what it was started with, so edits apply to new tasks only.
        opts = {
            -- Seconds between checks of a finished review's PR for merges and answers; false turns them off.
            follow = { interval = 600 },
            workspaces = {
                reviews = '~/Documents/databricks/pr-reviews',
            },
            worktrees = {
                universe = { reviews = '~/worktrees/universe/pr-reviews' },
                runtime = { reviews = '~/worktrees/runtime/pr-reviews' },
            },
            tasks = {
                -- `on`: steps whose agents run on an arclet of the task's own.  Only the panel and the judge right
                -- after it gain from one: the drafter and the verifier are single short agents, and an arclet that
                -- stopped while the task waited for me has to fetch the PR again first.
                review = { jobs = 8, isaac = true, on = { agents = 'arclet', synthesis = 'arclet' } },
            },
        },
    },
}
