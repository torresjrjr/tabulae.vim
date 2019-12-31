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
		let taebuf = bufname("%") " workbook.tae
	else
		let taebuf = a:taebuf
	endif
	let evalbuf = taebuf.".__eval__" " workbook.tae.eval

	let taebuf_metadata = _parse_taebuf_metadata(taebuf)
	let sheets = taebuf_metadata.sheets 
	" 'books dict', 'orders dict', 'customers dict'
	
	echo "DEBUG: sheets =" sheets
	let viewbufs = []
	for sheet in sheets
		let sheetname = sheet['name']
		let viewbufs += [taebuf.."."..sheetname]
		" workbook.tae.index, workbook.tae.books, workbook.tae.orders.
	endfor
	echo "DEBUG: viewbufs =" viewbufs
	
	" Yank the whole taebuf to the t register, and reset argument list.
	%argdelete
	execute "args "..taebuf
	argdo setlocal bufhidden=hide
	argdo %yank t
	%argdelete
	
	" Creating buffers, with respective grids.
	execute "badd "..evalbuf
	execute "$argadd "..evalbuf
	for viewbuf in viewbufs
		execute "badd "..viewbuf
		execute "$argadd "..viewbuf
	endfor 
	echo "DEBUG: args =" execute("args")
	
	argdo setlocal bufhidden=hide
	" Paste taebuf into viewbufs (argument list).
	argdo put! t 
	" Delete extra line and move cursor to first tab.
	argdo normal Gddgg0f	
	
	execute "$argadd "..taebuf
	
	argdo setlocal nowrap
	argdo setlocal showbreak=`
	argdo setlocal list listchars=eol:¬,tab:>\ \|,nbsp:%
	argdo setlocal cursorline cursorcolumn
	argdo setlocal tabstop=24 softtabstop=0 
	argdo setlocal vartabstop=24 varsofttabstop=0
endfunction

function _UpdateView(viewbuf="")
	" Get viewbuf name.
	if a:viewbuf == ""
		let viewbuf = bufname("%") " workbook.tae.books
	else
		let viewbuf = a:viewbuf
	endif
	
	" Get evalbuf name.
	let evalbuf = join(split(viewbuf, '.')[:-2], '.')..".__eval__"
	
	call _ProcEvalBuf()
	call _ProcViewBuf(viewbuf)
endfunction

" --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

function! _ProcEvalBuf() 
	let save_cursor = getcurpos()
	let b:viewbuf_data = {
\		'rows':line('$'),
\		'cols':len(substitute(getline(1), '[^\t]', '', 'g'))
\	}
	" echomsg "DEBUG: b:viewbuf_data = ".b:viewbuf_data
	
	" Iterate over all cell positions ( See: _itercellpos() ).
	for pos in _itercellpos(b:viewbuf_data['rows'], b:viewbuf_data['cols'])
		" pos := [int, int]
		let currentcell = _ProcEvalCell(pos)
	endfor
	
	call setpos('.', save_cursor)
endfunction

" --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

function _GetCell(pos) 
	""" Returns String of whole cell including all characters and TAB (^I)
	""" Example: cell = "#= 123.45	"
	let line = getline(a:pos[0])
	" echo "DEBUG: line = "..line

	let row  = split(line, '\t\zs', 1)
	" echo "DEBUG: row = "..join(row, ', ')

	let cell = row[a:pos[1] - 1]
	" echo "DEBUG: cell = "..cell
	return cell
endfunction

function _ProcEvalCell(pos)
	""" Gets, evaluates, and sets a cell at position `pos`.
	""" Recursively evaluates if cell is equation with references (TBC).
	" echo "DEBUG: pos = "..join(a:pos, ', ')
	
	let cell = _GetCell(a:pos)
	echo "DEBUG: cell = "..cell
	
	" CASE: Cell is empty.
	if cell == "\t"
		return v:none
	
	" CASE: Unplanned occurence of preceding whitespace?
	elseif cell[0] == " "
		echoerr "Unexpected preceding whitespace."
	endif
	
	let [meta, data] = _SplitCell(cell)
	
	" CASE: Cell is already evaluated.
	if meta[len(meta)-1] != "="
		return cell
	endif
	
	let meta = substitute(meta, '=$', '', '')
	
	" let metadata = _ParseCellMeta(meta)
	" if metadata['equation'] == l
	"	formula = data
	"	data = _EvalFormula(formula)
	
	let datatype = _GetDatatype(meta)
	" echo"DEBUG: datatype = "..datatype
	
	let value = _EvalCellData(meta, data)
	let valuestr = string(value)
	let newcell = meta..' '..valuestr..'	'
	
	let set_cell_status = _SetCell(a:pos, cell, newcell)
	return newcell
endfunction

function _SetCell(pos, oldcell, newcell) 
	""" Sets cell with new content.
	""" Unintentionlly but desireably sets all matching cells, which would
	""" minimise total cell evaluations.
	let oldcell = escape(a:oldcell, "/\*")
	let newcell = escape(a:newcell, "/\*")
	
	execute "%s/"..oldcell.."/"..newcell.."/g"
	return "Cell Set"
endfunction

" --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

function _EvalCellData(meta, data)
	" call _SubstituteAliases(a:data)
	
	let value = eval(a:data)

	" tmp example code.
	" if datatype == 'String'
	" 	let value = '`S:'.data
	" elseif datatype == 'Number'
	" 	let value = '`N:'.data
	" endif
	" tmp end.
	
	return value
endfunction

" --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

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

function _GetCell_depreciated(pos) 
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
	echo "DEBUG: pos = "..join(a:pos, ', ')
	
	let cell = _GetCell(a:pos)
	" echomsg "DEBUG: cell = ".cell
	
	echo "DEBUG: cell = "..cell
	
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

	" let metadata = _ParseCellMeta(meta)
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

function _SetCell_depreciated(pos, cell, eval) 
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

function _ParseCellMeta(meta)
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
	\		{'name':'index'},
	\		{'name':'books'},
	\		{'name':'orders'},
	\	]
	\}
	return metadata
endfunction

" --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

let &cpo = s:save_cpo
unlet s:save_cpo
