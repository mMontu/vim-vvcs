" vvcs#comparison: display file comparison on a new tab
" Maintainer: Marcelo Montu 
" Repository: https://github.com/mMontu/vim-vvcs

let save_cpo = &cpo   " allow line continuation
set cpo&vim

" constants {{{1
let s:VVCS_CODE_REVIEW_LIST_TITLE = "CodeReview:"
let s:VVCS_CODE_REVIEW_DIFF_LABEL = ['OLD', 'NEW']


function! vvcs#comparison#create(list) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Create a new tab and display the diff of the first pair of selected files.
"
" \par list    a list of files to be compared. Only used when the first
"              parameter is an empty string
"
" When a:list is contains a single element the listWindow isn't displayed.
"
" Each entry on a:list is can be one of the following:
"  * two filenames separeted by a semi-colon
"  * a single filename without version specified -- on this case it will be
"     compared against the previous version based on the current branch/config
"     spec
"
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

   if type(a:list) != type([]) || len(a:list) == 0
      call vvcs#log#error('comparison#create(): invalid ''a:list'' (type: '.
               \ type(a:list).', len = '.len(a:list).')')
      return 1
   endif

   tabe
   vnew

   " t:compareFile holds the bufNumber for the 3 comparison windows
   let t:compareFile = [ 
            \ {'name' : 'first diff'  , 'bufNr' : -1 , 'winNr' : -1},
            \ {'name' : 'second diff' , 'bufNr' : -1 , 'winNr' : -1},
            \ {'name' : 'file list'   , 'bufNr' : -1 , 'winNr' : -1},
   \ ]

   for i in range(2)
      exe i+1.'wincmd w'
      let t:compareFile[i].bufNr = bufnr('%')
      let t:compareFile[i].winNr = winnr()
      call s:setTempBuffer()
      call s:commonMappings()
   endfor

   if len(a:list) > 1
      new
      silent put =a:list
      1  " move to the first line
      let t:compareFile[2].bufNr = bufnr('%')
      """"""""""""""""""""""""""
      "  list window settings  "
      """"""""""""""""""""""""""
      exe 'silent file '.s:VVCS_CODE_REVIEW_LIST_TITLE
      call s:setTempBuffer()
      wincmd J
      setlocal cursorline
      resize 8
      setlocal winfixheight
      " highlight filenames
      match SpecialKey /^.\{-}[/\\]\zs[^/\\]\+\ze@@/
      setlocal nowrap
      " 'expandtab' is not useful on this window, and can cause problems. 
      " E.g.: when s:VVCS_COMMIT_MSG_MARKER (used by VcListCheckedout)
      " contains \t it will expand to spaces when the comment is inserted,
      " thus this variable won't match the inserted text on a substitute()
      " used to remove comments.
      setlocal noexpandtab
      """""""""""""""""""""""""""
      "  list window  mappings  "
      """""""""""""""""""""""""""
      call s:commonMappings()
      nnoremap <buffer> <silent> <CR> :call <SID>compareFiles(0)<CR>
      " map D to the same function on fugitive plugin
      nnoremap <buffer> <silent> D :call <SID>compareFiles(0)<CR>
      nnoremap <buffer> <silent> J :call <SID>compareFiles(1)<CR>
      nnoremap <buffer> <silent> K :call <SID>compareFiles(-1)<CR>
      " trigger the diff on the first line of the list
      call s:compareFiles(0)
   else
      let t:compareFile[2].bufNr = -1 " TODO: remove when changed to object
      call s:compareItem(a:list[0])
   endif
endfunction

function! s:compareFiles(offset) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Handle selection of a line in the file list.
" The offset parameter indicates the line relative to current cursor position.
" Empty lines and lines starting with comments are skipped.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

   """"""""""""""""""""""""""""""""""""""""
   "  check if windows are still present  "
   """"""""""""""""""""""""""""""""""""""""
   for i in range(len(t:compareFile))
      let t:compareFile[i].winNr = bufwinnr(t:compareFile[i].bufNr)
      if t:compareFile[i].winNr  == -1
         call vvcs#log#error("missing comparison window: ".
                  \ t:compareFile[i].name .' ('.t:compareFile[i].bufNr.')')
         return
      endif
   endfor
   " echo t:compareFile
   " return
   exe t:compareFile[2].winNr.'wincmd w'
   call cursor(line('.') + a:offset, 0)

   """""""""""""""""""""""""""""""""
   "  skip empty and marker lines  "
   """""""""""""""""""""""""""""""""
   while getline('.') =~ '\v^\s*%($|'.g:vvcs_review_comment.')'
      if (a:offset >= 0 && line('.') == line('$')) ||
               \ (a:offset < 0 && line('.') == 1)
         return
      endif
      call cursor(line('.') + (a:offset >= 0 ? 1 : -1), 0)
   endw
   redraw  " avoid that cursor move outside window
   let files = substitute(getline('.'), '\s*'.g:vvcs_review_comment.'.*','','')
   return s:compareItem(files)
endfunction

function! s:compareItem(listItem) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Handle a line in the file list. Can be used to peform comparisons when there
" is no file list.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let file = [
            \ {'name' : '', 'cmd' : ''},
            \ {'name' : '', 'cmd' : ''},
   \ ]
   if a:listItem !~ ';'
      " single file specified
      call vvcs#log#msg('retrieving previous version of '.a:listItem.' ...')
      let file[0].cmd = "call vvcs#remote#execute('pred', 0, '".
               \ a:listItem."')"
      let file[0].name = fnamemodify(a:listItem, ":t")
      let file[1].cmd = 'edit '.a:listItem
   else
      " two files specified
      let splitItem = split(a:listItem, '\s*;\s*')
      if len(splitItem) != 2
         call vvcs#log#error('invalid number of files: '.len(splitItem))
         return
      endif
      for i in range(len(splitItem))
         let file[i].name = substitute(splitItem[i], '@.*','','')
         " TODO use a custom remote command instead of -cInlineResult and move
         " both 'retrieving' messages from this method to g:vvcs#remote#op
         " 'message' key
         call vvcs#log#msg('retrieving '.splitItem[i].' ...')
         let file[i].cmd = 'call vvcs#remote#execute("-cInlineResult", i, '.
                  \ '"cat ".splitItem[i])'
      endfor
   endif

   " display the files
   for i in range(2)
      exe t:compareFile[i].winNr.'wincmd w'
      diffoff
      if &buftype == 'nofile'
         setlocal modifiable
         1,$d
      else
         enew
         call s:setTempBuffer()
         setlocal modifiable
      endif
      exe 'silent file '.s:VVCS_CODE_REVIEW_DIFF_LABEL[i].'\ '. file[i].name
      exe file[i].cmd
      if &buftype != 'nofile'
         let t:compareFile[i].bufNr = bufnr('%') " bufNr changes if cmd is edit
      endif
      " trigger autocmd to detect filetype and execute any filetype plugins
      silent doautocmd BufNewFile
      if line('$') > 1 || getline(1) != ''
         " check before 'diffthis' to avoid redraw problem when file is empty
         diffthis
      endif
      if &buftype == 'nofile'
         setlocal nomodifiable
      endif
   endfor

   """""""""""""""""""""""""""""
   "  jump to the first error  "
   """""""""""""""""""""""""""""
   exe t:compareFile[0].winNr.'wincmd w'
   if line('$') > 1 || getline(1) != ''
      normal! gg]c
      " try to avoid some redraw problems
      exe t:compareFile[1].winNr.'wincmd w'
      normal! gg]c
      wincmd p
      redraw!
   else
      diffo!
      exe t:compareFile[1].winNr.'wincmd w'
   endif
endfunction

function! vvcs#comparison#switchToListWindow() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Return true if successfully switch to the window use to list compared files
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
      let t:compareFile[2].winNr = bufwinnr(t:compareFile[2].bufNr)
      if t:compareFile[2].winNr  == -1
         return 0
      endif
      exe t:compareFile[2].winNr.'wincmd w'
      return 1
endfunction


function! s:commonMappings() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" mappings applicable to all compareFile windows
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   nnoremap <buffer> <c-down> ]c
   nnoremap <buffer> <c-up> [c
   nnoremap <buffer> J ]c
   nnoremap <buffer> K [c
   nnoremap <buffer> <silent> q 
            \ :if VvcsConfirm("Quit comparison?", "&Yes\n&No") == 1 <bar> 
            \ diffo! <bar> tabc <bar> endif<CR>
   nnoremap <buffer> <silent> <leader>j :call <SID>compareFiles(1)<CR>
   nnoremap <buffer> <silent> <leader>k :call <SID>compareFiles(-1)<CR>
endfunction

let &cpo = save_cpo

function! s:setTempBuffer() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Select settings of a temporary/scratch buffer
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   setlocal buftype=nofile
   setlocal bufhidden=delete
   setlocal noswapfile
   setlocal nomodifiable
   setlocal textwidth=0 " avoid automatic line break
endfunction


" vim: ts=3 sts=0 sw=3 expandtab ff=unix foldmethod=marker :
