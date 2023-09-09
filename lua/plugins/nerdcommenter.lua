return {
    { 'scrooloose/nerdcommenter',
        dependencies = { 'folke/which-key.nvim' },
        config = function()
            vim.g.NERDCreateDefaultMappings = 0
            vim.g.NERDAllowAnyVisualDelims = 1
            vim.g.NERDSpaceDelims = 1
            vim.g.NERDCompactSexyComs = 1
            vim.g.NERDTrimTrailingWhitespace = 1
            vim.g.NERDDefaultAlign = 'left'

            local wk = require'which-key'
            wk.register({
                name = 'NERD Commenter',
                ['<C-c>'] = { '<cmd>call nerdcommenter#Comment(\'n\', \'toggle\')<cr>', 'Comment toggle line' },
            }, { silent = true, mode = 'n' })
            wk.register({
                name = 'NERD Commenter',
                ['<C-c>'] = { ':call nerdcommenter#Comment(\'x\', \'toggle\')<cr>', 'Comment toggle selection' },
            }, { silent = true, mode = 'v' })
        end,
    },
}
