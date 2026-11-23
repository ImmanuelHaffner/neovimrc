return {
    {
        'ImmanuelHaffner/pigmentor.nvim',
        branch = 'dev',
        dev = true,
        dependencies = {
            'folke/which-key.nvim',
        },
        config = function()
            local display_styles = {
                {
                    -- '#00AAFF'
                    style = 'inline',
                    inline = {
                        text_pre = '',
                        text_post = '',
                    },
                },
                {
                    -- '♦#00AAFF'
                    style = 'inline',
                    inline = {
                        text_pre = '♦',
                        text_post = '',
                    },
                },
                {
                    -- '#00AAFF' with fg text color
                    style = 'highlight',
                    highlight = {
                        padding = { left = 0, right = 0 },
                        inverted = false,
                    },
                },
                {
                    -- '#00AAFF' with bg color
                    style = 'highlight',
                    highlight = {
                        padding = { left = 1, right = 1 },
                        inverted = true,
                    },
                },
                {
                    -- '#00AAFF' with bg color
                    style = 'hybrid',
                    inline = {
                        text_pre = { '', '' },
                        text_post = { '', '', '' },
                    },
                    highlight = {
                        inverted = true,
                        padding = { left = 1, right = 1 },
                    },
                },
            }
            local current_display_style = 1

            local pm = require'pigmentor'
            pm.setup{
                display = display_styles[current_display_style],
                -- Highlight only where color literals are part of the content; everything else opts in per buffer or window.
                default = false,
                filetypes = {
                    tex = true, plaintex = true, context = true,
                    css = true, scss = true, sass = true, less = true, stylus = true,
                    html = true, svg = true, xresources = true,
                },
            }

            local function report(scope)
                return function(active)
                    vim.notify(('Pigmentor %s %s'):format(active and 'enabled' or 'disabled', scope))
                end
            end
            local report_global, report_buf, report_win = report'globally', report'for buffer', report'for window'

            local wk = require'which-key'
            wk.add({
                { '<leader>p', group = 'Pigmentor…' },
                { '<leader>pt', function() report_global(pm.toggle()) end, desc = 'Toggle globally' },
                { '<leader>pb', function() report_buf(pm.toggle_buf()) end, desc = 'Toggle for buffer' },
                { '<leader>pw', function() report_win(pm.toggle_win()) end, desc = 'Toggle for window' },
                { '<leader>pr', function()
                    pm.reset_win()
                    report_buf(pm.reset_buf())
                end, desc = 'Reset buffer and window to defaults' },
                { '<leader>pc', function()
                    if current_display_style >= #display_styles then
                        current_display_style = 1
                    else
                        current_display_style = current_display_style + 1
                    end
                    pm.update_config{display = display_styles[current_display_style]}
                    pm.refresh_visible_buffers()
                end, desc = 'Cycle display style' },
            })
        end,
    },
}
