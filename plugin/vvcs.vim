" vvcs.vim - Aid development on remote machines
" Maintainer: Marcelo Montu 
" Repository: https://github.com/mMontu/vim-vvcs

if exists('g:loaded_vvcs') || &cp || version < 700
   finish
endif
let g:loaded_vvcs = 1

" Commands {{{1
command! -bar -complete=file -nargs=? VcUp call vvcs#command('up', <f-args>)
command! -bar -complete=file -nargs=? VcDown call vvcs#command('down', <f-args>)
command! -bar -nargs=0 VcDiff call vvcs#diff()
command! -bar -nargs=0 VcCheckout call vvcs#checkout(expand("%:p"))
command! -nargs=0 VcCodeReview call vvcs#codeReview()
command! -nargs=0 VcListCheckedout call vvcs#listCheckedOut()
command! -nargs=0 VcGetRemotePath call vvcs#getRemotePath()

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

if !hasmapto('<Plug>VcGetRemotePath')
   map <unique> <leader>vg <Plug>VcGetRemotePath
endif
noremap <unique> <Plug>VcGetRemotePath :VcGetRemotePath<CR>

" Options {{{1
if !exists("g:vvcs_fix_path")
   let g:vvcs_fix_path = { 'pat' : '', 'sub' : '' }
endif
if !exists("g:vvcs_remote_cmd")
   let g:vvcs_remote_cmd = "%s"
endif
if !exists("g:vvcs_remote_mark")
   let g:vvcs_remote_mark = "<remote>"
endif
if !exists("g:vvcs_remote_host")
   let g:vvcs_remote_host = "<remote_host>"
endif
if !exists("g:vvcs_remote_branch")
   let g:vvcs_remote_branch = "<remote_branch>"
endif
if !exists("g:vvcs_exclude_patterns")
   let g:vvcs_exclude_patterns = ['*.class', '.cmake.state', '*.swp', 
            \ 'core.[0-9][0-9]*', '*.so.[0-9]', 'lost+found/', '*.jar', '*.gz']
endif
if !exists("g:vvcs_cache_dir")
   let g:vvcs_cache_dir = $HOME.'/.cache/vvcs'
endif
if !exists("g:vvcs_review_comment")
   let g:vvcs_review_comment = "#"
endif
if !exists("g:vvcs_log_location")
   let g:vvcs_log_location = '/log/%Y/%m/%d.log'
endif

function! VvcsSystem(expr) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Wrapper for system() calls. Needed in order to intercept during the tests.
" It is on this file in order to avoid early loading of autoload during tests.
" Variable g:VvcsSystemShellError is the replacement for v:shell_error.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let ret = system(a:expr)
   let g:VvcsSystemShellError = v:shell_error
   " echom "v:shell_error = ". v:shell_error
   return ret
endfunction

function! VvcsInput(...) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Wrapper for input() calls. Needed in order to intercept during the tests.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   return call(function("input"), a:000)
endfunction
function! VvcsConfirm(...) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Wrapper for confirm() calls. Needed in order to intercept during the tests.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   return call(function("confirm"), a:000)
endfunction

" vim: ts=3 sts=0 sw=3 expandtab ff=unix foldmethod=marker :
