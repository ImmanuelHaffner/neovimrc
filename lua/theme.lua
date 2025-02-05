local M = { }

-- some useful color definitions
M._colors = {
    bg = '#282c34',
    fg = '#aab2bf',
    section_bg = '#38393f',
    blue = '#61afef',
    green = '#98c379',
    purple = '#c678dd',
    orange = '#e5c07b',
    red1 = '#e06c75',
    red2 = '#be5046',
    yellow = '#e5c07b',
    gray1 = '#5c6370',
    gray2 = '#2c323d',
    gray3 = '#3e4452',
    darkgrey = '#5c6370',
    grey = '#848586',
    middlegrey = '#8791A5',
}

function M.colors()
    return M._colors
end

return M
