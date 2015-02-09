" Test 'up' remote command 

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                 ClearCase                                  "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:vvcs_remote_vcs = 'ClearCase'

echomsg '>> [ClearCase] Test successful invocation'
call vvcs#log#clear()
call vvcs#remote#execute('up', 'AuxFiles/readOnly.h', 0)
" check the contents of the log
call vvcs#log#open()
call EchoAllWindows()

echomsg '>> [ClearCase] Test failure due to invalid local path'
call vvcs#remote#execute('up', 'AuxFiles/xyz', 0)

echomsg '>> [ClearCase] Test failure due to invalid remote path'
call vvcs#log#clear()
call vvcs#remote#execute('up',  'AuxFiles/invalidDir.h', 0)
" check the contents of the log
call EchoAllWindows()

echomsg '>> [ClearCase] Test failure due to ssh error'
call vvcs#log#clear()
call vvcs#remote#execute('up', 'AuxFiles/sshError.h', 0)
" check the contents of the log
call EchoAllWindows()


call vimtest#Quit()
