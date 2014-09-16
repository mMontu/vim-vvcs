" vvcs#utils: utility functions
" Maintainer: Marcelo Montu 
" Repository: https://github.com/mMontu/vim-vvcs

let save_cpo = &cpo   " allow line continuation
set cpo&vim
" TODO: create cache.vim

function! vvcs#utils#writeCacheFile(lines, file) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Write list of lines to file on cache directory (an existing file is
" overwritten)
" Return the full path of the specified filename.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let fileName = vvcs#utils#GetCacheFileName(a:file)
   if s:checkDirectory(fileName)
      silent call writefile(a:lines, fileName)
   endif
   return fileName
endfunction

function! vvcs#utils#readCacheFile(file) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Return list of lines from file on cache directory
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let fileName = vvcs#utils#GetCacheFileName(a:file)
   if !filereadable(fileName)
      return []
   endif
   return readfile(fileName)
endfunction

function! vvcs#utils#appendCacheFile(lines, file) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Append lines to file on cache directory
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   call vvcs#utils#writeCacheFile(
            \ vvcs#utils#readCacheFile(a:file) + a:lines, a:file)
endfunction

function! vvcs#utils#DisplayCacheFile(file) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Display the cache file. If it is already displayed in the current tabpage it
" is reloaded.
"
" Return true when opened the file (and it wasn't already present in current
" tabpage)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let fileName = vvcs#utils#GetCacheFileName(a:file)
   let winNr = bufwinnr(fileName)
   if winNr != -1
      exe winNr.'wincmd w'
      silent edit
      $  " move to last line
   elseif s:checkDirectory(fileName)
      exe "silent split ".fileName
      $  " move to last line
      return 1
   endif
   return 0
endfunction

function! vvcs#utils#GetCacheFileName(file) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Return the full path of the specified filename
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   return g:vvcs_cache_dir.'/'.a:file
endfunction

function! s:checkDirectory(file) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Return true if the given directory exists or was successfully created
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let dir = fnamemodify(a:file, ":p:h")
   if !isdirectory(dir)
      if !exists('*mkdir') || !mkdir(dir, 'p')
         echohl ErrorMsg
         echomsg "vvcs plugin: unable to create directory: ".dir
         echohl None
         return 0
      endif
   endif
   return 1
endfunction


let &cpo = save_cpo
" vim: ts=3 sts=0 sw=3 expandtab ff=unix foldmethod=marker :
