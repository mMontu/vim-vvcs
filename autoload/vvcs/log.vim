" vvcs#log: log to screen and file
" Maintainer: Marcelo Montu 
" Repository: https://github.com/mMontu/vim-vvcs

let save_cpo = &cpo   " allow line continuation
set cpo&vim

" constants {{{1
let s:PLUGIN_TAG = '[vvcs] '
let s:MAX_ARG_LENGTH = 60

" variables {{{1
let s:currentCmd = ''


function! vvcs#log#error(msg) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Output an error message to display and log file. Return the formmatted error
" message, which can be used on a throw statement.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   echohl ErrorMsg
   echomsg s:PLUGIN_TAG.a:msg
   echohl None
   call vvcs#log#append(['>>> Error <<<', a:msg])
   return s:PLUGIN_TAG.a:msg
endfunction

function! vvcs#log#msg(msg) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Output a message to display and log file
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   echohl Question
   echo s:PLUGIN_TAG.a:msg
   echohl None
   call vvcs#log#append(['>>> Msg <<<', a:msg])
endfunction

function! vvcs#log#startCommand(cmd, ...) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Output start command indication to display and log file. A second argument
" containg additional information about the command (as its argument) is
" included on the message if supplied.
"
" As some commands may use another VVCS commmands on their implementation,
" further calls to this method are ignored until the next call to either
" vvcs#log#commandSucceed() or vvcs#log#commandFailed() with the same
" argument.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   if !empty(s:currentCmd)
      return
   endif
   let s:currentCmd = a:cmd
   let cmd = a:cmd
   if a:0
      if len(a:1) <= s:MAX_ARG_LENGTH
         let cmd .= ' '.a:1
      else
         " remove start of the argument to avoid the hit-enter prompt
         let cmd .= ' ...'.substitute(a:1, '\v.{-}(.{,'.s:MAX_ARG_LENGTH.
                  \ '})$', '\1', '')
      endif
   else
      let cmd .= '...'
   endif
   echohl Directory
   echo s:PLUGIN_TAG.cmd
   echohl None
   call vvcs#log#append(['>>> '.cmd.' <<<'])
endfunction

function! vvcs#log#commandSucceed(cmd, ...) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Output command result to display and log file, but only if a:cmd is the main
" running command (which is specified on the first vvcs#log#startCommand()).
" A second argument containg additional information about the command (as its
" argument) is included on the message if supplied.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   if a:cmd ==# s:currentCmd
      let s:currentCmd = ''
      redraw " clear previous messages
      let msg = a:cmd.' done'
      if a:0 && !empty(a:1)
         let msg .= ' ('.a:1.')'
      endif
      echohl Question
      echo s:PLUGIN_TAG.msg
      echohl None
      call vvcs#log#append(['>>> '.msg.' <<<'])
   endif
endfunction

function! vvcs#log#commandFailed(cmd) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Output command result to display and log file, but only if a:cmd is the main
" running command (which is specified on the first vvcs#log#startCommand()).
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   if a:cmd ==# s:currentCmd
      let s:currentCmd = ''
      let msg = a:cmd.' failed'
      echohl Question
      echomsg s:PLUGIN_TAG.msg
      echohl None
      call vvcs#log#append(['>>> '.msg.' <<<'])
   endif
endfunction

function! vvcs#log#append(lines) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" append lines along timestamp to the log
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   if !empty(g:vvcs_log_location) && !empty(a:lines)
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
   if !empty(g:vvcs_log_location) && 
            \ vvcs#utils#DisplayCacheFile(expand(strftime(g:vvcs_log_location)))
      setlocal nomodifiable
      setlocal autoread
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
