" tabulae.vim
" A Vim spreadsheet calculator plugin.
" Version:      0.0.0
" Last Changed: 2019 Dec 18
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
"
function _InitBufs(taebuf="")
	" Creating buffer names.
	if a:taebuf == ""
		let taebuf  = bufname("%") " workbook.tae
	else
		let taebuf = a:taebuf
	endif
	let evalbuf = taebuf."eval" " workbook.tae.eval

	let taebuf_metadata = parse_taebuf_metadata(taebuf)
	let sheets = taebuf_metadata.sheets 
	" 'books', 'orders', 'customers'
	
	let viewbufs = []
	for sheet in sheets
		let sheetname = sheet.name
		let viewbufs += taebuf..sheetname
		" workbook.tae.index, workbook.tae.books, workbook.tae.orders.
	endfor
	
	" Yank the whole taebuf to the t register, and reset argument list.
	execute "args "..taebuf
	argdo %yank t
	%argdelete
	
	" Creating buffers, with respective grids.
	execute "badd "..evalbuf
	for viewbuf in viewbufs
		execute "badd "..viewbuf
		execute "$argadd "..viewbuf
	endfor 
	
	" Paste taebuf into viewbufs (argument list).
	argdo put! t 
	" Delete extra line and move cursor to first tab.
	argdo normal Gddgg0f	
	argdo setlocal bufhidden=hide
	argdo setlocal nowrap
	argdo setlocal showbreak=`
	argdo setlocal list listchars=eol:¬,tab:>\ \|,nbsp:%
	argdo setlocal cursorline cursorcolumn
	argdo setlocal tabstop=24 softtabstop=0 
	argdo setlocal vartabstop=24,12,18,18,24 varsofttabstop=0 " HARDCODED
endfunction

function _UpdateBufs()
	call copy_taebuf_to_evalbuf()
	call process_evalbuf()
	call update_viewbufs()
endfunction


function! _InitView()
	set bufhidden=hide
	let b:tcur = {'x':1, 'y':1} " .tae buffer cursor data.
	let taebuf = bufname("%")
	let viewbuf = taebuf.".view"
	
	execute "badd ".viewbuf
	%yank t
	execute "buffer ".viewbuf
	put! t
	
	" Delete extra line and move cursor to first tab.
	normal Gddgg0f	
	let b:vcur = {'x':1, 'y':1} " .tae.view buffer cursor data.
	set bufhidden=hide
	set showbreak=`
	set list listchars=eol:¬,tab:>\ \|,nbsp:%
	set cursorline cursorcolumn
	setlocal tabstop=24 softtabstop=0 
	
	" HARDCODED
	setlocal vartabstop=24,12,18,18,24
endfunction

function! _EvalView() 
	let save_cursor = getcurpos()
	let b:viewbuf_data = {
\		'rows':line('$'),
\		'cols':len(substitute(getline(1), '[^\t]', '', 'g'))
\	}
	" echomsg "DEBUG: b:viewbuf_data = ".b:viewbuf_data
	
	" Iterate over all cell positions ( See: _itercellpos() ).
	for pos in _itercellpos(b:viewbuf_data['rows'], b:viewbuf_data['cols'])
		" pos := [int, int]
		let currentcell =  _EvalCell(pos)
	endfor

	call setpos('.', save_cursor)
endfunction

" --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

function _GetCell(pos) 
	""" Returns String of whole cell including all characters and TAB (^I)
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
		return 0

	" CASE: Cell is already evaluated.
	elseif cell[0] == g:tabulae_evaluated_marker
		return cell[1:]
	
	" CASE: Unplanned occurence of preceding whitespace?
	elseif cell[0] == ' '
		echoerr "Unexpected preceding whitespace."
	endif
	
	let [meta, data] = _SplitCell(cell)

	" let metadata = _ParseMetadata(meta)
	" if metadata['equation'] == l
	"	formula = data
	"	data = _EvalFormula(formula)
	
	let datatype = _GetDatatype(meta)
	" echomsg "DEBUG: datatype = ".datatype
	
	" Creating evaluated string.
	if datatype == 'String'
		let eval = '`S:'.data.'	'
	elseif datatype == 'Number'
		let eval = '`N:'.data.'	'
	endif
	
	let status = "Evaluated"
	let setstatus = _SetCell(a:pos, cell, eval)
	return status
endfunction

function _SetCell(pos, cell, eval) 
	""" Sets cell with new content.
	""" Unintentionlly but desireably sets all matching cells, which would
	""" minimise total cell evaluations.
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

function _EvalFormula(formula)
	" let expformula = _ExpandFormula(a:formula)
	" 
	" eval = execute(expformula)
	" return eval
endfunction

function _ParseMetadata(meta)
	let meta = {}
	
	for i in range(len(a:meta))
		let char = a:meta[i]
		
		if i == 0
			if _CheckParsedDatatype(char)
				let meta['datatype'] = char
				continue
			else
				echoerr "Metadata datatype char unrecognised."
			endif
		endif 
	endfor 
endfunction

function _GetDatatype(meta)
	if     stridx(a:meta, "'") == 0
		return 'String'
	elseif stridx(a:meta, "#") == 0
		return 'Number'
	else
		return 'Undefined'
	endif
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

function _parse_taebuf_metadata(taebuf)
	let metadata = {'sheets':
	\	[
	\		{'name':'index'}
	\	]
	\}
	return metadata
endfunction

" --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

let &cpo = s:save_cpo
unlet s:save_cpo
