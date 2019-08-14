
if exists("g:loaded_svnlog") || &cp
	finish
endif
let g:loaded_svnlog = 1

scriptencoding utf-8

function! svnlog#log(limit)
	if !empty(a:limit)
		let svnCommand = 'svn log -v --limit ' .a:limit
    else
		let svnCommand = 'svn log -v --limit 200' 
	endif
	let s:logs = s:GetLogs(svnCommand)

	"Create ui to show the date
	call s:InitWindow()
endfunction

function! s:InitWindow()
    if !exists("s:svnlog_init")
        let s:svnlog_init = 1
        "create windows 
        exe 'tabnew __Comments__'
        exe 'silent keepalt botright split __LogList__'
        exe 'silent keepalt botright split __Modify__'

        "set window arrtrbute 
        call s:InitCommentsWindow()
        call s:InitLogWindow()
        call s:InitModifyWindow()
    endif

	"show data
	call s:ShowLog()
	call s:ShowComments(0)
	call s:ShowModify(0)

	"move focus to logs window
	call s:GotoLogWindow()
endfunction

function! s:SetWindowAttribute()
    setlocal noreadonly " in case the "view" mode is used
    setlocal buftype=nofile
    setlocal bufhidden=delete
    setlocal noswapfile
    setlocal nobuflisted
    setlocal nolist
    setlocal nowrap
    setlocal winfixwidth
    setlocal textwidth=0
    setlocal nospell
endfunction

function! s:InitCommentsWindow()
	call s:GotoCommentsWindow()
	call s:SetWindowAttribute()
	exe 'resize 4'
endfunction

function! s:InitLogWindow()
	call s:GotoLogWindow()
	call s:SetWindowAttribute()
	augroup ShowCommentsAndModify
		autocmd!
		autocmd CursorMoved <buffer> :call s:ShowCommentsAndModify()
	augroup END
endfunction

function! s:InitModifyWindow()
	call s:GotoModifyWindow()
	call s:SetWindowAttribute()
    nnoremap <buffer> <cr> :call <SID>ShowDiff()<cr>
endfunction

function! s:ShowDiff()
	"get current version and preversion
	call s:GotoLogWindow()
	let position = line('.')
	let curVersion = s:GetVersion(position)
	let preVersion = s:GetVersion(position + 1)

	"get modify path
	call s:GotoModifyWindow()
	let line = getline('.')
	let path = strpart(line, 2, len(line))

	"call svn diff
	let diffcmd = '!svn diff "' .s:GetRealPath(path) .'" -r ' .preVersion .':' .curVersion 
	call g:VimDebug('diff cmd = ' .diffcmd)
	exec diffcmd
endfunction

function! s:GetRealPath(path)
	let svnRootPath = s:FindRoot()
	call g:VimDebug('svn root path  = '.svnRootPath)
    return svnRootPath .a:path

endfunction

function! s:GetVersion(index)
	let line = getline(a:index)
	let tmpList = split(line, '|')
	let l:version = g:StringTrim(get(tmpList, 0))
	let l:version = strpart(l:version, 1, len(l:version))
	let l:version = str2nr(l:version)
	return l:version
endfunction

function! s:GotoLogWindow()
	exe '2wincmd k'
	exe 'wincmd j'
endfunction

function! s:GotoCommentsWindow()
	exe "2wincmd k"
endfunction

function! s:GotoModifyWindow()
	exe "2wincmd j"
endfunction

function! s:ShowCommentsAndModify()
	let index = line('.') - 1
	call s:ShowComments(index)
	call s:ShowModify(index)
	"move to logs window
	call s:GotoLogWindow()
endfunction

function! s:ShowComments(index)
	"goto comments window
	call s:GotoCommentsWindow()
	"clear window
	exe '0,$ delete'
	"set comments
	let log = get(s:logs, a:index)
	let i = 1
	for comment in log.comments
		call setline(i, comment)
		let i = i+1
	endfor
endfunction

function! s:ShowLog()
	call s:GotoLogWindow()
	exe '0,$ delete'
	let i = 1
	for log in s:logs
		call setline(i, log.base)
		let i = i+1
	endfor
endfunction

function! s:ShowModify(index)
	"goto modify window
	call s:GotoModifyWindow()
	"clear window
	exe '0,$ delete'
	let log = get(s:logs, a:index)
	"show modify
	let i = 1
	for modify in log.modify
		call setline(i, modify)
		let i = i+1
	endfor
endfunction

let s:LogInfo = {}
let s:LogInfo.base = ''
let s:LogInfo.comments = []
let s:LogInfo.modify = []

function! s:LogInfo()
	let temp = {}
	let temp.base = ''
	let temp.comments = []
	let temp.modify = []
	return temp
endfunction

function! s:FormatLog(msg)
    let msgList = split(a:msg, "|")
    let author = msgList[1]
    let rest = 18 - len(author)
    while rest > 0
        let author = author ." "
        let rest = rest - 1
    endwhile

    let msgList[1] = author
    return join(msgList, " | ") 
endfunction

function! s:GetLogs(svnCommand)
	let output = system(a:svnCommand)
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
            let strend = stridx(line, "+0800", 0)
			let log.base = strpart(line, 0, strend)
            let log.base = s:FormatLog(log.base)
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
			if len(log.comments) == 0
                let log.base = log.base . "  |  " .line
			else
                let log.base = log.base . "; " .line
			endif

			call add(log.comments, line)
			continue
		endif

	endfor

	return logs
endfunction

function! s:FindRoot()
	let output = system('svn info')
	let infoList = split(output, '\n')
    for line in infoList
        if stridx(line, "Repository Root", 0) >=0 || stridx(line, "版本库根", 0) >=0
            let strstart = stridx(line, "http", 0)
            let root = strpart(line, strstart, len(line)) 
            let root = g:StringTrim(root)
            return root
        endif
    endfor
endfunction
