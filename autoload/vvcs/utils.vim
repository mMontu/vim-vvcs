" vvcs#utils: utility functions
" Maintainer: Marcelo Montu 
" Repository: https://github.com/mMontu/vim-vvcs

let save_cpo = &cpo   " allow line continuation
set cpo&vim

function! vvcs#utils#writeCacheFile(lines, file) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Write list of lines to file on cache directory (an existing file is
" overwritten)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   if !isdirectory(g:vvcs_cache_dir)
      call vvcs#log#error("writeCacheFile(): no cache directory")
      return
   endif
   silent! call writefile(a:lines, g:vvcs_cache_dir.'/'.a:file)
endfunction

function! vvcs#utils#readCacheFile(file) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Return list of lines from file on cache directory
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let fileName = g:vvcs_cache_dir.'/'.a:file
   if !filereadable(fileName)
      return []
   endif
   return readfile(fileName)
endfunction



let &cpo = save_cpo
" vim: ts=3 sts=0 sw=3 expandtab ff=unix foldmethod=marker :
