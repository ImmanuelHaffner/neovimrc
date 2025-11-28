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
}
