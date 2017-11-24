" =============================================================================
" Filename: autoload/cursorword.vim
" Author: itchyny
" License: MIT License
" Last Change: 2017/05/10 21:23:15.
" =============================================================================

let s:save_cpo = &cpo
set cpo&vim

let s:priority = -1 	"-1 or it overrules hlsearch

function! cursorword#highlight() abort
  if !get(g:, 'cursorword_highlight', 1) | return | endif
  highlight CursorWord0 term=underline cterm=underline gui=underline
  redir => out | silent! highlight CursorLine | redir END "needed to match char under cursor properly when cursorline is on...
  let highlight = 'highlight CursorWord1 term=underline cterm=underline gui=underline'
  execute highlight matchstr(out, 'ctermbg=#\?\w\+') matchstr(out, 'guibg=#\?\w\+')
endfunction

let s:alphabets = '^[\x00-\x7f\xb5\xc0-\xd6\xd8-\xf6\xf8-\u01bf\u01c4-\u02af\u0370-\u0373\u0376\u0377\u0386-\u0481\u048a-\u052f]\+$'

function! cursorword#update() abort
	if exists('s:deferred') | call timer_stop(s:deferred) | unlet s:deferred | endif
  let w:enable = get(b:, 'cursorword', get(g:, 'cursorword', 1)) && !has('vim_starting')
  if !w:enable && !get(w:, 'cursorword_match') | return | endif

	let s:deferred = timer_start(&updatetime, function('cursorword#matchadd'))
endfunction

function! cursorword#matchadd(...) abort
  let line = getline('.')
  let w:linenr = line('.')
  let word = matchstr(line[:(col('.')-1)], '\k*$') . matchstr(line[(col('.')-1):], '^\k*')[1:]
  if get(w:, 'cursorword_state', []) ==# [ w:linenr, word, w:enable ] | return | endif
  let w:cursorword_state = [ w:linenr, word, w:enable ]
  silent! call matchdelete(w:cursorword_id0)
  silent! call matchdelete(w:cursorword_id1)
  let w:cursorword_match = 0
  if !w:enable || word ==# '' || len(word) !=# strchars(word) && word !~# s:alphabets | return | endif
  let w:pattern = '\<' . escape(word, '~"\.^$[]*') . '\>'
  let w:cursorword_id0 = matchadd('CursorWord0', w:pattern, s:priority)
  let w:cursorword_id1 = matchadd('CursorWord' . &l:cursorline, '\%' . w:linenr . 'l' . w:pattern, s:priority)
  let w:cursorword_match = 1

	" call cursorword#blink()
endfunction

function! cursorword#blink(...) abort
  silent! call matchdelete(w:cursorword_id0)
  silent! call matchdelete(w:cursorword_id1)
	call timer_start(200, function('s:blink_callback'))

endfunction

function! s:blink_callback(...) abort
  let w:cursorword_id0 = matchadd('CursorWord0', w:pattern, -1)
  let w:cursorword_id1 = matchadd('CursorWord' . &l:cursorline, '\%' . w:linenr . 'l' . w:pattern, -1)
endfunction

if !has('vim_starting')
  call cursorword#highlight()
endif

let &cpo = s:save_cpo
unlet s:save_cpo
