"============================================================================"
"
"  Vim File Synchronization
"
"  Copyright (c) Cosmin Popescu
"
"  Author:      Cosmin Popescu <cosminadrianpopescu at gmail dot com>
"  Version:     1.00 (2014-12-07)
"  Requires:    Vim 7
"  License:     GPL
"
"  Description:
"
"  Vim provides a file synchronization for vim
"
"============================================================================"

function! sync#filename(f)
    let result = a:f
    if (matchstr(a:f, '\v^(\/|\~)', 'g') == '')
        let result = getcwd() . '/' . a:f
    endif

    return result
endfunction

function! sync#path(p)
    let result = sync#filename(a:p)
    return fnamemodify(result, ':p:h')
endfunction

function! sync#add_custom_function(source, dest, func)
    call sync#add(a:source, a:dest, 'f:' . a:func)
endfunction

function! sync#add(source, dest, command, ...)
    let pars = ''
    if a:0
        let pars = a:1
    endif
    let comm = a:command
    if a:command == ''
        let comm = g:sync_default_command
    elseif matchstr(comm, '\v^f:') != ''
        let comm = 'func'
        let pars = substitute(a:command, '\v^f:', '', 'g')
    endif
    let source = sync#path(a:source)

    call add(g:Sync, {'source': source, 'dest': a:dest, 'command': comm, 'params': pars, 'active': 1})
    call sync#save_session()
endfunction

function! s:check_sync_index(idx)
    if (a:idx > len(g:Sync) || a:idx < 1)
        echoerr "There is no active sync with that index. See the active sync list (:ActiveSyncList <cr>)" 
        return 0
    endif
    return 1
endfunction

function! sync#remove(idx)
    if s:check_sync_index(a:idx)
        unlet g:Sync[a:idx - 1]
    endif
    ""let i = 0
    ""let source = sync#path(a:source)
    ""while i < len(g:Sync)
    ""    if (g:Sync[i].source == source)
    ""        unlet g:Sync[i]
    ""    else
    ""        let i = i + 1
    ""    endif
    ""endwhile
    call sync#save_session()
endfunction

function! s:sync_enable_disable(idx, val)
    if (s:check_sync_index(a:idx))
        let g:Sync[a:idx - 1].active = a:val
    endif
    call sync#save_session()
endfunction

function! sync#enable(idx)
    call s:sync_enable_disable(a:idx, 1)
endfunction

function! sync#disable(idx)
    call s:sync_enable_disable(a:idx, 0)
endfunction

function! sync#execute()
    let path = fnamemodify(@%, ':p:h')
    let filename = fnamemodify(@%, ':p')
    for i in g:Sync
        if i.active
            if (matchstr(path, '^' . substitute(i.source, '\/', "\\\/", 'g')) != '')
                let dest = substitute(filename, i.source, '', 'g')
                "let dest = substitute(dest, '\v[\/]?[^\/]+$', '', 'g') . '/'
                if i.command == 'netrw'
                    let b:netrw_lastfile = filename 
                    let command = 'Nwrite ' . i.dest . dest
                elseif i.command == 'func'
                    let command = 'call ' . i.params . '("' . filename . '", "' . i.dest . dest . '")'
                else
                    let command = i.command . ' ' . i.params . ' "' . filename . '" "' . i.dest . dest .'"' 
                endif
                execute command
            endif
        endif
    endfor
endfunction

function! <SID>sync_operation(op, line)
    let pattern = '\v^([0-9]+):.*$'
    if (match(a:line, pattern) != 0)
        return 
    endif

    let idx = substitute(a:line, pattern, '\1', 'g')
    if a:op == 'd'
        if (s:check_sync_index(idx))
            call s:sync_enable_disable(idx, !g:Sync[idx - 1].active)
        endif
    elseif a:op == 'r'
        call sync#remove(idx)
    endif
    call sync#list_syncs()
endfunction

function! sync#list_syncs()
	let n = bufwinnr("__ActiveSyncs__")
	if n != -1
		execute "bwipeout!"
	endif
	silent! split __ActiveSyncs__

	" Mark the buffer as scratch
	setlocal buftype=nofile
	setlocal bufhidden=wipe
	setlocal noswapfile
	setlocal nowrap
	setlocal nobuflisted

	nnoremap <buffer> <silent> q :bwipeout!<CR>
	nnoremap <buffer> <silent> e :call <SID>sync_operation('d', getline('.'))<CR>
	nnoremap <buffer> <silent> r :call <SID>sync_operation('r', getline('.'))<CR>

	syn match Comment "^\".*"
	put = '\"-----------------------------------------------------'
	put = '\" q                        - close the list of active syncs'
	put = '\" r                        - remove active sync'
	put = '\" e                        - disable/enable active sync'
	put = '\"-----------------------------------------------------'
	let l = line(".") + 1

    let syncs = ''
    let i = 1
    for s in g:Sync
        let l = l + 1
        if (s.active)
            let syncs = syncs . "\n" . i . ": *" . s.source . " --> " . s.dest . ' (command: ' . s.command . ')'
        else
            let syncs = syncs . "\n" . i . ": " . s.source . " --> " . s.dest . ' (command: ' . s.command . ')'
        endif
        let i = i + 1
    endfor

	silent put = syncs

	setlocal nomodifiable
	setlocal nospell
endfunction

function! sync#restore_session()
	if (exists('g:Str_Sync'))
		execute 'let g:Sync = ' . g:Str_Sync
	endif
endfunction

function! sync#save_session()
	if (exists('g:Sync'))
		let g:Str_Sync = string(g:Sync)
	else
		let g:Str_Sync = ""
	endif
endfunction

