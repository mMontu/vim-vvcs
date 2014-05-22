" Test 'VcCodeReview' command 


" set splitright
echomsg '>> Test successful invocation'
let g:inputStub['list to review'] = "AuxFiles/ReviewList1"
VcCodeReview
echomsg 'echo the first window'
1wincmd w
exec "normal \<c-g>"
g/^/

echomsg 'echo the second window'
2wincmd w
exec "normal \<c-g>"
g/^/

echomsg 'echo the third window'
3wincmd w
exec "normal \<c-g>"
g/^/

call vimtest#Quit()
