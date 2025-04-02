return {
    { 'skywind3000/asyncrun.vim',
        config = function()
            vim.g.asyncrun_exit = [[silent lua require'galaxyline'.load_galaxyline()]]
        end,
        keys = {
            -- { '<F5>', '<cmd>AsyncRun -program=make<cr>', desc = 'Make' },
            { '<F5>', function()
                vim.api.nvim_call_function('asyncrun#run', { false, { program = 'make' }, '' })
            end, desc = 'Make' },
        },
    },
}
