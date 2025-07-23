--- Get the preferred number of jobs to use for building and testing as 90% of the number of CPU cores.
local nproc = function()
    local result = vim.fn.system('nproc')
    local n = tonumber(result)
    if n ~= nil then
        return math.floor(n * 0.9)
    end
    return 8
end

return {
    { 'git@github.com:firebolt-analytics/firebolt.nvim.git',
        dependencies = {
            'skywind3000/asyncrun.vim',
            'folke/which-key.nvim',
            'rcarriga/nvim-notify',  -- optional
        },
        branch = 'experimental',
        opts = {
            dirs = {
                '/home/immanuel/Documents/Firebolt/code/packdb',
                '/home/immanuel/Documents/Firebolt/code/packdb-2',
                '/home/immanuel/code/packdb',
            },
            build = {
                jobs = nproc(),
                targets = {
                    'clickhouse',
                    'sql_test',
                    'planner_tests',
                    'sql_parser_tests',
                    'packdb_tests',
                },
                -- icecc = {
                --     path = '/home/immanuel/Documents/Firebolt/code/packdb/icecc_prefix.sh',
                --     jobs = 200,
                -- },
                notify = true,
            },
            test = {
                fix_test_keep_actual = false,
                fix_test_confirm = false,
            },
            clang_format = '/usr/lib/llvm18/bin/clang-format -i --',
        },
    },
}
