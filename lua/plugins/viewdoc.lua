return {
    { 'powerman/vim-plugin-viewdoc',
        config = function()
            vim.g.viewdoc_openempty = false

            -- If set to 1, the word which is looked up is also copied into the Vims search register which allows to
            -- easily search in the documentation for occurrences of this word.
            vim.g.viewdoc_copy_to_search_reg = true
        end,
    },
}
