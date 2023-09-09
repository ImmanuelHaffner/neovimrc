return {
    { 'skywind3000/asyncrun.vim',
        dependencies = { 'folke/which-key.nvim' },
        config = function()
            vim.g.asyncrun_exit = 'silent lua require\'galaxyline\'.load_galaxyline()'
            local wk = require'which-key'
            wk.register({
                ['<F5>'] = { '<cmd>AsyncRun -program=make<cr>', 'Make' },
            }, { silent = true })
        end,
    },
}
