" vvcs#log: log to screen and file
" Maintainer: Marcelo Montu 
" Repository: https://github.com/mMontu/vim-vvcs

let save_cpo = &cpo   " allow line continuation
set cpo&vim

let s:PLUGIN_TAG = '[vvcs] '

function! vvcs#log#error(msg) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Output an error message to display and log file
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   echohl ErrorMsg
   echomsg s:PLUGIN_TAG.a:msg
   echohl None
   call vvcs#log#append(['>>> Error <<<', a:msg])
endfunction

function! vvcs#log#msg(msg) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Output a message to display and log file
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   echohl Question
   echomsg s:PLUGIN_TAG.a:msg
   echohl None
   call vvcs#log#append(['>>> Msg <<<', a:msg])
endfunction

function! vvcs#log#startCommand(msg) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Output start command indication to display and log file
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   echohl Directory
   echomsg s:PLUGIN_TAG.a:msg.'...'
   echohl None
   call vvcs#log#append(['>>> '.a:msg.' <<<'])
endfunction

function! vvcs#log#append(lines) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" append lines along timestamp to the log
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   if !empty(g:vvcs_log_location)
      if g:vvcs_log_location =~ '%d'
         let time = strftime('%H:%M:%S')
      else
         let time = strftime('%Y-%m-%d %H:%M:%S')
      endif
      let a:lines[0] = time.': '.a:lines[0]
      call vvcs#utils#appendCacheFile(a:lines, 
               \ expand(strftime(g:vvcs_log_location)))
   endif
endfunction

function! vvcs#log#open() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Display the log file
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   if !empty(g:vvcs_log_location)
      call vvcs#utils#DisplayCacheFile(expand(strftime(g:vvcs_log_location)))
      setl nomodifiable
      match Directory />>>.*<<</
      2match LineNr /^\d\+:\d\+:\d\+:/
      nnoremap <silent> <buffer> q :q<CR>
   endif
endfunction

function! vvcs#log#clear() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Clear the log file
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   if !empty(g:vvcs_log_location)
      call vvcs#utils#writeCacheFile([], expand(strftime(g:vvcs_log_location)))
   endif
endfunction

let &cpo = save_cpo
" vim: ts=3 sts=0 sw=3 expandtab ff=unix foldmethod=marker :
