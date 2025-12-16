local Utils = require'utils'

return {
    {
        'mfussenegger/nvim-dap',
        config = function()
            -- Debug settings if you're using nvim-dap
            local dap = require'dap'

            dap.configurations.scala = {
                {
                    type = 'scala',
                    request = 'launch',
                    name = 'RunOrTest',
                    metals = {
                        runType = 'runOrTestFile',
                        --args = { 'firstArg', 'secondArg', 'thirdArg' }, -- here just as an example
                    },
                },
                {
                    type = 'scala',
                    request = 'launch',
                    name = 'Test Target',
                    metals = {
                        runType = 'testTarget',
                    },
                },
            }
        end,
    },
    {
        'nvim-telescope/telescope-dap.nvim',
        dependencies = {
            'folke/which-key.nvim',
            'mfussenegger/nvim-dap',
        },
        config = function()
            local telescope = require'telescope'
            telescope.load_extension'dap'

            local wk = require'which-key'
            wk.add{
                { '<leader>d', group = 'DAP…' },
                { '<leader>dc', function() require'telescope'.extensions.dap.commands() end, desc = 'DAP Commands' },
                { '<leader>db', function() require'telescope'.extensions.dap.list_breakp() endoints() end, desc = 'DAP Breakpoints' },
                { '<leader>dv', function() require'telescope'.extensions.dap.variables() end, desc = 'DAP Variables' },
                { '<leader>df', function() require'telescope'.extensions.dap.frames() end, desc = 'DAP Frames' },
            }
        end,
    },
    {
        'igorlfs/nvim-dap-view',
        ---@module 'dap-view'
        ---@type dapview.Config
        opts = {},
        keys = {
            { '<leader>do', '<cmd>DapViewOpen<CR>', desc = 'Open DAP view' },
        },
    },
    {
        'LiadOz/nvim-dap-repl-highlights',
        dependencies = {
            'mfussenegger/nvim-dap',
        },
        config = function()
            require'nvim-dap-repl-highlights'.setup()
            if Utils.has_tree_sitter_cli() then
                local parsers = require'nvim-treesitter.parsers'
                if not parsers.has_parser('dap_repl') then
                    vim.cmd[[TSInstall dap_repl]]
                end
            end
        end,
    },
}
