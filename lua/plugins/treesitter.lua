return {
    { 'nvim-treesitter/nvim-treesitter',
        branch = 'main',  -- master branch is archived; main has tree-sitter CLI 0.25+ compat
        dependencies = {
            'OXY2DEV/markview.nvim',
        },
        lazy = false,
        build = ':TSUpdate',
        config = function()
            local Utils = require'utils'

            -- On the main branch, setup() only accepts { install_dir = ... }.
            -- Highlighting, indent, etc. are now handled by Neovim builtins (vim.treesitter.start).
            require'nvim-treesitter'.setup()

            -- Install parsers
            local ensure_installed = {
                'awk',
                'bash',
                'bibtex',
                'c',
                'cmake',
                'cpp',
                'diff',
                'dockerfile',
                'html',
                'htmldjango',
                'lua',
                'markdown',
                'markdown_inline',
                'nginx',
                'ninja',
                'python',
                'query',
                'regex',
                'requirements',
                'rust',
                'scala',
                'sql',
                'vim',
                'vimdoc',
                'xcompose',
                'xresources',
                'yaml',
                'zathurarc',
            }

            if Utils.has_tree_sitter_cli() then
                ensure_installed[#ensure_installed + 1] = 'latex'
            else
                vim.notify('Tree-sitter CLI is not available. Some grammars will not be installed.')
            end

            -- Install missing parsers asynchronously
            require'nvim-treesitter'.install(ensure_installed)
        end
    }
}
