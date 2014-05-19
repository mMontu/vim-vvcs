" Test 'up' remote command 

echomsg '>> Test successful invocation'
call vvcs#execute('up', 0, 'AuxFiles/readOnly.h')
" echo the contents of the log
copen
g/^/

echomsg '>> Test failure due to invalid local path'
call vvcs#execute('up', 0, 'AuxFiles/xyz')

echomsg '>> Test failure due to invalid remote path'
call vvcs#execute('up', 0,  'AuxFiles/invalidDir.h')
" echo the contents of the log
copen
g/^/

echomsg '>> Test failure due to ssh error'
call vvcs#execute('up', 0, 'AuxFiles/sshError.h')
" echo the contents of the log
copen
g/^/


call vimtest#Quit()
