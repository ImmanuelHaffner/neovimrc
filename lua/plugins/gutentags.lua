return {
    { 'ludovicchabant/vim-gutentags',
        config = function()
            vim.g.gutentags_cache_dir = os.getenv('HOME') .. '/.cache/nvim/tags'
            vim.g.gutentags_generate_on_new = true
            vim.g.gutentags_generate_on_missing = true
            vim.g.gutentags_generate_on_write = true
            vim.g.gutentags_generate_on_empty_buffer = false
            vim.g.gutentags_ctags_extra_args = {
                '--tag-relative=yes',
                '--fields=+ailmnS',
            }
            vim.g.gutentags_file_list_command = {
                ['markers'] = {
                    ['.git'] = 'git ls-files',
                    ['.hg']  = 'hg files',
                }
            }
        end,
    },
}
