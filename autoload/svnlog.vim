
if exists("g:loaded_svnlog") || &cp
	finish
endif
let g:loaded_svnlog = 1

scriptencoding utf-8

function! svnlog#log(path)
	echo 'call svnlog...'
	echo 'path = ' .a:path
endfunction
