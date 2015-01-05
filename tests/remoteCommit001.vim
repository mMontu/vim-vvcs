" Test 'commit' remote command 

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                 ClearCase                                  "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:vvcs_remote_vcs = 'ClearCase'

echomsg '>> [ClearCase] Test successful invocation'
call vvcs#log#clear()
call vvcs#remote#execute('commit', 'AuxFiles/readWrite.h', '<commit msg>')
" check the contents of the log
call vvcs#log#open()
call EchoAllWindows()

echomsg '>> [ClearCase] Test on already commited file'
call vvcs#log#clear()
call vvcs#remote#execute('commit', 'AuxFiles/readOnly.h', '<commit msg>')
" check the contents of the log
call EchoAllWindows()

echomsg '>> [ClearCase] Test failure due to invalid local path'
call vvcs#remote#execute('commit', 'AuxFiles/xyz', '<commit msg>')

echomsg '>> [ClearCase] Test failure due to invalid remote path'
call vvcs#log#clear()
call vvcs#remote#execute('commit',  'AuxFiles/invalidDir.h', '<commit msg>')
" check the contents of the log
call EchoAllWindows()

echomsg '>> [ClearCase] Test failure due to ssh error'
call vvcs#log#clear()
call vvcs#remote#execute('commit', 'AuxFiles/sshError.h', '<commit msg>')
" check the contents of the log
call EchoAllWindows()


call vimtest#Quit()
