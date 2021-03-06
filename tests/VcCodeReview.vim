" Test 'VcCodeReview' command 

" Only ClearCase is tested because other VCS only use different remote
" operations, which are verified on other test cases
let g:vvcs_remote_vcs = 'ClearCase'

function! TestCodeReview(msg, reviewFile, close)
   exe "echomsg '".a:msg."'"
   let g:inputStub['list to review'] = a:reviewFile
   VcCodeReview
   call EchoAllWindows()
   if a:close
      normal q
   endif
endfunction
call SaveRegisters()

"""""""""""""""""""""""""""""""""""
"  simple successful invocations  "
"""""""""""""""""""""""""""""""""""
" set splitright
call TestCodeReview('>> Test successful invocation 1',"AuxFiles/ReviewList1",1)
call TestCodeReview('>> Test successful invocation 2',"AuxFiles/ReviewList2",1)
" check that initial empty line isn't necessary and that empty buffer doesn't
" trigger diff
call TestCodeReview('>> Test successful invocation 3',"AuxFiles/ReviewList3",1)
" test two files with no space between
call TestCodeReview('>> Test successful invocation 4',"AuxFiles/ReviewList5",1)


""""""""""""""""""""""""
"  failed invocations  "
""""""""""""""""""""""""
call TestCodeReview('>> Test invalid input 1',"AuxFiles/ReviewList4",1)


""""""""""""""""""""""""""""""""""
"  two simultaneous comparisons  "
""""""""""""""""""""""""""""""""""
call TestCodeReview('>> simultaneous comparisons: 1st',"AuxFiles/ReviewList6",0)

call TestCodeReview('>> simultaneous comparisons: 2nd',"AuxFiles/ReviewList7",0)

echomsg ">> switching to the next file on 1st comparison"
tabprevious
normal \j
call EchoAllWindows()

echomsg ">> switching to the next file on 2nd comparison"
tabnext
normal \j
call EchoAllWindows()
normal q
normal q

"""""""""""""""""""""""""""""""""""""""""
"  one window split to another tabpage  "
"""""""""""""""""""""""""""""""""""""""""
echomsg ">> one window split to another tabpage"
let g:inputStub['list to review'] = "AuxFiles/ReviewList1"
VcCodeReview
wincmd w
tab vs
tabprevious
wincmd p
exe "normal \<cr>"
call EchoAllWindows()
normal q


""""""""""""""""""""""""""""""""""""""""
"  check if any register was changed   "
""""""""""""""""""""""""""""""""""""""""
call CheckRegisters()

call vimtest#Quit()
