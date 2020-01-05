" tests.vim
" A script to run abitrary tests on tabulae.vim and it's functionalities.

source ./plugin/tabulae.vim

" === === === === === === === ===

fu Test_A()
	call _InitView()
	call _EvalView()
endfu


fu Test_B()
	call _InitBufs()
endfu


fu Test_C()
	call _InitBufs()
	call _ProcEvalBuf()
endfu


fu Test_D()
	call _InitBufs()
	
	buffer basic.tae.__eval__
	
	call _ProcEvalBuf()
	
	%yank v
	bunload basic.tae.index
	buffer  basic.tae.index
	put v
	norm ggddgg
	
	call _ProcViewBuf()
endfu

" === === === === === === === ===

call Test_D()
