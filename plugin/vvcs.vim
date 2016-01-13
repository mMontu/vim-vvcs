" vvcs.vim - Aid development on remote machines
" Maintainer: Marcelo Montu 
" Repository: https://github.com/mMontu/vim-vvcs

if exists('g:loaded_vvcs') || &cp || version < 700
   finish
endif
let g:loaded_vvcs = 1

" Commands {{{1
command! -bar -complete=file -nargs=? VcUp call vvcs#up(0, <f-args>)
command! -bar -complete=file -nargs=? VcUpOverwrite call vvcs#up(1, <f-args>)
command! -bar -bang -complete=file -nargs=? VcDown 
         \ call vvcs#down(0, <bang>0, <f-args>)
command! -bar -bang -complete=file -nargs=? VcDownOverwrite
         \ call vvcs#down(1, <bang>0, <f-args>)
command! -bar -nargs=0 VcDiff call vvcs#diff()
command! -bar -bang -nargs=0 VcCheckout 
         \ call vvcs#checkout(<bang>0, expand("%:p"))
command! -nargs=0 VcCodeReview call vvcs#codeReview()
command! -nargs=0 VcListCheckedout call vvcs#listCheckedOut()
command! -nargs=0 VcGetRemotePath call vvcs#getRemotePath()
command! -nargs=0 VcLog call vvcs#log#open()
command! -bar -complete=file -nargs=? VcMake call vvcs#make(<f-args>)

" Mappings {{{1
if !hasmapto('<Plug>VcUp')
   map <unique> <leader>vu <Plug>VcUp
endif
noremap <unique> <Plug>VcUp :VcUp<CR>

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

if !hasmapto('<Plug>VcListCheckedout')
   map <unique> <leader>vl <Plug>VcListCheckedout
endif
noremap <unique> <Plug>VcListCheckedout :VcListCheckedout<CR>

if !hasmapto('<Plug>VcGetRemotePath')
   map <unique> <leader>vg <Plug>VcGetRemotePath
endif
noremap <unique> <Plug>VcGetRemotePath :VcGetRemotePath<CR>

if !hasmapto('<Plug>VcMake')
   map <unique> <leader>vm <Plug>VcMake
endif
noremap <unique> <Plug>VcMake :VcMake<CR>

" Options {{{1
if !exists("g:vvcs_remote_vcs")
   let g:vvcs_remote_vcs = "<select_vvcs_remote_vcs>"
endif
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
if !exists("g:vvcs_project_log")
   let g:vvcs_project_log = ''
endif
if !exists("g:vvcs_default_path")
   let g:vvcs_default_path = 'expand("%:p")'
endif
if !exists("g:vvcs_make_cmd")
   let g:vvcs_make_cmd = 'make'
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
