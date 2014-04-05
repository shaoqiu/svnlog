
if exists("g:loaded_svnlog") || &cp
	finish
endif
let g:loaded_svnlog = 1

scriptencoding utf-8

function! svnlog#log(path)
	if !empty(a:path)
		let svnCommand = 'svn log ' .a:path .' -v'
	else
		let svnCommand = 'svn log -v'
	endif

	let s:logs = s:getLogs(svnCommand)

	"Create ui to show the date
	for log in s:logs
		call g:VimDebug('base = ' .log.base)
		call g:VimDebug('comments = ' .log.comments)
		for modify in log.modify
			call g:VimDebug("\t" .modify)
		endfor
	endfor
endfunction

let s:LogInfo = {}
let s:LogInfo.base = ''
let s:LogInfo.comments = ''
let s:LogInfo.modify = []
function! s:LogInfo()
	let temp = {}
	let temp.base = ''
	let temp.comments = ''
	let temp.modify = []
	return temp
endfunction

function! s:getLogs(svnCommand)
	let output = system(a:svnCommand)
	"exec '!svn diff svnlog.vim -r 1:2'
	let logs = []
	let log = s:LogInfo()
	let status = 'base'
	"remove fisrt line '----------------'
	let logList = split(output, "\n")
	call remove(logList, 0)
	for line in logList
		let line = g:StringTrim(line)
		call g:VimDebug('line = ' .line)
		if match(line, '--------------') == 0
			"a log end
			call add(logs, log)
			let status = 'base'
			let log = s:LogInfo()
			continue
		endif

		if line == ''
			let status = 'comments'
			continue
		endif

		if status == 'base'
			let log.base = line
			let status = 'changePrompt'
			continue
		endif

		if status == 'changePrompt'
			let status = 'modify'
			continue
		endif

		if status == 'modify'
			call add(log.modify, line)
			continue
		endif

		if status == 'comments'
			if log.comments == ''
				let log.comments = line
			else
				let log.comments = log.comments ."\n" .line
			endif
			continue
		endif

	endfor

	return logs
endfunction
