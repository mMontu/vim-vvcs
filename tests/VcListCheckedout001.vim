" Test 'VcListCheckedout' command 

let g:vvcs_fix_path = {'pat' : 'AuxFiles', 'sub' : '/vobs'}

" set splitright
VcListCheckedout

echomsg '>> Check windows after opening'
call EchoAllWindows()

echomsg '>> Check diff on the second file'
normal /checkout
call EchoAllWindows()

echomsg '>> Mark one file as ''staged to commit'''
call vvcs#comparison#switchToListWindow()
normal /checkout-
call EchoAllWindows()

echomsg '>> Mark the other file as ''staged to commit'''
normal /readWrite-
call EchoAllWindows()

echomsg '>> Move back one file to ''not staged to commit'''
normal /checkout-
call EchoAllWindows()

echomsg '>> Diff stagged file'
normal /readWrite
call EchoAllWindows()

echomsg '>> Commit selected files'
call vvcs#log#clear()
call vvcs#comparison#switchToListWindow()
normal cc
" check the contents of the log
call vvcs#log#open()
call EchoAllWindows()

call vimtest#Quit()
