" Test 'commit' remote command 

echomsg '>> Test successful invocation'
call vvcs#remote#execute('commit', 0, 'AuxFiles/readWrite.h', '<commit msg>')
" echo the contents of the log
copen
g/^/

echomsg '>> Test on already commited file'
call vvcs#remote#execute('commit', 0, 'AuxFiles/readOnly.h', '<commit msg>')
" echo the contents of the log
copen
g/^/

echomsg '>> Test failure due to invalid local path'
call vvcs#remote#execute('commit', 0, 'AuxFiles/xyz', '<commit msg>')

echomsg '>> Test failure due to invalid remote path'
call vvcs#remote#execute('commit', 0,  'AuxFiles/invalidDir.h', '<commit msg>')
" echo the contents of the log
copen
g/^/

echomsg '>> Test failure due to ssh error'
call vvcs#remote#execute('commit', 0, 'AuxFiles/sshError.h', '<commit msg>')
" echo the contents of the log
copen
g/^/


call vimtest#Quit()
