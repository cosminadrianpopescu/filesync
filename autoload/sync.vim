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

if exists('g:loaded_sync') || v:version < 700
  finish
endif
let g:loaded_sync = 1

let g:Sync_default_command = '!rsync'
let g:Sync_default_args = ''
let g:Sync = []

" commands
command! -nargs=+ -complete=dir FileSync call sync#add(<f-args>, '')
command! -nargs=+ -complete=dir FileSyncNetrw call sync#add(<f-args>, 'netrw', '')
command! -nargs=+ -complete=dir FileSyncCmd call sync#add(<f-args>)
command! -nargs=+ -complete=dir FileSyncFunc call sync#add_custom_function(<f-args>)
command! FileSyncList call sync#list_syncs()

augroup sync_execute
augroup sync_sessions
autocmd sync_execute BufWritePost * call sync#execute()
autocmd sync_sessions SessionLoadPost * call sync#restore_session()
