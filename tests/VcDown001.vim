" Test 'VcDown' command 

" Only ClearCase is tested because other VCS only use different remote
" operations, which are verified on other test cases
let g:vvcs_remote_vcs = 'ClearCase'

edit AuxFiles/readWrite.h 
echomsg '>> Test successful invocation without arguments'
call vvcs#log#clear()
VcDown
" check the contents of the log
call vvcs#log#open()
call EchoAllWindows()

echomsg '>> Test successful invocation without arguments overwriting'
call vvcs#log#clear()
edit AuxFiles/readWrite.h 
VcDownOverwrite
" check the contents of the log
call vvcs#log#open()
call EchoAllWindows()

echomsg '>> Test successful invocation with arguments'
call vvcs#log#clear()
VcDown AuxFiles/readOnly.h
" check the contents of the log
call vvcs#log#open()
call EchoAllWindows()

echomsg '>> Test failure due to invalid local path'
VcDown AuxFiles/xyz

echomsg '>> Test failure due to invalid remote path'
call vvcs#log#clear()
VcDown  AuxFiles/invalidDir.h
" check the contents of the log
call EchoAllWindows()

echomsg '>> Test failure due to ssh error'
call vvcs#log#clear()
VcDown AuxFiles/sshError.h
" check the contents of the log
call EchoAllWindows()


call vimtest#Quit()
