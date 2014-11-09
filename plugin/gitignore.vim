" Vim plugin that add the entries in a .gitignore file to 'wildignore'
" Last Change:	2014 Jul 26
" Maintainer:	Andy Russell
" Contributors:	Adam Bellaire, Giuseppe Rota
" License:	This file is MIT licensed. See LICENSE for details.

if exists("g:loaded_gitignore_wildignore")
  finish
endif
let g:loaded_gitignore_wildignore = 1

if !exists("g:gitignore_ignore_submodules")
  let g:gitignore_ignore_submodules=1
endif

let s:save_cpo = &cpo
set cpo&vim

function s:WildignoreFromGitignore(...)
  let gitignore = (a:0 && !empty(a:1)) ? fnamemodify(a:1, ':p') : fnamemodify(expand('%'), ':p:h') . '/'
  let gitignore .= '.gitignore'
  if filereadable(gitignore)
    let igstring = ''
    for oline in readfile(gitignore)
      let line = substitute(oline, '\s|\n|\r', '', "g")
      if line =~ '^#' | con | endif
      if line == ''   | con | endif
      if line =~ '^!' | con | endif
      if line =~ '/$'
        let igstring .= "," . substitute(line, '/$', '*', "g")
        con
      endif
      let igstring .= "," . line
    endfor
    let execstring = "set wildignore+=".substitute(igstring, '^,', '', "g")
    execute execstring
  endif
  if g:gitignore_ignore_submodules
    let submodules=split(system('git submodule status'), '\n')
    for submodule in submodules
      let submodule_path=matchstr(submodule, '.*\ze ', 42)
      " Git gives us spaces in the path, so we need to escape the spaces
      let submodule_path=substitute(submodule_path, ' ', '\\ ', 'g')
      execute "set wildignore+=" . submodule_path
    endfor
  endif
endfunction

noremap <unique> <script> <Plug>WildignoreFromGitignore <SID>WildignoreFromGitignore
noremap <SID>WildignoreFromGitignore :call <SID>WildignoreFromGitignore()<CR>

command -nargs=? WildignoreFromGitignore :call <SID>WildignoreFromGitignore(<q-args>)

augroup wildignorefromgitignore_fugitive
    autocmd!
    autocmd User Fugitive if exists('b:git_dir') | call <SID>WildignoreFromGitignore(fnamemodify(b:git_dir, ':h')) | endif
augroup END

let &cpo = s:save_cpo

" vim:set ft=vim sw=2 sts=2 et:
