" File: vvcs.vim
" Author: Marcelo Montu 
" Description: Aid development on remote machines
" Created: 2014 Mar 12

if exists('g:loaded_vvcs') || &cp || version < 700
   finish
endif
let g:loaded_vvcs = 1

" Commands {{{1
command! -complete=file -nargs=? VcUp call vvcs#command('up', <f-args>)
command! -complete=file -nargs=? VcDown call vvcs#command('down', <f-args>)
command! -nargs=0 VcDiff call vvcs#diff(expand("%:p"))
command! -nargs=0 VcCheckout call vvcs#checkout(expand("%:p"))
command! -nargs=0 VcCodeReview call vvcs#codeReview()
command! -nargs=0 VcListCheckedout call vvcs#listCheckedOut()

" Mappings {{{1
if !hasmapto('<Plug>VcUpdate')
   map <unique> <leader>vu <Plug>VcUpdate
endif
noremap <unique> <Plug>VcUpdate :VcUp<CR>

if !hasmapto('<Plug>VcDown')
   map <unique> <leader>vw <Plug>VcDown
endif
noremap <unique> <Plug>VcDown :VcDown<CR>

if !hasmapto('<Plug>VcDiff')
   map <unique> <leader>vd <Plug>VcDiff
endif
noremap <unique> <Plug>VcDiff :VcDiff<CR>

if !hasmapto('<Plug>VcCheckout')
   map <unique> <leader>vo <Plug>VcCheckout
endif
noremap <unique> <Plug>VcCheckout :VcCheckout<CR>

if !hasmapto('<Plug>VcCodeReview')
   map <unique> <leader>vc <Plug>VcCodeReview
endif
noremap <unique> <Plug>VcCodeReview :VcCodeReview<CR>


function! VvcsSystem(expr) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Wrapper for system() calls. Needed in order to intercept system() calls
" during the tests. It is on this file in order to avoid early loading of
" autoload during tests.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   return system(a:expr)
endfunction

" vim: ts=3 sts=0 sw=3 expandtab ff=unix foldmethod=marker :
