return {
    {
        -- TODO: Switch back to 'ravitemer/mcphub.nvim' once PR #279 is merged:
        --       https://github.com/ravitemer/mcphub.nvim/pull/279
        --       This fork adds CodeCompanion v19 compatibility (tool cmd signature,
        --       variables→editor_context rename, output handler changes, image API).
        --       Upstream looks dormant (last commit 2026-01-18); alternative PR #287
        --       was closed unmerged on 2026-06-01. Don't expect quick resolution.
        'ImmanuelHaffner/mcphub.nvim',
        branch = 'dev',
        dependencies = {
            'nvim-lua/plenary.nvim',  -- Required for Job and HTTP requests
            'Joakker/lua-json5',
        },
        -- uncomment the following line to load hub lazily
        --cmd = 'MCPHub',  -- lazy load
        build = "cd ~/.local && npm install mcp-hub@latest",
        config = function()
            local Utils = require'utils'
            local port = 27373
            if Utils.is_ssh_connection() or Utils.is_client_server_connection() then
                port = port + 1
            end

            require("mcphub").setup({
                -- Pin an explicit port below the Linux ephemeral range (32768+) so the Arca SSH companion — which
                -- mirrors arbitrary remote devbox ports onto localhost — can never collide with the local hub.
                -- mcp-hub's default
                -- 37373 sits inside that ephemeral band and clashed with a remote mcp-hub forwarded by Arca, causing
                -- the hub to serve `/home/...` config paths (remote $HOME) and E739 on macOS autofs `/home`.
                port = port,
                -- Workspace hubs are OFF.  A workspace hub re-spawns every enabled global server, so each
                -- enrolled project added its own duplicate `fff_universe` / `fff_runtime` — three universe
                -- indexes at ~3.2 GiB each were once live at once, and 178 GiB resident was observed.
                -- Project-scoped servers now come from `.project.lua` via `lua/project/mcp.lua` instead,
                -- which yields exactly one hub, one static index per read-only checkout, and one process
                -- per project.  This also retires the `look_for` pin that stopped MCPHub's upward marker
                -- search (which never stopped at $HOME) from resolving every cwd under $HOME to a
                -- $HOME-rooted hub that merged Cursor's ~17 duplicate Databricks servers over ours.
                workspace = { enabled = false },
            })
        end
    },
}
