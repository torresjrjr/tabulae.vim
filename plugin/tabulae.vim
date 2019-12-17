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

" FUNCTIONS

function! _InitView()
	set bufhidden=hide
	let b:tcur = {'x':1, 'y':1} " .tae buffer cursor data.
	let taebuf = bufname("%")
	let viewbuf = taebuf.".view"
	
	execute "badd ".viewbuf
	%yank t
	
	execute "buffer ".viewbuf
	" Paste taebuf content into viewbuf.
	put! t
	" Delete extra line and move cursor to first tab.
	normal Gddgg0f	
	let b:vcur = {'x':1, 'y':1} " .tae.view buffer cursor data.
	set bufhidden=hide | setlocal tabstop=24 softtabstop=0 
	set showbreak=`
	set list listchars=eol:¬,tab:>\ \|,nbsp:%
	set cursorline cursorcolumn
endfunction

function! _EvalView() 
	let b:viewbuf_data = {
\		'rows':line('$'),
\		'cols':len(substitute(getline(1), '[^\t]', '', 'g'))
\	}
	echomsg b:viewbuf_data
	
	" Iterate over all cell positions (See _itercellpos() ).
	for pos in _itercellpos(b:viewbuf_data['rows'], b:viewbuf_data['cols'])
		" pos := [int, int]
		let cell = _GetCell(pos)
		let evalcell = _EvalCell(pos, cell)
		call _SetCell(cell, evalcell)
	endfor
endfunction

" --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

function _GetCell(pos) 
	" Returns String of whole cell including all characters and <TAB>
	let line = getline(a:pos[0])
	let row  = split(line, '\t\zs')
	let cell = row[a:pos[1] - 1]
	return cell
endfunction

function _EvalCell(pos, cell)
	let datatype = _GetDatatype(a:cell)
	if datatype == 'String'
		return 'String'.a:cell
	elseif datatype == 'Number'
		return 'Number'.a:cell
	endif
	return "DEFAULT_EVAL"
endfunction

function _SetCell(cell, newcell) 
	execute "%s/".a:cell."/".a:newcell."/g"
endfunction

" --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

function _GetDatatype(cell)
	if a:cell == "\t"
		return 'Empty'
	endif
	let meta = split(a:cell)[0]
	if stridx(meta, "'") != -1
		let datetype = 'String'
	elseif stridx(meta, "#") != -1
		let datetype = 'Number'
	endif
	return datetype
endfunction

function _Evaluate_numeric_cell()
	let cell = getline(curpos()[2])
	let cellcontents = split(cell)[3]
	echo cellcontents
endfunction

command EvaluateNumericCell :call _Evaluate_numeric_cell()

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

let &cpo = s:save_cpo
unlet s:save_cpo
