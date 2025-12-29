-- Detect if nvim is running in Neovide, and defer the initialization if not.
-- Note that `vim.g.neovide` might be set after this script is loaded, especially
-- some remote-control setups like `nvrh`. (And I really love nvrh!)
-- So we watch the variable instead of checking it once.
if vim.g.neovide == true then
  require("neov-ime").install()
elseif vim.g.neovime_manual_init ~= true then
  vim.api.nvim_exec2(
    [[
      function! s:on_neovide_set(dict, key, value) abort
        if g:neovide
          " Who wants to write lua in a vimscript function that is written inside a lua file...
          lua require("neov-ime").__deferred_install()
          call dictwatcherdel(g:, "neovide", function('s:on_neovide_set'))
        endif
      endfunction
      call dictwatcheradd(g:, "neovide", function('s:on_neovide_set'))
    ]],
    { output = false }
  )
end
