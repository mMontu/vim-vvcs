" Test 'VcDown' command 

edit AuxFiles/readWrite.h 
echomsg '>> Test successful invocation without arguments'
VcDown
" echo the contents of the log
copen
g/^/

echomsg '>> Test successful invocation with arguments'
VcDown AuxFiles/readOnly.h
" echo the contents of the log
copen
g/^/

echomsg '>> Test failure due to invalid local path'
VcDown AuxFiles/xyz

echomsg '>> Test failure due to invalid remote path'
VcDown  AuxFiles/invalidDir.h
" echo the contents of the log
copen
g/^/

echomsg '>> Test failure due to ssh error'
VcDown AuxFiles/sshError.h
" echo the contents of the log
copen
g/^/


call vimtest#Quit()
