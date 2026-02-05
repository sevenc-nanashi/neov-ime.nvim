local M = {}

-- Check if Neovim version meets minimum requirements
local function check_version()
  if vim.g.neovime_no_version_warning then
    return
  end

  local required_major = 0
  local required_minor = 12
  local required_patch = 0
  local required_prerelease = "dev-1724"

  local current = vim.version()
  
  -- Compare major.minor.patch
  if current.major < required_major then
    M._show_version_warning()
    return
  elseif current.major > required_major then
    return
  end

  if current.minor < required_minor then
    M._show_version_warning()
    return
  elseif current.minor > required_minor then
    return
  end

  if current.patch < required_patch then
    M._show_version_warning()
    return
  elseif current.patch > required_patch then
    return
  end

  -- If we're at exactly 0.12.0, check the prerelease version
  -- For dev versions, the prerelease field contains "dev+<build_number>"
  if current.prerelease then
    local build_num = tonumber(current.prerelease:match("dev%-(%d+)"))
    if build_num and build_num < 1724 then
      M._show_version_warning()
    end
  end
end

M._show_version_warning = function()
  vim.api.nvim_echo({
    { "[neov-ime] Warning: ", "WarningMsg" },
    {
      "Your Neovim version is too old. At least 0.12.0-dev-1724 is required. ",
      "Normal"
    },
    {
      "Set g:neovime_no_version_warning to suppress this warning.",
      "Comment"
    },
  }, true, {})
end

local function num_bytes_at_byte_index(str, byte_index)
  -- vim.fn.slice handles multi-byte characters correctly, so we can use it to get the number of bytes of the character at the given byte index.
  return #vim.fn.slice(str:sub(byte_index + 1), 0, 1)
end

local hl_preedit_bg = "NeovImePreedit"
local hl_cursor = "NeovImePreeditCursor"
local hl_cursor_on_text = "NeovImeOverlayCursorOnText"
local hl_cursor_tail = "NeovImePreeditCursorTail"
local hl_hidden = "NeovImeHidden"
vim.api.nvim_set_hl(0, hl_preedit_bg, { link = "Pmenu", default = true })
vim.api.nvim_set_hl(0, hl_cursor, { link = "PmenuSel", default = true })
vim.api.nvim_set_hl(0, hl_cursor_on_text, { link = hl_cursor, default = true })
vim.api.nvim_set_hl(0, hl_cursor_tail, { link = hl_cursor, default = true })

-- Hidden highlight group for hiding the original cursor during preedit;
-- Do not override this highlight group in your config.
vim.api.nvim_set_hl(0, hl_hidden, { blend = 100, default = true })

---@class ImeContext
---@field entered_preedit_block boolean
---@field is_commited boolean
---@field base_row integer The absolute bytes based position of the cursor's row within the window.
---@field base_col integer The absolute bytes based position of the cursor's column within the window.
---@field preedit_cursor_offset integer The bytes offset of the preedit cursor within the preedit text.
---@field preedit_text_offset integer The length in bytes of the preedit text.
---@field extmark_state? ImeExtmarkState

---@class ImePreeditData
---@field preedit_raw_text string
---@field cursor_offset? [integer, integer] (start_col, end_col) This values show the cursor begin position and end position. The position is byte-wise indexed.

---@class ImeCommitData
---@field commit_raw_text string
---@field commit_formatted_text string It's escaped.

---@class ImeExtmarkState
---@field virt_text {[1]: string, [2]: string}[]
---@field buffer_id integer
---@field extmark_id integer

---@type ImeContext
local ime_context = {
  entered_preedit_block = false,
  is_commited = false,
  base_row = 0,
  base_col = 0,
  preedit_cursor_offset = 0,
  preedit_text_offset = 0,
  extmark_state = nil,
}

local ns_id = vim.api.nvim_create_namespace("neovide_ime_preedit_ns")

function ime_context.cleanup_extmark()
  if ime_context.extmark_state ~= nil then
    vim.api.nvim_buf_del_extmark(ime_context.extmark_state.buffer_id, ns_id, ime_context.extmark_state.extmark_id)
  end
  ime_context.extmark_state = nil
end

ime_context.reset = function()
  ime_context.base_row, ime_context.base_col = 0, 0
  ime_context.preedit_cursor_offset = 0
  ime_context.preedit_text_offset = 0
  ime_context.entered_preedit_block = false
  ime_context.is_commited = false
  ime_context.cleanup_extmark()
end

---@param buffer_id integer|nil if not set, set current buffer id
---@param virt_text {[1]: string, [2]: string}[]|nil if not set, use last virt_text
---@param extmark_id integer|nil if not set, use last extmark_id
ime_context.update_extmark_position = function(buffer_id, virt_text, extmark_id)
  if ime_context.extmark_state ~= nil then
    buffer_id = buffer_id or ime_context.extmark_state.buffer_id
    virt_text = virt_text or ime_context.extmark_state.virt_text
    extmark_id = extmark_id or ime_context.extmark_state.extmark_id
  end
  ime_context.extmark_state = {
    buffer_id = buffer_id,
    virt_text = virt_text,
    extmark_id = vim.api.nvim_buf_set_extmark(buffer_id, ns_id, ime_context.base_row - 1, ime_context.base_col, {
      id = extmark_id,
      virt_text = virt_text,
      virt_text_pos = "overlay",
      hl_mode = "combine",
    }),
  }
end

---Getting cursor's row and colomn in bytes
---@param window_id? integer if not set, set current window id
---@return integer row
---@return integer colomn (started zero-colomn)
local function get_position_under_cursor(window_id)
  local win_id = window_id or vim.api.nvim_get_current_win()
  ---@type integer, integer
  local row, col = unpack(vim.api.nvim_win_get_cursor(win_id))
  return row, col
end

local previous_guicursor = nil

local function hide_guicursor()
  if previous_guicursor ~= nil then
    return
  end
  previous_guicursor = vim.o.guicursor
  vim.o.guicursor = "a:" .. hl_hidden
end
local function restore_guicursor()
  if previous_guicursor == nil then
    return
  end
  vim.o.guicursor = previous_guicursor
  previous_guicursor = nil
end

---@param preedit_raw_text string
---@param cursor_offset_start integer
---@param cursor_offset_end integer
local function preedit_handler_extmark(preedit_raw_text, cursor_offset_start, cursor_offset_end)
  if ime_context.is_commited then
    ime_context.reset()
  end

  -- Always update the base position because the cursor might move during preedit, especially in terminal mode.
  local row, col = get_position_under_cursor()
  ime_context.base_row = row
  ime_context.base_col = col
  ime_context.preedit_cursor_offset = 0
  ime_context.preedit_text_offset = 0
  ime_context.entered_preedit_block = true

  if preedit_raw_text ~= nil and preedit_raw_text ~= "" and cursor_offset_start ~= nil and cursor_offset_end ~= nil then
    -- Hide the original cursor because cursor will be drawn by the extmark
    hide_guicursor()

    -- Update the preedit text and cursor position if there is preedit text
    ime_context.preedit_cursor_offset = cursor_offset_end
    ime_context.preedit_text_offset = string.len(preedit_raw_text)

    local buffer_id
    if ime_context.extmark_state ~= nil then
      buffer_id = ime_context.extmark_state.buffer_id
    else
      buffer_id = vim.api.nvim_get_current_buf()
    end

    -- Set the highlight for the selected character
    -- If the cursor is at the end of the preedit text, append a space and highlight it.
    -- If not, highlight the selected character.
    local virt_text
    if cursor_offset_end == #preedit_raw_text then
      virt_text = {
        { preedit_raw_text:sub(1, cursor_offset_start), hl_preedit_bg },
        { " ",                                          hl_cursor_tail },
      }
    else
      local char_after_end_index = cursor_offset_end + num_bytes_at_byte_index(preedit_raw_text, cursor_offset_end)
      virt_text = {
        { preedit_raw_text:sub(1, cursor_offset_start),   hl_preedit_bg },
        {
          preedit_raw_text:sub(
            cursor_offset_start + 1, char_after_end_index
          ),
          hl_cursor_on_text },
        { preedit_raw_text:sub(char_after_end_index + 1), hl_preedit_bg }
      }
    end

    ime_context.update_extmark_position(buffer_id, virt_text, nil)
  else
    -- Clear the preedit text and reset the cursor position if there is no preedit text
    ime_context.entered_preedit_block = false
    ime_context.cleanup_extmark()
    restore_guicursor()
    vim.api.nvim_win_set_cursor(0, { ime_context.base_row, ime_context.base_col })
  end
end

local group_name = "ImePreeditMoveExtMark"
vim.api.nvim_create_augroup(group_name, { clear = true })
vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "TextChangedT" }, {
  group = group_name,
  callback = function()
    if ime_context.entered_preedit_block and ime_context.extmark_state ~= nil then
      -- Move the extmark to the new cursor position
      local row, col = get_position_under_cursor()
      if row == ime_context.base_row and col == ime_context.base_col then
        return
      end
      ime_context.base_row = row
      ime_context.base_col = col

      ime_context.update_extmark_position()
    end
  end,
})
vim.api.nvim_create_autocmd("BufLeave", {
  group = group_name,
  callback = function()
    if ime_context.entered_preedit_block and ime_context.extmark_state ~= nil then
      -- Clear the preedit text and reset the cursor position if the buffer is left during preedit
      ime_context.entered_preedit_block = false
      ime_context.cleanup_extmark()
      restore_guicursor()
    end
  end,
})

---@param preedit_raw_text string
---@param cursor_offset_start integer
---@param cursor_offset_end integer
M.preedit_handler = function(preedit_raw_text, cursor_offset_start, cursor_offset_end)
  if vim.in_fast_event() then
    -- In fast event, skip the preedit handling.
    return
  end

  -- Defer the preedit handling to run the extmark update in the main loop.
  -- TODO: Investigate why (I haven't understood how fast event works yet)
  vim.schedule(function()
    preedit_handler_extmark(preedit_raw_text, cursor_offset_start, cursor_offset_end)
  end)
end

local cleanup_schedule_nonce = 0

---@param commit_raw_text string
---@param commit_formatted_text string It's escaped.
M.commit_handler = function(commit_raw_text, commit_formatted_text)
  ---@diagnostic disable-next-line: unused-local
  local _void = commit_raw_text

  if vim.in_fast_event() then
    -- In fast event, 99% of functions are not allowed, thus we defer the cleanup until the next main loop.
    vim.api.nvim_input(commit_formatted_text)
    cleanup_schedule_nonce = cleanup_schedule_nonce + 1
    local my_nonce = cleanup_schedule_nonce
    vim.schedule(function()
      if my_nonce ~= cleanup_schedule_nonce then
        -- A newer schedule task has been created, skip this one.
        return
      end
      ime_context.cleanup_extmark()
      restore_guicursor()
    end)
  else
    vim.api.nvim_input(commit_formatted_text)
    ime_context.cleanup_extmark()
    restore_guicursor()
  end

  ime_context.is_commited = true
end

---Install the preedit and commit handlers to Neovide.
M.setup = function()
  check_version()
  neovide.preedit_handler = M.preedit_handler
  neovide.commit_handler = M.commit_handler
end

local first_install_attempt = nil
local install_attempts = 0
if vim.g.neovime_install_timeout == nil then
  vim.g.neovime_install_timeout = 10 -- seconds
end
M.__deferred_setup = function()
  if first_install_attempt == nil then
    first_install_attempt = vim.loop.hrtime()
  end
  if _G["neovide"] == nil then
    if (vim.loop.hrtime() - first_install_attempt) / 1e9 > vim.g.neovime_install_timeout then
      vim.api.nvim_echo({
        {
          "[neov-ime] `g:neovide` was set, but Neovide API is still not available. Aborting IME handler installation. Check :h neov-ime-troubleshooting for details.",
          "ErrorMsg",
        },
      }, true, {})
      return
    end
    install_attempts = install_attempts + 1
    if install_attempts <= 10 then
      -- Try to install immediately for the first 10 attempts.
      vim.schedule(M.__deferred_setup)
    else
      -- After that, try to install every 100ms.
      vim.defer_fn(M.__deferred_setup, 100)
    end
    return
  end
  M.setup()
end

return M
