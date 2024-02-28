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
            },
            build = {
                jobs = 14,
                targets = {
                    'clickhouse',
                    'sql_test',
                    'planner_tests',
                    'planner_unit_tests',
                    'sql_parser_tests',
                },
                notify = true,
            },
            git_clang_format = 'git-clang-format --binary /opt/clang-format-static/clang-format-14 --force --',
        },
    },
}
