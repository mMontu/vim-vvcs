" Test 'VcUp' command 

edit AuxFiles/readWrite.h 
echomsg '>> Test successful invocation without arguments'
VcUp
" echo the contents of the log
copen
g/^/

echomsg '>> Test successful invocation with arguments'
VcUp AuxFiles/readOnly.h
" echo the contents of the log
copen
g/^/

echomsg '>> Test failure due to invalid local path'
VcUp AuxFiles/xyz

echomsg '>> Test failure due to invalid remote path'
VcUp  AuxFiles/invalidDir.h
" echo the contents of the log
copen
g/^/

echomsg '>> Test failure due to ssh error'
VcUp AuxFiles/sshError.h
" echo the contents of the log
copen
g/^/


call vimtest#Quit()
