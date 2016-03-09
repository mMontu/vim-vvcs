" Test 'pred' remote command (retrieve the previous version of a file -
" replaced by remote commands info and catVersion)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                 ClearCase                                  "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:vvcs_remote_vcs = 'ClearCase'

echomsg '>> [ClearCase] Test successful invocation'
call vvcs#log#clear()
call setline(1, split(vvcs#remote#execute('catVersion', 
         \ vvcs#remote#execute('info', 'AuxFiles/readOnly.h', 1)['value'])
         \['value'], '\n'))
" check the contents of the log
call vvcs#log#open()
call EchoAllWindows()

echomsg '>> [ClearCase] Test failure due to invalid remote path'
call vvcs#log#clear()
call setline(1, split(vvcs#remote#execute('catVersion', 
         \ vvcs#remote#execute('info', 'AuxFiles/invalidDir.h', 1)['value'])
         \['value'], '\n'))
" check the contents of the log
call EchoAllWindows()

echomsg '>> [ClearCase] Test failure due to ssh error'
call vvcs#log#clear()
call setline(1, split(vvcs#remote#execute('catVersion', 
         \ vvcs#remote#execute('info', 'AuxFiles/sshError.h', 1)['value'])
         \['value'], '\n'))
" check the contents of the log
call EchoAllWindows()


call vimtest#Quit()
