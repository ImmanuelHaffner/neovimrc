return {
    { 'hedyhli/outline.nvim',
        -- Lazy-load: only needed when toggled; avoids BufEnter overhead.
        cmd = { 'Outline', 'OutlineOpen', 'OutlineClose' },
        keys = {
            { '<leader>lo', '<cmd>Outline<CR>', desc = 'Toggle outline' },
        },
        config = function()
            local pct = 0.25   -- target: 20% of screen width
            local min_w = 30   -- absolute minimum columns
            local max_w = 80   -- absolute maximum columns

            local function compute_width()
                return math.max(min_w, math.min(max_w, math.floor(vim.o.columns * pct)))
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
