" Test 'VcListCheckedout' command 

set splitright
VcListCheckedout

echomsg '>> Check windows after opening'
call EchoAllWindows()

echomsg '>> Mark one file as ''staged to commit'''
normal /checkout-
call EchoAllWindows()

echomsg '>> Mark the other file as ''staged to commit'''
normal /readWrite-
call EchoAllWindows()

echomsg '>> Move back one file to ''not staged to commit'''
normal /checkout-
call EchoAllWindows()

echomsg '>> Commit selected files'
normal cc
copen
g/^/
cclose

normal q
call vimtest#Quit()
