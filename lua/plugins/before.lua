local function bufvalid(bufnr)
  return vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_is_valid(bufnr)
end

local function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

local function load_file_line(file, linenum)
  local cnt = 1
  for line in io.lines(file) do
    if cnt == linenum then
      return trim(line)
    end
    cnt = cnt + 1
  end

  return ''
end

local function load_buf_line(bufnr, linenum)
  return trim(vim.api.nvim_buf_get_lines(bufnr, linenum - 1, linenum, false)[1])
end

local function get_line_content(location)
  local line_content = nil

  if bufvalid(location.bufnr) then
    line_content = load_buf_line(location.bufnr, location.line)
  else
    line_content = load_file_line(location.file, location.line)
  end

  if line_content == '' then
    line_content = "[EMPTY-LINE]"
  end
  return line_content
end

return {
    { 'bloznelis/before.nvim',
        dependencies = {
            'folke/which-key.nvim',
            'nvim-telescope/telescope.nvim',
        },
        lazy = false,
        config = function()
            local before = require'before'
            before.setup()
            local ts = require'telescope'
            ts.load_extension('before')

            local pickers = require'telescope.pickers'
            local finders = require'telescope.finders'
            local entry_display = require'telescope.pickers.entry_display'
            local conf = require('telescope.config').values
            local function get_opts()
                return {
                    prompt_title = 'Edit Locations',
                    finder = finders.new_table({
                        results = before.edit_locations,
                        entry_maker = function(entry)
                            local line_content = get_line_content(entry)
                            local filename = entry.file:match('.*/(.*)')

                            local formatter = entry_display.create{
                                separator = '',
                                items = {
                                    { width = filename:len() },                         -- File name
                                    { width = 1 },                                      -- Separator
                                    { width = math.ceil(math.log(entry.line, 10)) },    -- Line
                                    { width = 2 },                                      -- Separator
                                    { remaining = true }                                -- Content
                                }
                            }

                            local display = function()
                                return formatter{
                                    { filename, 'TelescopePreviewLink' },
                                    { ':' },
                                    { entry.line, 'TelescopeResultsNumber' },
                                    { ':' },
                                    { line_content },
                                }
                            end

                            return {
                                value = filename .. entry.line,
                                display = display,
                                ordinal = entry.file .. ':' .. entry.line .. ':' .. line_content;
                                filename = entry.file,
                                bufnr = entry.bufnr,
                                lnum = entry.line,
                                col = entry.col,
                            }
                        end,
                    }),
                    sorter = conf.generic_sorter({}),
                    previewer = conf.grep_previewer({}),
                }
            end
            require'which-key'.add{
                {
                    '<leader>fe', function() pickers.new({ preview_title = 'Preview' }, get_opts()):find() end,
                    desc = 'Show edits in Telescope'
                },
            }
        end,
        keys = {
            { '[e', function() require'before'.jump_to_last_edit() end, desc = 'Jump to last edit location' },
            { ']e', function() require'before'.jump_to_next_edit() end, desc = 'Jump to next edit location' },
            { '<leader>e', function() require'before'.show_edits_in_quickfix() end, desc = 'Show edits in Quickfix window' },
        },
    }
}
