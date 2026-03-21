--- Speech-to-text integration for CodeCompanion chat.
---
--- Workflow (macOS speech-to-text app):
---   1. App sends `<D-F8>` or `<F8>` when recording starts.
---   2. App sends `<F8><D-v>` when recording finishes (F8 then paste).
---
--- Keymaps (buffer-local on `codecompanion` buffers):
---   `<D-F8>` / `<F8>` — toggle recording state:
---       Not recording → save mode, jump to end of chat, enter insert mode,
---                        show "🎤 Recording…" overlay at cursor.
---       Recording     → clear extmark (mode restored after paste).
---   `<D-v>`          — (only during recording) one-shot paste from system clipboard (`+` register).
---   `<Esc>`          — (only during recording) abort: clear extmark, exit insert mode,
---                       install a no-op `<D-v>` absorber for the paste the app will still send.

local M = {}

local ns = vim.api.nvim_create_namespace('speech_to_text')

-- "On Air" highlight: bold red text reminiscent of a recording indicator
vim.api.nvim_set_hl(0, 'SpeechRecording', { fg = '#ff2020', bold = true })

--- Remove all one-shot keymaps installed during recording.
---@param bufnr number
local function clear_recording_keymaps(bufnr)
    pcall(vim.keymap.del, 'n', '<D-v>', { buffer = bufnr })
    pcall(vim.keymap.del, 'i', '<D-v>', { buffer = bufnr })
    pcall(vim.keymap.del, 'i', '<Esc>', { buffer = bufnr })
end

--- Restore the vim mode that was active before recording started.
---@param bufnr number
local function restore_mode(bufnr)
    local orig = vim.b[bufnr]._speech_orig_mode
    vim.b[bufnr]._speech_orig_mode = nil
    if orig == 'n' then
        vim.cmd('stopinsert')
    end
end

--- Abort recording: clear state, install a no-op `<D-v>` absorber, exit insert mode.
---@param bufnr number
local function recording_abort(bufnr)
    vim.b[bufnr]._speech_recording = false
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    clear_recording_keymaps(bufnr)
    -- One-shot no-op <D-v>: absorb the paste the app will still send, then remove itself.
    -- Mapped in both modes since <Esc> leaves us in normal mode before <D-v> arrives.
    vim.keymap.set({ 'n', 'i' }, '<D-v>', function()
        pcall(vim.keymap.del, 'n', '<D-v>', { buffer = bufnr })
        pcall(vim.keymap.del, 'i', '<D-v>', { buffer = bufnr })
    end, { buffer = bufnr, desc = '[Speech] Absorb paste (aborted)' })
end

--- Start recording: jump to end of chat, enter insert mode, show extmark.
--- Installs one-shot `<D-v>` (paste) and `<Esc>` (abort) mappings.
---@param bufnr number
local function recording_start(bufnr)
    vim.b[bufnr]._speech_orig_mode = vim.fn.mode()
    vim.b[bufnr]._speech_recording = true

    -- Move cursor to end of buffer and enter insert mode if in normal mode
    if vim.b[bufnr]._speech_orig_mode == 'n' then
        local last_line = vim.api.nvim_buf_line_count(bufnr)
        vim.api.nvim_win_set_cursor(0, { last_line, 0 })
        vim.cmd('startinsert!')  -- moves cursor to end of line
    end

    -- Show overlay extmark at cursor position (deferred so cursor has settled after startinsert)
    vim.schedule(function()
        if not vim.api.nvim_buf_is_valid(bufnr) then return end
        local cursor = vim.api.nvim_win_get_cursor(0)
        vim.api.nvim_buf_set_extmark(bufnr, ns, cursor[1] - 1, cursor[2], {
            virt_text = { { '🎤 Recording…', 'SpeechRecording' } },
            virt_text_pos = 'overlay',
        })
    end)

    -- One-shot <D-v>: paste from clipboard, clean up, restore mode
    vim.keymap.set({ 'n', 'i' }, '<D-v>', function()
        local lines = vim.split(vim.fn.getreg('+'), '\n', { plain = true })
        vim.api.nvim_put(lines, 'c', false, true)
        -- If recording was started from normal mode, append a newline after the pasted text
        if vim.b[bufnr]._speech_orig_mode == 'n' then
            vim.api.nvim_put({ '', '' }, 'c', true, true)
        end
        clear_recording_keymaps(bufnr)
        restore_mode(bufnr)
    end, { buffer = bufnr, desc = '[Speech] Paste from clipboard (one-shot)' })

    -- One-shot <Esc>: abort recording
    vim.keymap.set('i', '<Esc>', function()
        recording_abort(bufnr)
        vim.cmd('stopinsert')
    end, { buffer = bufnr, desc = '[Speech] Abort recording' })
end

--- Stop recording: clear extmark, remove <Esc> override (keep <D-v> for incoming paste).
---@param bufnr number
local function recording_stop(bufnr)
    vim.b[bufnr]._speech_recording = false
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    pcall(vim.keymap.del, 'i', '<Esc>', { buffer = bufnr })
    -- Mode is restored after <D-v> fires (not here, since paste hasn't arrived yet)
end

--- Set up speech-to-text keymaps on a CodeCompanion chat buffer.
---@param bufnr number
local function attach(bufnr)
    -- Guard: only attach once per buffer
    if vim.b[bufnr]._speech_attached then return end
    vim.b[bufnr]._speech_attached = true

    -- <D-F8> / <F8>: toggle recording state
    -- Not recording → start; already recording → stop & arm submit.
    -- The speech app sends <D-F8> or <F8> to start, then <F8><D-v> to finish.
    local function toggle_recording()
        if vim.b[bufnr]._speech_recording then
            recording_stop(bufnr)
        else
            recording_start(bufnr)
        end
    end

    vim.keymap.set({ 'n', 'i' }, '<D-F8>', toggle_recording,
        { buffer = bufnr, desc = '[Speech] Toggle recording' })
    vim.keymap.set({ 'n', 'i' }, '<F8>', toggle_recording,
        { buffer = bufnr, desc = '[Speech] Toggle recording' })

end

function M.install_on_ui_enter(augrp)
    vim.api.nvim_create_autocmd('UIEnter', {
        group = augrp,
        callback = function()
            if not vim.g.neovide then return end

            vim.api.nvim_clear_autocmds({ group = augrp })

            vim.api.nvim_create_autocmd('FileType', {
                pattern = 'codecompanion',
                group = augrp,
                callback = function(args)
                    attach(args.buf)
                end,
                desc = 'Attach speech-to-text keymaps to CodeCompanion chat',
            })

            M.install_on_ui_leave(augrp)
        end,
        desc = 'Trigger setup of Speech-to-Text utility on UIEnter'
    })
end

function M.install_on_ui_leave(augrp)
    vim.api.nvim_create_autocmd('UILeave', {
        group = augrp,
        callback = function()
            M.install_on_ui_enter(augrp)
        end,
        desc = 'Trigger tear down of Speech-to-Text utility on UILeave'
    })
end

--- Call once from CodeCompanion's config function.
--- Listens for codecompanion buffers and attaches speech keymaps.
function M.setup()
    local augrp_speech_to_text = vim.api.nvim_create_augroup('SpeechToText', {})
    M.install_on_ui_enter(augrp_speech_to_text)
end

return M
