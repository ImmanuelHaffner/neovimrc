--- Show neo-tree and reveal current file.
--- @param toggle boolean whether to toggle the neo-tree
local function show_neo_tree(toggle)
    local reveal_file = vim.fn.expand'%:p'
    if reveal_file == '' then
        reveal_file = vim.fn.getcwd()
    else
        local f = io.open(reveal_file, 'r')
        if f then
            f.close(f)
        else
            reveal_file = vim.fn.getcwd()
        end
    end
    require'neo-tree.command'.execute{
        action = 'focus',          -- OPTIONAL, this is the default value
        toggle = toggle,
        source = 'filesystem',     -- OPTIONAL, this is the default value
        position = 'left',         -- OPTIONAL, this is the default value
        reveal_file = reveal_file, -- path to file or folder to reveal
        reveal_force_cwd = true,   -- change cwd without asking if needed
    }
end


return {
    {
        'nvim-neo-tree/neo-tree.nvim',
        branch = 'v3.x',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-tree/nvim-web-devicons', -- not strictly required, but recommended
            'MunifTanjim/nui.nvim',
            '3rd/image.nvim', -- Optional image support in preview window: See `# Preview Mode` for more information
        },
        lazy = false,
        config = function()
            local neotree = require'neo-tree'
            neotree.setup{
                window = {
                    mappings = {
                        ['<F2>'] = 'close_window',
                        ['<leader>p'] = 'image_wezterm',
                    },
                },
                commands = {
                    image_wezterm = function(state)
                        local node = state.tree:get_node()
                        if node.type == 'file' then
                            require'image_preview'.PreviewImage(node.path)
                        end
                    end,
                },
            }
        end,
        keys = {
            {
                '<F2>',
                function()
                    -- local reveal_file = vim.fn.expand'%:p'
                    -- if reveal_file == '' then
                    --     reveal_file = vim.fn.getcwd()
                    -- else
                    --     local f = io.open(reveal_file, 'r')
                    --     if f then
                    --         f.close(f)
                    --     else
                    --         reveal_file = vim.fn.getcwd()
                    --     end
                    -- end
                    -- require'neo-tree.command'.execute{
                    --     action = 'focus',          -- OPTIONAL, this is the default value
                    --     toggle = true,
                    --     source = 'filesystem',     -- OPTIONAL, this is the default value
                    --     position = 'left',         -- OPTIONAL, this is the default value
                    --     reveal_file = reveal_file, -- path to file or folder to reveal
                    --     reveal_force_cwd = true,   -- change cwd without asking if needed
                    -- }
                    show_neo_tree(true)
                end,
                desc = 'Toggle Neo-tree (filesystem)'
            },
            {
                '<S-F2>',
                function()
                    show_neo_tree(false)
                end,
                desc = 'Open Neo-tree (filesystem)'
            },
        }
    },
    {
        'kyazdani42/nvim-tree.lua',
        enabled = false,
        tag = 'nightly',
        dependencies = {
            'folke/which-key.nvim',
            'nvim-tree/nvim-web-devicons',
        },
        config = function()
            require'nvim-tree'.setup{
                view = { width = 40 },
            }
        end,
        keys = {
            { '<F2>', '<cmd>NvimTreeToggle<cr>', desc = 'Toggle NvimTree' },
        }
    }
}
