
" Create a command to directly call the new search type
command! -nargs=? SVNLog call svnlog#log(<q-args>)
