" Test 'VcListCheckedout' command 

let g:vvcs_fix_path = {'pat' : 'AuxFiles', 'sub' : '/vobs'}
call SaveRegisters()

" set splitright
VcListCheckedout

echomsg '>> Check windows after opening'
call EchoAllWindows()

echomsg '>> Check diff on the second file'
call search('checkout')
normal 
call EchoAllWindows()

echomsg '>> Mark one file as ''staged to commit'''
call vvcs#comparison#switchToListWindow()
call search('checkout')
normal -
call EchoAllWindows()

echomsg '>> Mark the other file as ''staged to commit'''
call search('readWrite')
normal -
call EchoAllWindows()

echomsg '>> Move back one file to ''not staged to commit'''
call search('checkout')
normal -
call EchoAllWindows()

echomsg '>> Diff stagged file'
call search('readWrite')
normal 
call EchoAllWindows()

echomsg '>> Commit selected files'
call vvcs#log#clear()
call vvcs#comparison#switchToListWindow()
normal cc
" check the contents of the log
call vvcs#log#open()
call EchoAllWindows()

" check if any register was changed
call CheckRegisters()

call vimtest#Quit()
