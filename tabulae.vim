" tabulae.vim
" Author:       Byron Torres <http://t.me/torresjrjr/>
" Version:      1.0.0

if exists("g:loaded_tabulae") || &cp || v:version < 700
  finish
endif
let g:loaded_tabulae = 1


" VARIABLES


" FUNCTIONS

function! _Make_clean_tae()
	let filepath = bufname()
	let viewfilepath = bufname().'.clean'
	execute('new '.viewfilepath)
	execute('read '.filepath)

	:%s/^#.*//
	:g/^$/d
	sort

	write
endfunction


function! _Make_eval_tae()
	let filepath = bufname()
	let viewfilepath = bufname().'.eval'
	execute('new '.viewfilepath)
	execute('read '.filepath)

	:g/. . = .*/_EvaluateNumericCell

	write
endfunction


function! _Make_view()
	let filepath = bufname()
	let viewfilepath = bufname().'.view'
	execute('new '.viewfilepath)
	execute('read '.filepath)

	:%s/^#.*//
	:g/^$/d
	sort
endfunction

function _Evaluate_numeric_cell()
	let cell = getline(curpos()[2])
	let cellcontents = split(cell)[3]
	echo cellcontents
endfunction


command EvaluateNumericCell :call _Evaluate_numeric_cell()
