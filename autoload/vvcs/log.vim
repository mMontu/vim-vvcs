" vvcs#log: log to screen and file
" Maintainer: Marcelo Montu 
" Repository: https://github.com/mMontu/vim-vvcs

let save_cpo = &cpo   " allow line continuation
set cpo&vim

function! vvcs#log#error(msg) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Format and output an error message
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   echohl WarningMsg
   echomsg '[vvcs plugin] '.a:msg
   echohl None
endfunction



let &cpo = save_cpo
" vim: ts=3 sts=0 sw=3 expandtab ff=unix foldmethod=marker :
