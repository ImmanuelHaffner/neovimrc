return {
    { 'hedyhli/outline.nvim',
        -- Lazy-load: only needed when toggled; avoids BufEnter overhead.
        cmd = { 'Outline', 'OutlineOpen', 'OutlineClose' },
        keys = {
            { '<leader>lo', '<cmd>Outline<CR>', desc = 'Toggle outline' },
        },
        config = function()
            local function compute_width()
                -- 25% of screen width, clamped to [30, 80] columns.
                return require'nvu.layout'.adaptive_extent{
                    frac = 0.25, extent = vim.o.columns, min = 30, max = 80,
                }
            end

            local outline = require'outline'
            outline.setup{
                outline_window = {
                    position = 'left',
                    width = compute_width(),
                    relative_width = false,
                },
            }

            local timer = vim.uv.new_timer()
            vim.api.nvim_create_autocmd('VimResized', {
                group = vim.api.nvim_create_augroup('OutlineResize', { clear = true }),
                callback = function()
                    timer:stop()
                    timer:start(150, 0, vim.schedule_wrap(function()
                        local w = compute_width()
                        -- Update internal config so future opens use the new width
                        require('outline.config').o.outline_window.width = w
                        -- Resize live window if open
                        local sidebar = outline._get_sidebar(false)
                        if sidebar and sidebar.view:is_open() then
                            vim.api.nvim_win_set_width(sidebar.view.win, w)
                        end
                    end))
                end,
            })
        end,
    },
}
