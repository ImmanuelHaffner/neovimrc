return {
    {
        -- Fork adding `:Pesto -C <dir>`, `require'pesto'.run{}` and `User PestoBuild*` events.
        'ImmanuelHaffner/pesto.nvim',
        branch = 'dev',
        dev = true,
        ---@type pesto.Config
        opts = {},
        -- Pesto is lazy by default (see :h lua-plugin-lazy)
        lazy = false,
    }
}
