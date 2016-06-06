" Fichier de configuration de vim reservé au langage python

" This is used to save the folds before closing a file, and restoring them
" after opening (useful while reloading the file).
autocmd BufWinEnter *.py loadview
autocmd BufWinLeave,BufUnload *.py mkview
setlocal foldenable
setlocal foldmethod=indent
setlocal foldnestmax=2

setlocal viewoptions=folds,cursor

" Execute file being edited with <Shift> + e:
map <buffer> <S-e> :w<CR>:!/usr/bin/env python % <CR>
" Comment line
nnoremap <buffer> <LocalLeader>c I# <esc>
vnoremap <buffer> <LocalLeader>c :s/^# //<esc>
" Force un hard breaking de la ligne à 80 caractères
set textwidth=79
" Highlight lines over 79 characters.
let &l:colorcolumn=join(range(80,999),",")

" Snap at me abbreviations to force me to use snippets.
for var in ['assertFalse', 'assertTrue', 'assertEqual', 'assertRaisesRegexp', 'api', 'def']
    exec "iabbrev " . var . " 'Bam: You should use a snippet, dummy!'"
endfor

" ROPE {{{
nnoremap <buffer> <LocalLeader>rn :RopeRename<cr>
vnoremap <buffer> <LocalLeader>rl :RopeExtractVariable<cr>
vnoremap <buffer> <LocalLeader>rm :RopeExtractMethod<cr>
nnoremap <buffer> <LocalLeader>ri :RopeInline<cr>
nnoremap <buffer> <LocalLeader>rv :RopeMove<cr>
nnoremap <buffer> <LocalLeader>rx :RopeRestructure<cr>
nnoremap <buffer> <LocalLeader>ru :RopeUseFunction<cr>
nnoremap <buffer> <LocalLeader>rs :RopeChangeSignature<cr>
" }}}
