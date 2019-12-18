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
let g:tabulae_evaluated_marker = '`'

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
	" echomsg "DEBUG: b:viewbuf_data = ".b:viewbuf_data
	
	" Iterate over all cell positions (See _itercellpos() ).
	for pos in _itercellpos(b:viewbuf_data['rows'], b:viewbuf_data['cols'])
		" pos := [int, int]
		let evalstatus =  _EvalCell(pos)
	endfor
endfunction

" --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

function _GetCell(pos) 
	""" Returns String of whole cell including all characters and <TAB> (^I)
	""" Example: cell = "#= 123.45^I"
	let line = getline(a:pos[0])
	let row  = split(line, '\t\zs', 1)
	let cell = row[a:pos[1] - 1]
	return cell
endfunction

function _EvalCell(pos)
	""" Gets, evaluates, and sets a cell at position `pos`.
	""" Recursively evaluates if cell is equation with references (TBC).
	" echomsg "DEBUG: pos = ".join(a:pos, ', ')
	
	let cell = _GetCell(a:pos)
	" echomsg "DEBUG: cell = ".cell
	
	" CASE: Cell is empty.
	if cell == "\t"
		return "Empty"

	" CASE: Cell is already evaluated.
	elseif cell[0] == g:tabulae_evaluated_marker
		return "Already Evaluated"
	
	" CASE: Unplanned occurence of preceding whitespace?
	elseif cell[0] == ' '
		return "Error: Unexpected preceding whitespace."
	endif
	
	let [metadata, data] = _SplitCell(cell)
	
	let datatype = _GetDatatype(metadata)
	" echomsg "DEBUG: datatype = ".datatype
	
	" Creating evaluated string.
	if datatype == 'String'
		let eval = '`S: '.data.'	'
	elseif datatype == 'Number'
		let eval = '`N: '.data.'	'
	endif
	
	let status = "Evaluated"
	let setstatus = _SetCell(a:pos, cell, eval)
	return status
endfunction

function _SetCell(pos, cell, eval) 
	execute "%s/".a:cell."/".a:eval."/g"
	return "Cell Set"
endfunction

" --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

function _SplitCell(cell)
	let metadata = split(a:cell)[0]
	
	let data = a:cell[len(metadata):]
	let data = trim(data)
	let data = substitute(data, '\\|', '', 'g')
	
	return [metadata, data]
endfunction

function _GetDatatype(meta)
	if     stridx(a:meta, "'") == 0
		return 'String'
	elseif stridx(a:meta, "#") == 0
		return 'Number'
	else
		return 'Undefined'
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

let &cpo = s:save_cpo
unlet s:save_cpo
