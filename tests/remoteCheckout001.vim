" Test 'checkout' remote command 

echomsg '>> Test successful invocation'
call vvcs#log#clear()
call vvcs#remote#execute('checkout', 'AuxFiles/readOnly.h')
" check the contents of the log
call vvcs#log#open()
call EchoAllWindows()

echomsg '>> Test on already checkedout file'
call vvcs#log#clear()
call vvcs#remote#execute('checkout', 'AuxFiles/readWrite.h')
call EchoAllWindows()

echomsg '>> Test failure due to invalid local path'
call vvcs#remote#execute('checkout', 'AuxFiles/xyz')

echomsg '>> Test failure due to invalid remote path'
call vvcs#log#clear()
call vvcs#remote#execute('checkout',  'AuxFiles/invalidDir.h')
" check the contents of the log
call EchoAllWindows()

echomsg '>> Test failure due to ssh error'
call vvcs#log#clear()
call vvcs#remote#execute('checkout', 'AuxFiles/sshError.h')
" check the contents of the log
call EchoAllWindows()


call vimtest#Quit()
