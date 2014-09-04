" Test remote 'fix path' 

function! s:toForwardSlash(path)
   if exists('+shellslash')
      " adapt for ms-windows paths
      if !&shellslash
         setlocal shellslash!
         " change backslashes to slashes in path separator
         let correctedPath = expand(a:path)
         setlocal shellslash!
         return correctedPath
      endif
   endif
   return a:path
endfunction




call vimtest#StartTap()
call vimtap#Plan(4)

""""""""""""""""""""""""""""
"  g:vvcs_fix_path: empty  "
""""""""""""""""""""""""""""
call vimtap#Is(vvcs#remote#toRemotePath('AuxFiles/readOnly.h'), 
         \ s:toForwardSlash(fnamemodify('AuxFiles/readOnly.h', ":p")), 
         \ 'toRemote when option is empty')
if exists('+shellslash')
   let expected = '\vobs\readOnly.h'
else
   let expected = '/vobs/readOnly.h'
endif
call vimtap#Is(vvcs#remote#toLocalPath('/vobs/readOnly.h'), 
         \ expected,
         \ 'toLocal when option is empty')


""""""""""""""""""""""""""""""""""""""""""""
"  g:vvcs_fix_path: 'AuxFiles' -> '/vobs'  "
""""""""""""""""""""""""""""""""""""""""""""
let g:vvcs_fix_path = { 'pat' : fnamemodify('AuxFiles/readOnly.h', ":p:h"), 
         \ 'sub' : '/vobs' }
" g:vvcs_fix_path.pat must always use forward slashes
let g:vvcs_fix_path.pat = s:toForwardSlash(g:vvcs_fix_path.pat)

call vimtap#Is(vvcs#remote#toRemotePath('AuxFiles/readOnly.h'), 
         \ '/vobs/readOnly.h', 
         \ "toRemote with 'AuxFiles' -> '/vobs'")
call vimtap#Is(vvcs#remote#toLocalPath('/vobs/readOnly.h'), 
         \ fnamemodify('AuxFiles/readOnly.h', ":p"), 
         \ "toLocalPath with 'AuxFiles' -> '/vobs'")


call vimtest#Quit()
