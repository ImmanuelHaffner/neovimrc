return {
    { 'akinsho/toggleterm.nvim',
        version = "*",
        dependencies = {
            'folke/which-key.nvim',
        },
        opts = {--[[ things you want to change go here]]},
        config = function()
            local term = require'toggleterm'
            term.setup{
                open_mapping = [[<c-\>]],
                shade_terminals = false,
            }

            local Terminal  = require'toggleterm.terminal'.Terminal

            local wk = require'which-key'

            local lazygit = Terminal:new({
                cmd = "lazygit",
                dir = "git_dir",
                direction = "tab",
                -- function to run on opening the terminal
                on_open = function(term)
                    vim.cmd("startinsert!")
                    vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", {noremap = true, silent = true})
                end,
                -- function to run on closing the terminal
                on_close = function(term)
                    vim.cmd("startinsert!")
                end,
            })

            function _lazygit_toggle()
                lazygit:toggle()
            end

            wk.register({
                l = { function() lazygit:toggle() end, "Lazygit" }
            }, { prefix = '<leader>g', silent = true })
        end
    },
    { 'tknightz/telescope-termfinder.nvim',
        dependencies = {
            'akinsho/toggleterm.nvim',
            'nvim-telescope/telescope.nvim',
            'folke/which-key.nvim',
        },
        config = function()
            require'telescope'.load_extension'termfinder'

            require'which-key'.register({
                name = 'Telescope',
                ['\\'] = { ':Telescope termfinder find<cr>', 'Find terminal' },
            }, { prefix = '<leader>f', silent = true })
        end,
    },
}
