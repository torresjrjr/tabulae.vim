" tabulae.vim
" A Vim spreadsheet calculator plugin.
" Version:      0.1.0
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

" FUNCTIONS
"
function _InitBufs(taebuf="")
	""" Initialises buffers for a `.tae` file.
	
	" Creating buffer names.
	" Creating `.tae` file buffer name.
	if a:taebuf == ""
		let taebuf = bufname("%") " workbook.tae
	else
		let taebuf = a:taebuf
	endif
	
	" Creating eval-buffer name.
	let evalbuf = taebuf.".__eval__" " workbook.tae.__eval__
	
	" Extracting file's metadata and getting spreadsheet names.
	let taebuf_metadata = _parse_taebuf_metadata(taebuf)
	let sheets = taebuf_metadata.sheets
	" 'books dict', 'orders dict', 'customers dict'
	
	call DEBUG('_InitBufs', 'sheets', sheets)
	
	" Creating view-buffer names for each spreadsheet.
	let viewbufs = []
	for sheet in sheets
		let sheetname = sheet['name']
		let viewbufs += [taebuf.."."..sheetname]
		" workbook.tae.index, workbook.tae.books, workbook.tae.orders.
	endfor
	call DEBUG('_InitBufs', 'viewbufs', viewbufs)
	
	" All necessary buffer names are now created.
	
	" Yank the whole taebuf to the t-register, and reset argument list.
	%argdelete
	execute "argadd "..taebuf
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
	call DEBUG('_InitBufs', 'execute("args")', execute("args"))
	
	" Settings which apply to relevant buffers except .tae file:
	argdo setlocal buftype=nofile
	argdo setlocal bufhidden=hide
	argdo setlocal noswapfile
	" Paste taebuf into evalbuf & viewbufs (argument list).
	argdo put! t
	" Delete extra line and move cursor to first tab.
	argdo normal Gddgg0f	
	
	" Add .tae file to argument list.
	execute "$argadd "..taebuf
	
	" Settings which now apply to all relevant buffers:
	argdo setlocal nowrap
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
	
	call _ProcEvalBuf(evalbuf)
	call _ProcViewBuf(viewbuf)
endfunction

" --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

function _ProcEvalBuf(bufname='')
	let save_cursor = getcurpos()
	
	if a:bufname == ''
		let bufname = bufname()
	else
		let bufname = a:bufname
	endif
	
	let buf_data = {
\		'rows':line('$'),
\		'cols':len(substitute(getline(1), '[^\t]', '', 'g'))
\	}
	call DEBUG('_ProcEvalBuf', 'buf_data', buf_data)
	
	" Iterate over all cell positions [ See: _itercellpos() ].
	for pos in _itercellpos(buf_data['rows'], buf_data['cols'])
		" pos := [int, int]
		let [cell, meta, data] = _ProcEvalCell(bufname, pos)
	endfor
	
	call setpos('.', save_cursor)
endfunction

" --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

function _GetCell(bufname, pos)
	""" Returns String of whole cell including all characters and TAB (^I)
	""" Example: cell = "#= 123.45	"
	let line = getbufline(a:bufname, a:pos[0])[0]
	" call DEBUG('_GetCell', 'line', line)
	
	let row  = split(line, '\t\zs', 1)
	" call DEBUG('_GetCell', 'row', row)
	
	let cell = row[a:pos[1] - 1]
	" call DEBUG('_GetCell', 'cell', cell)
	return cell
endfunction


function _ProcEvalCell(bufname, pos)
	""" Gets, evaluates, and sets a cell at position `pos`.
	""" Recursively evaluates if cell is equation with references (TBC).
	
	call DEBUG('_ProcEvalCell', 'a:bufname', a:bufname)
	call DEBUG('_ProcEvalCell', 'a:pos', a:pos)
	
	let cell = _GetCell(a:bufname, a:pos)
	call DEBUG('_ProcEvalCell', 'cell', cell)
	
	" CASE: Cell is empty.
	if cell == "\t"
		return v:none
	
	" CASE: Unplanned occurence of preceding whitespace?
	elseif cell[0] == " "
		echoerr "Unexpected preceding whitespace."
	endif
	
	let [meta, data] = _SplitCell(cell)
	
	" CASE: Cell is already evaluated.
	let is_already_evaluated = meta[len(meta)-1] != "="
	if is_already_evaluated
		return [cell, meta, data]
	endif
	
	let newmeta = substitute(meta, '=$', '', '')
	
	" let metadata = _ParseCellMeta(newmeta)
	" if metadata['equation'] == l
	"	formula = data
	"	data = _EvalFormula(formula)
	
	let datatype = _GetDatatype(newmeta)
	" call DEBUG('_ProcEvalCell', 'datatype', datatype)
	
	
	let value = _EvalCellData(a:bufname, a:pos, newmeta, data)
	" call DEBUG('_ProcEvalCell', 'value', value)
	
	let valuestr = string(value)
	let newcell = newmeta..' '..valuestr..'	'
	
	let set_cell_status = _SetCell(a:bufname, a:pos, newcell)
	echo set_cell_status
	
	return [newcell, newmeta, value]
endfunction


function _SetCell(bufname, pos, newcell)
	""" Sets cell with new content.
	
	" call DEBUG('_SetCell', 'a:pos', a:pos)
	" call DEBUG('_SetCell', 'a:newcell', a:newcell)
	
	let l:before_line = getbufline(bufnr(a:bufname), a:pos[0])[0]
	" call DEBUG('_SetCell', 'l:before_line', l:before_line)
	
	let l:row = split(before_line, '\t\zs', 1)
	" call DEBUG('_SetCell', 'l:row', l:row)
	
	let l:row[ a:pos[1] - 1 ] = a:newcell
	" call DEBUG('_SetCell', 'l:row', l:row)
	
	let l:after_line = join(row, '')
	" call DEBUG('_SetCell', 'l:after_line', l:after_line)
	
	call setbufline(bufnr(a:bufname), a:pos[0], after_line)
	
	return "Cell ["..a:newcell.."] Set."
endfunction

" --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

function _EvalCellData(bufname, pos, meta, data)
	""" Evaluates the data of a cell formula.
	""" Will handle cell addresses.

	" While Loop: whilst there are unevaluated addresses present:
		" Section: Convert next (first in string) Relative Addresses to an Absolute Addresses.
		" Section: Call _ProcEvalCell() on Absolute Address.
		" Section: Replace that Address with value.
	
	let data = ' '..a:data..' ' " Padded so regex in matchstrpos() works later.
	
	let rel_addr_regex = '[^\\]\zs{\(+\|-\|\)\d\+,\(+\|-\|\)\d\+}' " Example: {3,-5}
	let abs_range_regex = '[^\\]\zs[A-Z]\+[0-9]\+:[A-Z]\+[0-9]\+' " Example: A1:C3
	let abs_addr_regex = '[^\\]\zs[A-Z]\+[0-9]\+' " Example: A1
	
	
	" Process loop. Loops through matches in order of importance.
	while v:true
		call DEBUG('_EvalCellData', 'data', data)
		
		
		""" First, evaluate relative addresses as they come.
		let [rel_str, A, B] = matchstrpos(data, rel_addr_regex)
		if A != -1
			" Evaluate relative address here. Then `continue`.
			echo "Processing Relative Address: "..rel_str
			" ...
			continue
		endif
		
		
		""" Second, evaluate absolute address ranges as they come.
		let [abr_str, A, B] = matchstrpos(data, abs_range_regex)
		if A != -1
			" Evaluate absolute address range here. Then `continue`.
			echo "Processing Absolute Address Range: "..abr_str
			" ...
			continue
		endif
		
		
		""" Third, evaluate absulute addresses as they come.
		"   Calls `_ProcEvalCell()`.
		let [abs_str, A, B] = matchstrpos(data, abs_addr_regex)
		if A != -1
			" Evaluate absolute address here. Then `continue`.
			" First, get pos variable.
			echo "Processing Absolute Address: "..abs_str
			let col_str = matchstr(abs_str, '[A-Z]\+')
			let row_str = matchstr(abs_str, '[0-9]\+')
			
			let col_tmp = str2list(col_str)->reverse()
			let col_tmp = map(col_tmp, { i, v -> pow(26, i)*(v-64) })
			let col_num = join(col_tmp, '+')->eval()->float2nr()
			
			let row_num = str2nr(row_str)
			
			let ref_pos = [row_num, col_num]
			" call DEBUG('_EvalCellData', 'ref_pos', ref_pos)
			
			" GET cell value at reference position.
			let processed_eval_cell = _ProcEvalCell(a:bufname, ref_pos)
			" call DEBUG('_EvalCellData', 'processed_eval_cell', processed_eval_cell)
			
			let [ref_cell, ref_meta, ref_val] = processed_eval_cell
			" call DEBUG('_EvalCellData', 'ref_val', ref_val)
			
			let ref_val_str = string(ref_val)
			
			" CHANGE absolute address to referenced value
			let data = substitute(data, abs_str, ref_val_str, '')
			" call DEBUG('_EvalCellData', 'data', data)
			
			continue
		endif
		
		break
	endwhile
	
	
	let value = eval(data)
	call DEBUG('_EvalCellData', 'value', value)
	
	return value
endfunction

" --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

function _ProcViewBuf(bufname='')
	let save_cursor = getcurpos()
	
	if a:bufname == ''
		let bufname = bufname()
	else
		let bufname = a:bufname
	endif
	
	let buf_data = {
\		'rows':line('$'),
\		'cols':len(substitute(getbufline(bufname, 1)[0], '[^\t]', '', 'g'))
\	}
	call DEBUG('_ProcEvalBuf', 'buf_data', buf_data)
	
	" Iterate over all cell positions [ See: _itercellpos() ].
	for pos in _itercellpos(buf_data['rows'], buf_data['cols'])
		" pos := [int, int]
		let currentcell = _ProcViewCell(bufname, pos)
	endfor
	
	call setpos('.', save_cursor)
endfunction

" --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

" IN PROGRESS
function _ProcViewCell(bufname, pos)
	""" Gets, evaluates, and sets a cell at position `pos`.
	""" Recursively evaluates if cell is equation with references (TBC).
	
	call DEBUG('_ProcViewCell', 'a:bufname', a:bufname)
	call DEBUG('_ProcViewCell', 'a:pos', a:pos)
	
	let cell = _GetCell(a:bufname, a:pos)
	call DEBUG('_ProcViewCell', 'cell', cell)
	
	" CASE: Cell is empty.
	if cell == "\t"
		return v:none
	endif
	
	let [meta, data] = _SplitCell(cell)
	call DEBUG('_ProcViewCell', 'meta', meta)
	call DEBUG('_ProcViewCell', 'data', data)
	
	let newmeta = meta
	
	" let newmeta = substitute(meta, '=$', '', '')
	
	" let metadata = _ParseCellMeta(newmeta)
	" if metadata['equation'] == l
	"	formula = data
	"	data = _EvalFormula(formula)
	
	" let datatype = _GetDatatype(newmeta)
	" call DEBUG('_ProcViewCell', 'datatype', datatype)
	
	" " Commented out for now.
	" let value = _EvalCellData(a:bufname, a:pos, newmeta, data)
	" call DEBUG('_ProcViewCell', 'value', value)
	
	let value = data " For now, this, for testing.
	
	" let valuestr = string(value)
	let valuestr = value
	call DEBUG('_ProcViewCell', 'valuestr', valuestr)
	
	let newcell = valuestr..'	'
	call DEBUG('_ProcViewCell', 'newcell', newcell)
	
	" " Or maybe something like this:
	" let newcell = hlA..valuestr..'	'..hlB
	" " To create highlighting/concealing/formatting easier.
	
	let set_cell_status = _SetCell(a:bufname, a:pos, newcell)
	echo set_cell_status
	
	return [newcell, newmeta, value]
endfunction

" --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
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
\		[
\			{'name':'index'},
\			{'name':'books'},
\			{'name':'orders'},
\		]
\	}
	return metadata
endfunction

" --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
" TEMPORARY DEBUGGING TOOLS

function DEBUG(func_name, var_name, var)
	echo "DEBUG: "..a:func_name.."(): "..a:var_name.." = "..string(a:var)
endfunction

nnoremap U <C-r>

" --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

let &cpo = s:save_cpo
unlet s:save_cpo
