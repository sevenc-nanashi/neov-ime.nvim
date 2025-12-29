-- Detect if nvim is running in Neovide; if not, don't load the IME handlers
if vim.g.neovide == nil or vim.g.neovide == false then
  return
end

local neovide_ime = require("neov-ime")

neovide.preedit_handler = neovide_ime.preedit_handler
neovide.commit_handler = neovide_ime.commit_handler
