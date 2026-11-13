return {
    {
        'ImmanuelHaffner/mcphub.nvim',
        branch = 'dev',
        dev = true,
        dependencies = {
            'nvim-lua/plenary.nvim',  -- Required for Job and HTTP requests
            'Joakker/lua-json5',
        },
        -- uncomment the following line to load hub lazily
        --cmd = 'MCPHub',  -- lazy load
        build = "cd ~/.local && npm install mcp-hub@latest",
        config = function()
            local Utils = require'utils'
            local project_mcp = require'project.mcp'
            local port = 27373
            -- Hold edit reviews back until I am in Normal mode in the chat that asked for them, so a review
            -- never takes the cursor while I am typing a prompt or working elsewhere. `edit_file.ui` also
            -- governs `write_file`.
            local defer = { allow_in_modes = { 'n' }, chat = 'focused' }
            if Utils.is_ssh_connection() or Utils.is_client_server_connection() then
                port = port + 1
            end
            -- Isolated test hubs: a probe Neovim with these set gets a hub of its own, which neither reads
            -- nor writes the files the real hub watches.  Pair with `MCPHUB_PROJECT_OVERLAY` (`project.mcp`).
            port = tonumber(vim.env.MCPHUB_PORT) or port

            require("mcphub").setup({
                -- Pin an explicit port below the Linux ephemeral range (32768+) so the Arca SSH companion — which
                -- mirrors arbitrary remote devbox ports onto localhost — can never collide with the local hub.
                -- mcp-hub's default
                -- 37373 sits inside that ephemeral band and clashed with a remote mcp-hub forwarded by Arca, causing
                -- the hub to serve `/home/...` config paths (remote $HOME) and E739 on macOS autofs `/home`.
                port = port,
                config = vim.env.MCPHUB_CONFIG,
                -- Workspace hubs are OFF.  A workspace hub re-spawns every enabled global server, so each
                -- enrolled project added its own duplicate `fff_universe` / `fff_runtime` — three universe
                -- indexes at ~3.2 GiB each were once live at once, and 178 GiB resident was observed.
                -- Project-scoped servers now come from `.project.lua` via `lua/project/mcp.lua` instead,
                -- which yields exactly one hub, one static index per read-only checkout, and one process
                -- per project.  This also retires the `look_for` pin that stopped MCPHub's upward marker
                -- search (which never stopped at $HOME) from resolving every cwd under $HOME to a
                -- $HOME-rooted hub that merged Cursor's ~17 duplicate Databricks servers over ours.
                workspace = { enabled = false },
                -- Project-scoped servers live in their own file, which `make install` never touches: it
                -- replaces the global `servers.json` wholesale, and the hub used to drop every project server
                -- with it.  Only `lua/project/mcp.lua` writes this file; the hub reads and watches it.
                -- `ephemeral`: whichever Neovim spawns a hub disables every entry first, so a fresh hub starts
                -- none of them and each Neovim re-enables its own from `on_ready`.
                config_overlays = { { path = project_mcp.config.overlay, ephemeral = true } },
                on_ready = function() project_mcp.on_hub_ready() end,
                builtin_tools = {
                    apply_edit = { ui = { defer = defer } },
                    edit_file = { ui = { defer = defer } },
                    view_image = { enabled = true },
                    execute_command = { memory_limit = 32 * 1024 ^ 3 },  -- 32 GiB
                },
            })

            -- Once per session, as soon as the overlay is loaded, drop entries whose project is gone.  And on
            -- every update adopt project servers other Neovims started, so `max_active` holds hub-wide.
            local swept = false
            require('mcphub').on('servers_updated', function()
                pcall(project_mcp.observe)
                if swept then return end
                local ok, ran = pcall(project_mcp.sweep)
                swept = ok and ran
            end)
        end
    },
}
