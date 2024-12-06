return {
    { 'akinsho/toggleterm.nvim',
        version = "*",
        dependencies = {
            'folke/which-key.nvim',
        },
        config = function()
            local term = require'toggleterm'
            term.setup{
                open_mapping = [[<c-\>]],
                shade_terminals = false,
                autochdir = true,
                auto_scroll = false,
            }

            local Terminal = require'toggleterm.terminal'.Terminal
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

            local wk = require'which-key'
            wk.add{
                { '<leader>gl', function() lazygit:toggle() end, desc = 'Lazygit' },
                { '<leader>ft', '<cmd>TermSelect<cr>', desc = 'Select toggle term' },
            }
        end,
    },
}
