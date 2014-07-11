" Test 'checkout' remote command 

echomsg '>> Test successful invocation'
call vvcs#remote#execute('checkout', 0, 'AuxFiles/readOnly.h')
" echo the contents of the log
copen
g/^/

echomsg '>> Test on already checkedout file'
call vvcs#remote#execute('checkout', 0, 'AuxFiles/readWrite.h')
" echo the contents of the log
copen
g/^/

echomsg '>> Test failure due to invalid local path'
call vvcs#remote#execute('checkout', 0, 'AuxFiles/xyz')

echomsg '>> Test failure due to invalid remote path'
call vvcs#remote#execute('checkout', 0,  'AuxFiles/invalidDir.h')
" echo the contents of the log
copen
g/^/

echomsg '>> Test failure due to ssh error'
call vvcs#remote#execute('checkout', 0, 'AuxFiles/sshError.h')
" echo the contents of the log
copen
g/^/


call vimtest#Quit()
