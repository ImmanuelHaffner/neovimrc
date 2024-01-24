-- This file provides the global NVim configuration
local M = { }

function M.setup()

    -- Define <Leader> for mappings
    vim.g.mapleader = ' '

    -- When this option is set, the screen will not be redrawn while executing macros, registers and other commands that
    -- have not been typed.
    vim.opt.lazyredraw = false

    -- Changes the effect of the |:mksession| command.  It is a comma- separated list of words.  Each word enables
    -- saving and restoring something.
    vim.g.sessionoptions = 'buffers,folds,sesdir,tabpages,winpos,winsize,help'

    -- When a file has been detected to have been changed outside of Vim and it has not been changed inside of Vim,
    -- automatically read it again.
    vim.opt.autoread = true

    -- This option helps to avoid all the |hit-enter| prompts caused by file messages, for example  with CTRL-G, and to
    -- avoid some other messages. It is a list of flags.
    vim.g.shortmess = 'filnxtToOFc'

    ----- Visuals {{{---------------------------------------------------------------------------------------------------
    -- Enables 24-bit RGB color in the TUI.
    vim.opt.termguicolors = true
    --When set to "dark" or "light", adjusts the default color groups for that background type.
    vim.opt.background = 'dark'

    -- 'colorcolumn' is a comma-separated list of screen columns that are highlighted with ColorColumn |hl-ColorColumn|.
    -- Useful to align text.
    vim.opt.colorcolumn = '121'

    -- Highlight the text line of the cursor with CursorLine |hl-CursorLine|.
    vim.opt.cursorline = true

    -- Print the line number in front of each line.
    vim.opt.number = true

    -- Show the line number relative to the line with the cursor in front of each line.
    vim.opt.relativenumber = true

    -- Minimal number of screen lines to keep above and below the cursor.
    vim.opt.scrolloff = 7

    -- The minimal number of columns to scroll horizontally.  Used only when the 'wrap' option is off and the cursor is
    -- moved off of the screen.
    vim.opt.sidescroll = 1

    -- The minimal number of screen columns to keep to the left and to the right of the cursor if 'nowrap' is set.
    vim.opt.sidescrolloff = 15

    -- Determine how text with the "conceal" syntax attribute |:syn-conceal| is shown:  Concealed text is completely
    -- hidden unless it has a custom replacement character defined (see |:syn-cchar|).
    vim.opt.conceallevel = 2

    -- Sets the modes in which text in the cursor line can also be concealed.
    vim.opt.concealcursor = ''

    -- The value of this option influences when the last window will have a status line:
    --      3: always and ONLY the last window
    vim.opt.laststatus = 3
    --}}}---------------------------------------------------------------------------------------------------------------

    -- Use a dialog when an operation has to be confirmed.
    vim.opt.confirm = true

    -- If in Insert, Replace or Visual mode *do not* put a message on the last line.
    vim.opt.showmode = false

    -- When on, splitting a window will put the new window below the current one.
    vim.opt.splitbelow = true

    -- When on, splitting a window will put the new window right of the current one.
    vim.opt.splitright = true

    ----- Wildmenu configuration for command-line completion {{{--------------------------------------------------------
    -- Ignore case when completing file names and directories.
    vim.opt.wildignorecase = true

    -- Character you have to type to start wildcard expansion in the command-line
    vim.opt.wildchar = vim.api.nvim_replace_termcodes('<Tab>', true, true, true)[1]

    -- Enable wildmenu "enhanced mode", showing completions *above* the command line.
    vim.opt.wildmenu = true

    -- Completion behavior: When more than one match, list all matches and complete till longest common string.
    vim.opt.wildmode = 'list:longest,list:full'
    --}}}---------------------------------------------------------------------------------------------------------------

    -- Insert mode completion
    vim.opt.completeopt = 'menu,menuone,longest,noselect'

    -- Specify the tag files
    vim.opt.tags = './.tags'

    ----- Formatting {{{------------------------------------------------------------------------------------------------
    -- In Insert mode: Use the appropriate number of spaces to insert a <Tab>.
    vim.opt.expandtab = true

    -- Number of spaces that a <Tab> in the file counts for.
    vim.opt.tabstop = 4

    -- Number of spaces that a <Tab> counts for while performing editing operations, like inserting a <Tab> or using
    -- <BS>.
    vim.opt.softtabstop = 4

    -- Number of spaces to use for each step of (auto)indent.  Used for |'cindent'|, |>>|, |<<|, etc.
    vim.opt.shiftwidth = 4

    -- When on, a <Tab> in front of a line inserts blanks according to 'shiftwidth'.  'tabstop' or 'softtabstop' is used
    -- in other places.
    vim.opt.smarttab = true

    -- Strings to use in 'list' mode and for the |:list| command.  It is a comma-separated list of string settings.
    vim.opt.listchars = 'tab:┣━,extends:@,trail:·'

    -- List mode: By default, show tabs as ">", trailing spaces as "-", and non-breakable space characters as "+".
    -- Useful to see the difference between tabs and spaces and for trailing blanks. Further changed by the 'listchars'
    -- option.
    vim.opt.list = true

    vim.opt.textwidth = 120

    -- This option changes how text is displayed.  It doesn't change the text in the buffer, see 'textwidth' for that.
    vim.opt.wrap = false

    -- If on, Vim will wrap long lines at a character in 'breakat' rather than at the last character that fits on the
    -- screen.  Unlike 'wrapmargin' and 'textwidth', this does not insert <EOL>s in the file, it only affects the way
    -- the file is displayed, not its contents.
    vim.opt.linebreak = true

    -- This is a sequence of letters which describes how automatic formatting is to be done.  See |fo-table|.
    vim.opt.formatoptions = 'tcrqnlj'
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- Undo configuration {{{----------------------------------------------------------------------------------------
    -- List of directory names for undo files, separated with commas.
    vim.g.undodir = os.getenv('HOME') .. '/.cache/nvim/undo'

    -- When on, Vim automatically saves undo history to an undo file when writing a buffer to a file, and restores undo
    -- history from the same file on buffer read.
    vim.opt.undofile = true

    -- Maximum number of changes that can be undone.
    vim.opt.undolevels = 200

    -- Save the whole buffer for undo when reloading it.  The save only happens when this option is negative or when the
    -- number of lines is smaller than the value of this option.
    vim.opt.undoreload = 10000
    --}}}---------------------------------------------------------------------------------------------------------------

    ----- Search configuration {{{--------------------------------------------------------------------------------------
    -- Searches wrap around the end of the file.  Also applies to |]s| and |[s|, searching for spelling mistakes.
    vim.opt.wrapscan = false

    -- When there is a previous search pattern, highlight all its matches.
    vim.opt.hlsearch = true

    -- While typing a search command, show where the pattern, as it was typed so far, matches.  The matched string is
    -- highlighted.
    vim.opt.incsearch = true

    -- Ignore case in search patterns.  Also used when searching in the tags file.
    vim.opt.ignorecase = true

    -- Override the 'ignorecase' option if the search pattern contains upper case characters.
    vim.opt.smartcase = true
    --}}}---------------------------------------------------------------------------------------------------------------

    -- The name of the font that will be used for |:hardcopy|. See |pfn-option|.
    vim.g.printfont = 'Courier:h8'

end

return M
