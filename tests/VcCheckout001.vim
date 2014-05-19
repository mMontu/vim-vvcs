" Test 'VcCheckout' command 

echomsg '>> Test successful invocation'
edit AuxFiles/checkoutOk.h 
VcCheckout
" echo the contents of the log
copen
g/^/

echomsg '>> Test failure due to invalid state of remote file'
edit AuxFiles/readWrite.h 
VcCheckout
" echo the contents of the log
copen
g/^/

echomsg '>> Test failure due to VcDown failure'
edit AuxFiles/readOnly.h 
VcCheckout
" echo the contents of the log
copen
g/^/

echomsg '>> Test failure due to invalid local path'
edit AuxFiles/xyz
VcCheckout

echomsg '>> Test failure due to invalid remote path'
edit AuxFiles/invalidDir.h
VcCheckout
" echo the contents of the log
copen
g/^/

echomsg '>> Test failure due to ssh error'
edit AuxFiles/sshError.h
VcCheckout
" echo the contents of the log
copen
g/^/


call vimtest#Quit()
