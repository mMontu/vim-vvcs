" Test 'VcCheckout' command 

" Only ClearCase is tested because other VCS only use different remote
" operations, which are verified on other test cases
let g:vvcs_remote_vcs = 'ClearCase'

echomsg '>> Test successful invocation'
call vvcs#log#clear()
edit AuxFiles/checkoutOk.h 
VcCheckout
" check the contents of the log
call vvcs#log#open()
call EchoAllWindows()

echomsg '>> Test failure due to invalid state of remote file'
call vvcs#log#clear()
edit AuxFiles/readWrite.h 
VcCheckout
" check the contents of the log
call EchoAllWindows()

echomsg '>> Test failure due to VcDown failure'
call vvcs#log#clear()
edit AuxFiles/readOnly.h 
VcCheckout
" check the contents of the log
call EchoAllWindows()

echomsg '>> Test failure due to invalid local path'
edit AuxFiles/xyz
VcCheckout

echomsg '>> Test failure due to invalid remote path'
call vvcs#log#clear()
edit AuxFiles/invalidDir.h
VcCheckout
" check the contents of the log
call EchoAllWindows()

echomsg '>> Test failure due to ssh error'
call vvcs#log#clear()
edit AuxFiles/sshError.h
VcCheckout
" check the contents of the log
call EchoAllWindows()


call vimtest#Quit()
