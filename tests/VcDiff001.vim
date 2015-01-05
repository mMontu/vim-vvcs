" Test 'VcDiff' command 

" Only ClearCase is tested because other VCS only use different remote
" operations, which are verified on other test cases
let g:vvcs_remote_vcs = 'ClearCase'

call SaveRegisters()

" set splitright
echomsg '>> Test successful invocation (single line)'
call vvcs#log#clear()
edit AuxFiles/readOnly.h 
VcDiff
" check the contents of the log
call vvcs#log#open()
call EchoAllWindows()
tabc

echomsg '>> Test successful invocation (last line empty)'
call vvcs#log#clear()
edit AuxFiles/readWrite.h 
VcDiff
" check the contents of the log
call vvcs#log#open()
call EchoAllWindows()
tabc

echomsg '>> Test successful invocation (first line empty)'
call vvcs#log#clear()
edit AuxFiles/checkoutOk.h 
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

" check for corrupted registers
call CheckRegisters()

call vimtest#Quit()
