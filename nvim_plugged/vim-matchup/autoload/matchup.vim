" vim match-up - matchit replacement and more
"
" Maintainer: Andy Massimino
" Email:      a@normed.space
"

let s:save_cpo = &cpo
set cpo&vim

function! matchup#init()
  call matchup#perf#tic('loading')

  call s:init_options()
  call s:init_modules()
  call s:init_default_mappings()

  call matchup#perf#toc('loading', 'init_done')
endfunction

function! s:init_options()
  call s:init_option('matchup_matchparen_enabled',
    \ !(&t_Co < 8 && !has('gui_running')))
  call s:init_option('matchup_matchparen_status_offscreen', 1)
  call s:init_option('matchup_matchparen_scrolloff', 0)
  call s:init_option('matchup_matchparen_singleton', 0)
  call s:init_option('matchup_matchparen_deferred', 0)
  call s:init_option('matchup_matchparen_deferred_show_delay', 50)
  call s:init_option('matchup_matchparen_deferred_hide_delay', 700)
  call s:init_option('matchup_matchparen_stopline', 400)
  call s:init_option('matchup_matchparen_pumvisible', 1)
  call s:init_option('matchup_matchparen_novisual', 0)

  call s:init_option('matchup_matchparen_timeout',
    \ get(g:, 'matchparen_timeout', 300))
  call s:init_option('matchup_matchparen_insert_timeout',
    \ get(g:, 'matchparen_insert_timeout', 60))

  call s:init_option('matchup_delim_count_fail', 0)
  call s:init_option('matchup_delim_count_max', 8)
  call s:init_option('matchup_delim_start_plaintext', 1)
  call s:init_option('matchup_delim_noskips', 0)

  call s:init_option('matchup_motion_enabled', 1)
  call s:init_option('matchup_motion_cursor_end', 1)
  call s:init_option('matchup_motion_override_Npercent', 6)

  call s:init_option('matchup_text_obj_enabled', 1)
  call s:init_option('matchup_text_obj_linewise_operators', ['d', 'y'])

  call s:init_option('matchup_transmute_enabled', 0)

  call s:init_option('matchup_mouse_enabled', 1)

endfunction

function! s:init_option(option, default)
  let l:option = 'g:' . a:option
  if !exists(l:option)
    let {l:option} = a:default
  endif
endfunction

function! s:init_modules()
  for l:mod in [ 'loader', 'matchparen' ]
    if !get(g:, 'matchup_'.l:mod.'_enabled', 1)
      continue
    endif
    call matchup#perf#tic('loading_module')
    call matchup#{l:mod}#init_module()
    call matchup#perf#toc('loading_module', l:mod)
  endfor

  call s:motion_init_module()
  call s:text_obj_init_module()
  call s:misc_init_module()
endfunction

let g:v_motion_force = ''
function! s:force(wise)
  let g:v_motion_force = a:wise
  " let g:v_operator = v:operator
  return ''
endfunction

function! s:init_default_mappings()
  if !get(g:,'matchup_mappings_enabled', 1) | return | endif

  function! s:map(mode, lhs, rhs, ...)
    if !hasmapto(a:rhs, a:mode)
          \ && ((a:0 > 0) || (maparg(a:lhs, a:mode) ==# ''))
      silent execute a:mode . 'map <silent> ' a:lhs a:rhs
    endif
  endfunction

  for l:opforce in ['', 'v', 'V', '<c-v>']
    call s:map('onore', '<expr> <plug>(matchup-o_'.l:opforce.')',
          \ '<sid>force('''.l:opforce.''')')
  endfor

  " these won't conflict since matchit should not be loaded at this point
  if get(g:, 'matchup_motion_enabled', 0)
    call s:map('n', '%',  '<plug>(matchup-%)' )
    call s:map('n', 'g%', '<plug>(matchup-g%)')

    call s:map('x', '%',  '<plug>(matchup-%)' )
    call s:map('x', 'g%', '<plug>(matchup-g%)')

    call s:map('n', ']%', '<plug>(matchup-]%)')
    call s:map('n', '[%', '<plug>(matchup-[%)')

    call s:map('x', ']%', '<plug>(matchup-]%)')
    call s:map('x', '[%', '<plug>(matchup-[%)')

    call s:map('n', 'z%', '<plug>(matchup-z%)')
    call s:map('x', 'z%', '<plug>(matchup-z%)')

    for l:opforce in ['', 'v', 'V', '<c-v>']
      call s:map('o', l:opforce.'%',
            \ '<plug>(matchup-o_'.l:opforce.')<plug>(matchup-%)')
      call s:map('o', l:opforce.'g%',
            \ '<plug>(matchup-o_'.l:opforce.')<plug>(matchup-g%)')
      call s:map('o', l:opforce.']%',
            \ '<plug>(matchup-o_'.l:opforce.')<plug>(matchup-]%)')
      call s:map('o', l:opforce.'[%',
            \ '<plug>(matchup-o_'.l:opforce.')<plug>(matchup-[%)')
      call s:map('o', l:opforce.'z%',
            \ '<plug>(matchup-o_'.l:opforce.')<plug>(matchup-z%)')
    endfor
  endif

  if get(g:, 'matchup_text_obj_enabled', 0)
    call s:map('x', 'i%', '<plug>(matchup-i%)')
    call s:map('x', 'a%', '<plug>(matchup-a%)')
    for l:opforce in ['', 'v', 'V', '<c-v>']
      call s:map('o', l:opforce.'i%',
            \ '<plug>(matchup-o_'.l:opforce.')<plug>(matchup-i%)')
      call s:map('o', l:opforce.'a%',
            \ '<plug>(matchup-o_'.l:opforce.')<plug>(matchup-a%)')
    endfor
  endif

  if get(g:, 'matchup_mouse_enabled', 1)
    call s:map('n', '<2-LeftMouse>', '<plug>(matchup-double-click)')
  endif
endfunction

" module initialization

function! s:motion_init_module() " {{{1
  if !g:matchup_motion_enabled | return | endif

  call matchup#perf#tic('loading_module')

  " gets the current forced motion type
  nnoremap <silent><expr> <sid>(wise)
        \ empty(g:v_motion_force) ? 'v' : g:v_motion_force

  " the basic motions % and g%
  nnoremap <silent> <plug>(matchup-%)
        \ :<c-u>call matchup#motion#find_matching_pair(0, 1)<cr>
  nnoremap <silent> <plug>(matchup-g%)
        \ :<c-u>call matchup#motion#find_matching_pair(0, 0)<cr>

  " visual and operator-pending
  xnoremap <silent> <sid>(matchup-%)
        \ :<c-u>call matchup#motion#find_matching_pair(1, 1)<cr>
  xmap     <silent> <plug>(matchup-%) <sid>(matchup-%)
  onoremap <silent> <plug>(matchup-%)
        \ :<c-u>call matchup#motion#op('%')<cr>

  xnoremap <silent> <sid>(matchup-g%)
        \ :<c-u>call matchup#motion#find_matching_pair(1, 0)<cr>
  xmap     <silent> <plug>(matchup-g%) <sid>(matchup-g%)
  onoremap <silent> <plug>(matchup-g%)
        \ :<c-u>call matchup#motion#op('g%')<cr>

  " ]% and [%
  nnoremap <silent> <plug>(matchup-]%)
        \ :<c-u>call matchup#motion#find_unmatched(0, 1)<cr>
  nnoremap <silent> <plug>(matchup-[%)
        \ :<c-u>call matchup#motion#find_unmatched(0, 0)<cr>

  xnoremap <silent> <sid>(matchup-]%)
        \ :<c-u>call matchup#motion#find_unmatched(1, 1)<cr>
  xnoremap <silent> <sid>(matchup-[%)
        \ :<c-u>call matchup#motion#find_unmatched(1, 0)<cr>
  xmap     <plug>(matchup-]%) <sid>(matchup-]%)
  xmap     <plug>(matchup-[%) <sid>(matchup-[%)
  onoremap <silent> <plug>(matchup-]%)
        \ :<c-u>call matchup#motion#op(']%')<cr>
  onoremap <silent> <plug>(matchup-[%)
        \ :<c-u>call matchup#motion#op('[%')<cr>

  " jump inside z%
  nnoremap <silent> <plug>(matchup-z%)
        \ :<c-u>call matchup#motion#jump_inside(0)<cr>

  xnoremap <silent> <sid>(matchup-z%)
        \ :<c-u>call matchup#motion#jump_inside(1)<cr>
  xmap     <silent> <plug>(matchup-z%) <sid>(matchup-z%)
  onoremap <silent> <plug>(matchup-z%)
        \ :<c-u>call matchup#motion#op('z%')<cr>

  call matchup#perf#toc('loading_module', 'motion')
endfunction

" TODO redo this
function! s:snr()
  return str2nr(matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_snr$'))
endfunction
let s:sid = printf("\<SNR>%d_", s:snr())

function! matchup#motion_sid()
  return s:sid
endfunction

" }}}1
function! s:text_obj_init_module() " {{{1
  if !g:matchup_text_obj_enabled | return | endif

  call matchup#perf#tic('loading_module')

  for [l:map, l:name, l:opt] in [
        \ ['%', 'delimited', 'delim_all'],
        \]
    let l:p1 = 'noremap <silent> <plug>(matchup-'
    let l:p2 = l:map . ') :<c-u>call matchup#text_obj#' . l:name
    let l:p3 = empty(l:opt) ? ')<cr>' : ', ''' . l:opt . ''')<cr>'
    execute 'x' . l:p1 . 'i' . l:p2 . '(1, 1' . l:p3
    execute 'x' . l:p1 . 'a' . l:p2 . '(0, 1' . l:p3
    execute 'o' . l:p1 . 'i' . l:p2 . '(1, 0' . l:p3
    execute 'o' . l:p1 . 'a' . l:p2 . '(0, 0' . l:p3
  endfor

  nnoremap <silent> <plug>(matchup-double-click)
    \ :<c-u>call matchup#text_obj#double_click()<cr>

  call matchup#perf#toc('loading_module', 'motion')
endfunction

" }}}1
function! s:misc_init_module() " {{{1
  call matchup#perf#tic('loading_module')
  command! MatchupReload          call matchup#misc#reload()
  nnoremap <plug>(matchup-reload) :<c-u>MatchupReload<cr>
  call matchup#perf#toc('loading_module', 'misc')
endfunction

" }}}1

let &cpo = s:save_cpo

" vim: fdm=marker sw=2

