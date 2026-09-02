return {
    {
        'zbirenbaum/copilot.lua',
        enabled = false,
        cmd = 'Copilot',
        event = 'InsertEnter',
        config = function()
            require'copilot'.setup{}
        end,
    },
    {
        'CopilotC-Nvim/CopilotChat.nvim',
        enabled = false,
        dependencies = {
            { 'zbirenbaum/copilot.lua' },
            { 'nvim-lua/plenary.nvim' }, -- for curl, log and async functions
        },
        build = 'make tiktoken', -- Only on MacOS or Linux
        opts = {
            model = 'claude-sonnet-4',
        },
    },
}
