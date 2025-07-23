return {
    { 'tamton-aquib/duck.nvim',
        dependencies = {
            'folke/which-key.nvim',
        },
        config = function()
            local duck = require'duck'
            local wk = require'which-key'
            local pets = { '🦆', 'ඞ', '🦀', '🐈', '🐎', '🦖', '🐤' }
            local pet_idx = 1
            local speed = 1
            local hatch = function()
                local pet = pets[pet_idx]
                pet_idx = pet_idx + 1
                duck.hatch(pet, speed)
            end
            wk.add{
                { '<leader>d', group = 'Duck' },
                { '<leader>dd', function() duck.hatch('🦆', speed) end, desc = 'Hatch duck' },
                { '<leader>dp', function() hatch() end, desc = 'Hatch a pet' },
                { '<leader>dc', function() duck.cook() end, desc = 'Cook duck' },
            }
        end
    }
}
