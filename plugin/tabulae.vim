" tabulae.vim
" A Vim spreadsheet calculator plugin.
" Version:      0.0.0
" Last Changed: 2019 Dec 17
" Author:       Byron Torres <http://t.me/torresjrjr/>
" License:      This file is placed in the public domain.

if exists("g:loaded_tabulae") || &cp || v:version < 700
  finish
endif
let g:loaded_tabulae = 1 
let s:save_cpo = &cpo
set cpo&vim


" ### NOTE ###
" This version is a very early draft. This will change soon.

" OPTIONS
setlocal tabstop=24 softtabstop=0

" VARIABLES
let s:tcur = {'x':1, 'y':1} " .tae buffer cursor data.
let s:vcur = {'x':1, 'y':1} " .tae.view buffer cursor data.

" FUNCTIONS

function! _InitView()
	set bufhidden=hide
	let taebuf = bufname("%")
	let viewbuf = taebuf.".view"
	execute "badd ".viewbuf
	%yank t
	execute "args ".viewbuf
	argdo set bufhidden=hide | normal "tP
	execute "hide buffer ".taebuf
endfunction

function! _EvalView() 
"	let viewbuf_data = {
"		'rows':get_rows(),
"		'cols':get_cols()
"	}

	" HARDCODED
	let viewbuf_data = {
		'rows':5,
		'cols':4
	}

	for cellpos in itercellpos(rows, cols)
		let cell = _GetCell(cellpos)
		let celldata = _EvalCell(cell)
		call _SetCell(cellpos, cell)
	endfor
endfunction

" --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

function _itercellpos(nrows, ncols)
	" Returns a list of coordinates of a spreadsheet of size nrows and ncols.
	" (3,2) -> [  [1,1],[1,2],
	"             [2,1],[2,2],
	"             [3,1],[3,2]  ]
	let cellposlist = []
	for nrow in range(1, a:nrows)
		for ncol in range(1, a:ncols)
			let cellposlist += [[nrow, ncol]]
		endfor
	endfor
	return cellposlist
endfunction

" --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

function _GetCell(cellpos) 
	return "DEFAULT_DATA"
endfunction

function _EvalCell(cell)
	let datatype = _GetDatatype(cell)
	return "DEFAULT_EVAL"
endfunction

function _Evaluate_numeric_cell()
	let cell = getline(curpos()[2])
	let cellcontents = split(cell)[3]
	echo cellcontents
endfunction


command EvaluateNumericCell :call _Evaluate_numeric_cell()


let &cpo = s:save_cpo
unlet s:save_cpo
