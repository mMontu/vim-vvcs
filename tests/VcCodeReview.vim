" Test 'VcCodeReview' command 

function! TestCodeReview(msg, reviewFile)
   exe "echomsg '".a:msg."'"
   let g:inputStub['list to review'] = a:reviewFile
   VcCodeReview
   call EchoAllWindows()
   normal q
endfunction


" set splitright
call TestCodeReview('>> Test successful invocation 1', "AuxFiles/ReviewList1")
call TestCodeReview('>> Test successful invocation 2',"AuxFiles/ReviewList2")
call TestCodeReview('>> Test successful invocation 3',"AuxFiles/ReviewList3")

call vimtest#Quit()
