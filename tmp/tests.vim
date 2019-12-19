" tests.vim
" A script to run abitrary tests on tabulae.vim and it's functionalities.

source ./plugin/tabulae.vim

" === === === === === === === ===

fu TestA()
	call _InitView()
	call _EvalView()
endfu

" === === === === === === === ===

call TestA()
