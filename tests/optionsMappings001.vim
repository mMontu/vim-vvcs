" Test default mapping

call vimtest#StartTap()
call vimtap#Plan(11)

call vimtap#Is(maparg('<leader>vu'), '<Plug>VcUp', "default \vu")
call vimtap#Is(maparg('<leader>vw'), '<Plug>VcDown', "default \vw")
call vimtap#Is(maparg('<leader>vd'), '<Plug>VcDiff', "default \vd")
call vimtap#Is(maparg('<leader>vo'), '<Plug>VcCheckout', "default \vo")
call vimtap#Is(maparg('<leader>vc'), '<Plug>VcCodeReview', "default \vc")

call vimtap#Is(exists('g:loaded_vvcs'), 1, "exists g:loaded_vvcs")


unmap <leader>vu
map <leader>ca <Plug>VcUp
unmap <leader>vw
map <leader>cb <Plug>VcDown
unmap <leader>vd
map <leader>cc <Plug>VcDiff
unmap <leader>vo
map <leader>cd <Plug>VcCheckout
unmap <leader>vc
map <leader>ce <Plug>VcCodeReview

unlet g:loaded_vvcs
source _setup.vim

call vimtap#Is(maparg('<leader>vu'), '', "detect VcUp already mapped")
call vimtap#Is(maparg('<leader>vw'), '', "detect VcDown already mapped")
call vimtap#Is(maparg('<leader>vd'), '', "detect VcDiff already mapped")
call vimtap#Is(maparg('<leader>vo'), '', "detect VcCheckout already mapped")
call vimtap#Is(maparg('<leader>vc'), '', "detect VcCodeReview already mapped")

call vimtest#Quit()
