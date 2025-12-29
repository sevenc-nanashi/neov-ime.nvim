-- Detect if nvim is running in Neovide, and defer the initialization if not.
-- Note that `vim.g.neovide` might be set after this script is loaded, especially
-- some remote-control setups like `nvrh`. (And as I really love nvrh, this is a must-have feature!)
-- So we watch the variable instead of checking it once.
if vim.g.neovime_manual_setup == true then
  return
end

if vim.g.neovide == true then
  require("neov-ime").setup()
else
  vim.api.nvim_exec2(
    [[
      function! s:on_neovide_set(dict, key, value) abort
        if g:neovide
          " Who wants to write lua in a vimscript function that is written inside a lua file...
          lua require("neov-ime").__deferred_setup()
          call dictwatcherdel(g:, "neovide", function('s:on_neovide_set'))
        endif
      endfunction
      call dictwatcheradd(g:, "neovide", function('s:on_neovide_set'))
    ]],
    { output = false }
  )
end
