-- `project.databricks`: pairing worktrees of different repositories.

local H = require 'tests.helpers'
local eq = MiniTest.expect.equality

local dir, universe, runtime, databricks

local T = MiniTest.new_set{ hooks = {
    pre_case = function()
        dir = vim.fn.tempname()
        universe, runtime = dir .. '/worktrees/universe', dir .. '/worktrees/runtime'
        vim.fn.mkdir(universe .. '/x', 'p')
        vim.fn.mkdir(universe .. '/only', 'p')
        vim.fn.mkdir(runtime .. '/x', 'p')
        databricks = H.fresh 'project.databricks'
        databricks.config.worktree_families = { universe, runtime }
        databricks.config.canonical_checkouts = { dir .. '/universe', dir .. '/runtime' }
    end,
    post_case = function() vim.fn.delete(dir, 'rf') end,
} }

T['a worktree pairs with its namesake in the other family'] = function()
    eq(databricks.companions_of(universe .. '/x'), { runtime .. '/x' })
    eq(databricks.companions_of(runtime .. '/x/'), { universe .. '/x' })
end

T['a worktree without a namesake has none'] = function()
    eq(databricks.companions_of(universe .. '/only'), {})
end

T['canonical checkouts and unrelated roots have none'] = function()
    vim.fn.mkdir(dir .. '/universe', 'p')
    eq(databricks.companions_of(dir .. '/universe'), {})
    eq(databricks.companions_of(dir .. '/elsewhere/x'), {})
    eq(databricks.companions_of(universe .. '/x/sub'), {})
end

return T
