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
" check that initial empty line isn't necessary and that empty buffer doesn't
" trigger diff
call TestCodeReview('>> Test successful invocation 3',"AuxFiles/ReviewList3")
" test two files with no space between
call TestCodeReview('>> Test successful invocation 4',"AuxFiles/ReviewList5")

call TestCodeReview('>> Test invalid input 1',"AuxFiles/ReviewList4")

call vimtest#Quit()
