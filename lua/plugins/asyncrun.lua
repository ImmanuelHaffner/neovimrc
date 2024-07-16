return {
    { 'skywind3000/asyncrun.vim',
        config = function()
            vim.g.asyncrun_exit = 'silent lua require\'galaxyline\'.load_galaxyline()'
        end,
        keys = {
            { '<F5>', '<cmd>AsyncRun -program=make<cr>', desc = 'Make' },
        },
    },
}
