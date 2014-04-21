" File: vvcs.vim
" Author: Marcelo Montu 
" Description: Aid development on remote machines
" Created: 2014 Mar 12

if exists('g:loaded_vvcs') || &cp || version < 700
   finish
endif
let g:loaded_vvcs = 1

command! -nargs=0 VcDiff call vvcs#diff(expand("%:p"))
nnoremap <leader>vd :VcDiff<CR>
command! -complete=file -nargs=? VcUp call vvcs#command('up', <f-args>)
nnoremap <leader>vu :update <bar> VcUp<CR>
command! -complete=file -nargs=? VcDown call vvcs#command('down', <f-args>)
nnoremap <leader>vw :VcDown<CR>
command! -nargs=0 VcCheckout call vvcs#checkout(expand("%:p"))
nnoremap <leader>vo :VcCheckout<CR>
command! -nargs=0 VcCodeReview call vvcs#codeReview()
nnoremap <leader>vc :VcCodeReview<CR>
command! -nargs=0 VcListCheckedout call vvcs#listCheckedOut()


