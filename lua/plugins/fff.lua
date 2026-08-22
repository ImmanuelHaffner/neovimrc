return {
    {
        -- Upstream renamed the repo from `fff.nvim` to `fff`; the Lua module is still `fff`.
        'dmtrKovalenko/fff',
        build = function(plugin)
            -- Downloads the picker binary the Lua plugin loads (or `cargo build`).
            require'fff.download'.download_or_build_binary()
            -- Also install the standalone `fff-mcp` server binary consumed by
            -- MCPHub (registered in servers.json). The installer resolves the latest
            -- stable *release* of fff-mcp, so its version is independent of the plugin
            -- revision in lazy-lock.json and the two can drift apart.
            local installer = plugin.dir .. '/install-mcp.sh'
            if vim.uv.fs_stat(installer) then
                local out = vim.system({ 'bash', installer }, { text = true }):wait()
                if out.code ~= 0 then
                    vim.notify('fff-mcp install failed:\n' .. (out.stderr or ''), vim.log.levels.WARN)
                end
            else
                vim.notify('fff-mcp installer not found at ' .. installer, vim.log.levels.WARN)
            end
        end,
        dependencies = { 'folke/which-key.nvim' },
        lazy = false,  -- the plugin lazy-initialises its index itself
        config = function()
            require'fff'.setup{
                -- Match adaptive_pickers' find_files prompt icon for a consistent look.
                prompt = '󰱼 ',
                title = 'FFFiles',
                max_results = 100,
                layout = {
                    -- Same 0.8 fractions our nvu.layout adaptive extents default to.
                    height = 0.8,
                    width = 0.8,
                    prompt_position = 'bottom',
                    preview_position = 'right',
                    preview_size = 0.5,
                    -- Follow the global window border so fff matches our other floats.
                    border = nil,
                    -- Mirror nvu.telescope's path shortening philosophy.
                    path_shorten_strategy = 'middle',
                },
                git = { status_text_color = true },
                -- Blend the picker with the theme the way our other floats do.
                hl = { normal = 'NormalFloat' },
            }

            local fff = require'fff'
            local wk = require'which-key'
            wk.add{
                { '<leader>F', group = 'FFF (fast find)' },
                { '<leader>Ff', function() fff.find_files() end, desc = 'FFFind files' },
                { '<leader>Fl', function() fff.live_grep() end, desc = 'FFF live grep' },
                {
                    '<leader>Fz',
                    function() fff.live_grep{ grep = { modes = { 'fuzzy', 'plain' } } } end,
                    desc = 'FFF fuzzy grep',
                },
                { '<leader>Fs', function() fff.scan_files() end, desc = 'FFF rescan files' },
            }
            wk.add{
                mode = { 'n', 'x' },
                { '<leader>Fw', function() fff.live_grep_under_cursor() end, desc = 'FFF grep word/selection' },
            }
        end,
    },
}
