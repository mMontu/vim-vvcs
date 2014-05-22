" Test 'VcDiff' command 

" set splitright
echomsg '>> Test successful invocation'
edit AuxFiles/readOnly.h 
VcDiff
" echo the contents of each window
echomsg '>>> contents of first window'
1wincmd w
exec "normal \<c-g>"
set diff?
g/^/
echomsg '>>> contents of second window'
2wincmd w
exec "normal \<c-g>"
set diff?
g/^/
tabc

echomsg '>> Test failure due to invalid remote path'
edit AuxFiles/invalidDir.h 
VcDiff 
" echo the contents of each window
1wincmd w
echomsg '>>> contents of first window'
set diff?
g/^/
2wincmd w
echomsg '>>> contents of second window'
set diff?
g/^/
tabc

call vimtest#Quit()
