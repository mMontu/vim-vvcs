" Test 'VcDiff' command 

" set splitright
echomsg '>> Test successful invocation'
call vvcs#log#clear()
edit AuxFiles/readOnly.h 
VcDiff
" check the contents of the log
call vvcs#log#open()
call EchoAllWindows()
tabc

echomsg '>> Test failure due to invalid remote path'
call vvcs#log#clear()
edit AuxFiles/invalidDir.h 
VcDiff 
" check the contents of the log
call EchoAllWindows()
tabc

call vimtest#Quit()
