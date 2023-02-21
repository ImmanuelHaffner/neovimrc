local M = { }

function M.setup()

    ----- Bootstrap `packer` {{{----------------------------------------------------------------------------------------
    local install_path = vim.fn.stdpath('data') .. '/site/pack/packer/start/packer.nvim'
    if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
      packer_bootstrap = vim.fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
      vim.cmd [[packadd packer.nvim]]
    end
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- Install/load plugins {{{--------------------------------------------------------------------------------------
    require('packer').startup(function()
        -- Packer can manage itself
        use 'wbthomason/packer.nvim'

        -- Plugins -----------------------------------------------------------------------------------------------------
        use {
            'lewis6991/gitsigns.nvim',
            -- tag = 'release' -- To use the latest release (do not use this if you run Neovim nightly or dev builds!)
        }
        use 'altercation/vim-colors-solarized'
        use 'ctrlpvim/ctrlp.vim'
        use 'euclidianAce/BetterLua.vim'
        use 'gpanders/vim-medieval'
        use 'lervag/vimtex'
        use 'ludovicchabant/vim-gutentags'
        use 'mhinz/vim-grepper'
        use 'mhinz/vim-signify'
        use 'nvim-lua/plenary.nvim'
        use 'overcache/NeoSolarized'
        use 'pedrohdz/vim-yaml-folds'
        use 'powerman/vim-plugin-viewdoc'
        use 'rhysd/vim-grammarous'
        use 'scrooloose/nerdcommenter'
        use 'skywind3000/asyncrun.vim'
        use 'sukima/xmledit'
        -- use 'tpope/vim-fugitive'
        use 'vim-pandoc/vim-pandoc-syntax'
        use 'vim-scripts/DoxygenToolkit.vim'
        use 'Yggdroot/indentLine'
        use {
            'kyazdani42/nvim-tree.lua',
            tag = 'nightly',
            requires = {
                'kyazdani42/nvim-web-devicons', opt = true -- optional, for file icons
            },
            config = function() require'nvim-tree'.setup() end,
        }
        use {
            'glepnir/galaxyline.nvim',
            branch = 'main',
            -- some optional icons
            requires = { 'kyazdani42/nvim-web-devicons', opt = true }
        }
        use { 'akinsho/bufferline.nvim', tag = 'v2.*', requires = { 'kyazdani42/nvim-web-devicons', opt = true } }
        use { 'dccsillag/magma-nvim', run = ':UpdateRemotePlugins' }
        use { 'euclio/vim-markdown-composer', run = { 'cargo build --release', ':UpdateRemotePlugins' } }
        use { 'Shatur/neovim-session-manager', requires = { 'nvim-lua/plenary.nvim' } }
        use {
            'folke/which-key.nvim',
            config = function() require('which-key').setup() end
        }
        use { 'ray-x/lsp_signature.nvim' }
        use { 'petertriho/cmp-git', requires = 'nvim-lua/plenary.nvim' }
        use {
            'hrsh7th/nvim-cmp',
            requires = {
                'hrsh7th/cmp-nvim-lsp',
                'hrsh7th/cmp-buffer',
                'hrsh7th/cmp-path',
                'hrsh7th/cmp-cmdline',
            }
        }
        -- use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }

        use {
            "folke/todo-comments.nvim",
            requires = "nvim-lua/plenary.nvim",
            config = function()
                require("todo-comments").setup {
                    -- your configuration comes here
                    -- or leave it empty to use the default settings
                    -- refer to the configuration section below
                }
            end
        }

        -- Telescope {{{------------------------------------------------------------------------------------------------
        use {
            'nvim-telescope/telescope.nvim', tag = '0.1.0',
            requires = { 'nvim-lua/plenary.nvim' },
        }
        use {
            'nvim-telescope/telescope-fzf-native.nvim',
            requires = { 'nvim-telescope/telescope.nvim' },
            run = 'make'
        }
        use {'nvim-telescope/telescope-ui-select.nvim' }
        --}}}-----------------------------------------------------------------------------------------------------------

        -- LanguageServerProtocol (LSP) plugins {{{---------------------------------------------------------------------
        -- use {
        --     'williamboman/nvim-lsp-installer',
        --     config = function()
        --         require('nvim-lsp-installer').setup({automatic_installation = true})
        --     end
        -- }

        use {
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "neovim/nvim-lspconfig",
        }
        use {
            'p00f/clangd_extensions.nvim',
            requires = { 'neovim/nvim-lspconfig' },
        }
        use {
            'https://git.sr.ht/~whynothugo/lsp_lines.nvim',
            requires = { 'neovim/nvim-lspconfig' },
            config = function()
                require('lsp_lines').setup()
            end
        }
        --}}}-----------------------------------------------------------------------------------------------------------

        -- Disabled plugins {{{-----------------------------------------------------------------------------------------
        -- use 'lervag/vimtex'
        -- use 'lifepillar/pgsql.vim'
        -- use 'mh21/errormarker.vim'
        -- use 'neovimhaskell/haskell-vim'
        -- use 'scrooloose/nerdtree'
        -- use 'Shougo/deoplete-clangx'
        -- use 'Shougo/deoplete.nvim', { 'do': ':UpdateRemotePlugins' }
        -- use 'Shougo/echodoc.vim'
        -- use 'sudar/vim-arduino-syntax'
        -- use 'vim-airline/vim-airline'
        -- use 'vim-airline/vim-airline-themes'
        -- use 'vim-scripts/taglist.vim'
        -- use 'zchee/deoplete-jedi'
        -- use { 'beauwilliams/statusline.lua', requires = { 'mhinz/vim-signify' } }
        -- use { 'rafcamlet/tabline-framework.nvim',  requires = 'kyazdani42/nvim-web-devicons' }
        --}}}-----------------------------------------------------------------------------------------------------------

        -- Automatically set up your configuration after cloning packer.nvim.  Put this at the end after all plugins.
        if packer_bootstrap then
            require('packer').sync()
        end
    end)
    ---}}}--------------------------------------------------------------------------------------------------------------

end

return M
