--- Check whether a compatible ctags (Universal or Exuberant) is available.
local function has_compatible_ctags()
    local ctags = vim.fn.exepath('ctags')
    if ctags == '' then return false end
    local out = vim.fn.system({ ctags, '--version' })
    return vim.fn.match(out, [[\c\(Universal\|Exuberant\) Ctags]]) >= 0
end

return {
    {
        'ludovicchabant/vim-gutentags',
        enabled = false,
        cond = has_compatible_ctags,
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
