" Vim plugin that add the entries in a .gitignore file to 'wildignore'
" Last Change:	2014 Jul 26
" Maintainer:	Andy Russell
" Contributors:	Adam Bellaire, Giuseppe Rota
" License:	This file is MIT licensed. See LICENSE for details.

if exists("g:loaded_gitignore_wildignore")
  finish
endif
let g:loaded_gitignore_wildignore = 1

if !has('python')
  echo "Error: Vim not compiled with +python."
  finish
endif

let s:save_cpo = &cpo
set cpo&vim

function s:WildignoreFromStatus(git_dir)
python << EOF
import os
import subprocess
import vim

git_dir = vim.eval('a:git_dir')

file_statuses = subprocess.check_output(
        ['git', 'status', '--ignored', '--porcelain'])
for file_status in file_statuses.decode('utf-8').split('\n'):
    if file_status.startswith('!!'):
        escaped_path = (
                os.path.join(git_dir, file_status[3:]).replace(' ', '\ '))
        vim.options['wildignore'] += ',' + escaped_path.rstrip('/')
EOF
endfunction

function s:WildignoreFromSubmodules(git_dir)
python << EOF
import os
import re
import subprocess
import vim

git_dir = vim.eval('a:git_dir')
submodules = subprocess.check_output(['git', 'submodule', 'status', '--recursive'])
for submodule in submodules.splitlines():
    # The command will return triples of hash, path, and branch.
    # We are only interested in the path.
    if submodule[0] == '-':  # ignore non-initialised submodules
        continue
    submodule_path, = re.search(r'[ +U].{40} (.*) \(.*?\)', submodule).groups()
    escaped_path = os.path.abspath(submodule_path).replace(' ', '\ ')
    vim.options['wildignore'] += ',' + escaped_path
EOF
endfunction

function s:WildignoreFromGitignore(git_dir)
  call <SID>WildignoreFromStatus(a:git_dir)
  call <SID>WildignoreFromSubmodules(a:git_dir)
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
