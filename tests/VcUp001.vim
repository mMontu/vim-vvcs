" Test 'VcUp' command 

edit AuxFiles/readWrite.h 
echomsg '>> Test successful invocation without arguments'
call vvcs#log#clear()
VcUp
" check the contents of the log
call vvcs#log#open()
call EchoAllWindows()

echomsg '>> Test successful invocation with arguments'
call vvcs#log#clear()
VcUp AuxFiles/readOnly.h
" check the contents of the log
call vvcs#log#open()
call EchoAllWindows()

echomsg '>> Test failure due to invalid local path'
VcUp AuxFiles/xyz

echomsg '>> Test failure due to invalid remote path'
call vvcs#log#clear()
VcUp  AuxFiles/invalidDir.h
" check the contents of the log
call EchoAllWindows()

echomsg '>> Test failure due to ssh error'
call vvcs#log#clear()
VcUp AuxFiles/sshError.h
" check the contents of the log
call EchoAllWindows()


call vimtest#Quit()
