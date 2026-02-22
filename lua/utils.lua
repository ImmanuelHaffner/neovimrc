-- Re-export nvu modules for convenience
local nvu = require'nvu'

local M = {
    -- Core utilities
    toggle = nvu.core.toggle,
    select = nvu.core.select,

    -- String utilities
    starts_with = nvu.string.starts_with,
    ends_with = nvu.string.ends_with,
    trim = nvu.string.trim,
    split_str = nvu.string.split,

    -- Path utilities
    basename = nvu.path.basename,
    shorten_path = nvu.path.shorten,
    shorten_absolute_path = nvu.path.shorten_absolute,
    shorten_relative_path = nvu.path.shorten_relative,

    -- Buffer utilities
    is_buffer_empty = nvu.buffer.is_empty,
    has_width_gt = nvu.buffer.has_width_gt,
    get_visual_selection = nvu.buffer.get_visual_selection,
    search_for_visual_selection = nvu.buffer.search_visual_selection,
    any_visible_buffer = nvu.buffer.any_visible,
    toggle_quickfix = nvu.buffer.toggle_quickfix,

    -- Environment utilities
    is_local_nvim = nvu.env.is_local,
    is_ssh_connection = nvu.env.is_ssh,
    is_client_server_connection = nvu.env.is_client_server,
    is_headless_server = nvu.env.is_headless,
    has_tree_sitter_cli = nvu.env.has_treesitter_cli,

    -- Highlight utilities
    get_highlight_group = nvu.highlight.get,
}

local colors = require'theme'.colors()

--- Get the current Vim mode information (color and name).
--- @return table { color, mode_name }
function M.get_vim_mode_info()
    local vim_modes = {
        ['n']   = { colors.green,       'NORMAL' },
        ['i']   = { colors.blue,        'INSERT' },
        ['c']   = { colors.red2,        'COMMAND' },
        ['t']   = { colors.yellow,      'TERMINAL' },
        ['v']   = { colors.purple3,     'VISUAL' },
        ['']  = { colors.purple3,     'V-BLOCK' },
        ['V']   = { colors.purple3,     'V-LINE' },
        ['R']   = { colors.light_red,   'REPLACE' },
        ['s']   = { colors.light_red,   'SELECT' },
        ['S']   = { colors.light_red,   'S-LINE' },
        ['']  = { colors.light_red,   'S-BLOCK' },
        ['r']   = { colors.cyan4,       'PROMPT' },
        ['!']   = { colors.dark_red,    'SHELL' },
    }

    local mode = vim.fn.mode(1) or ''

    -- Check for OPERATOR PENDING mode.
    if mode:sub(1, 2) == 'no' then
        return { colors.orange, 'OPERATOR' }
    end

    local chr = mode:sub(1, 1) or 0
    local current_mode = vim_modes[chr]
    return current_mode or { colors.dark_red, 'UNKNOWN ' .. mode }
end

--- Load project-specific configuration from `.project.lua` or `.project.vim`.
function M.load_project_config()
    if vim.fn.filereadable('.project.lua') == 1 then
        vim.cmd[[luafile .project.lua]]
    elseif vim.fn.filereadable('.project.vim') == 1 then
        vim.cmd[[source .project.vim]]
    end
end

return M
