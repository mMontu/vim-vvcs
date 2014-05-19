" Test 'pred' remote command 

echomsg '>> Test successful invocation'
call vvcs#execute('pred', 0, 'AuxFiles/readOnly.h')
" echo the contents of the log
copen
g/^/
" echo the contents of main windows
wincmd p
g/^/

echomsg '>> Test failure due to invalid local path'
g/^/d
call vvcs#execute('pred', 0, 'AuxFiles/xyz')
" echo the contents of main windows - should be empty
g/^/

echomsg '>> Test failure due to invalid remote path'
call vvcs#execute('pred', 0,  'AuxFiles/invalidDir.h')
" echo the contents of the log
copen
g/^/
" echo the contents of main windows
wincmd p
g/^/

echomsg '>> Test failure due to ssh error'
call vvcs#execute('pred', 0, 'AuxFiles/sshError.h')
" echo the contents of the log
copen
g/^/
" echo the contents of main windows
wincmd p
g/^/


call vimtest#Quit()
