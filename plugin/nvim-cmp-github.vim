fun! NvimCmpGithub()
  lua for k in pairs(package.loaded) do if k:match("^nvim%-cmp%-github") then package.loaded[k] = nil end end
  lua require("nvim_cmp_github")
endfun

augroup NvimCmpGithub
  autocmd!
augroup END
