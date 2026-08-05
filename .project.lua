-- Neovim configuration repo.
--
-- Loaded by `require'project'` (this very repo's `lua/project.lua`).  Top-level code runs **once per
-- session**; `load` runs on every directory change into this project and must therefore be idempotent.

return {
    load = function(ctx)
        -- This repo folds by marker.
        vim.opt.foldmethod = 'marker'

        -- A project-scoped fff index.  This tree is small (~80 MiB resident), so it is cheap to keep.
        require'project.mcp'.fff{ root = ctx.root }
    end,
}
