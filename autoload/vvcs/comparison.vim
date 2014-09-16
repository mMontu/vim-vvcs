" vvcs#comparison: display file comparison on a new tab
" Maintainer: Marcelo Montu 
" Repository: https://github.com/mMontu/vim-vvcs

let save_cpo = &cpo   " allow line continuation
set cpo&vim

" constants {{{1
let s:VVCS_CODE_REVIEW_DIFF_LABEL = ['OLD', 'NEW']


function! vvcs#comparison#createSingle(files) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Create a new tab with two windows and display the diff of files specified in
" the string a:files, which can be:
"
"  * two filenames separeted by a semi-colon
"  * a single filename without version specified -- on this case it will be
"     compared against the previous version based on the current branch/config
"     spec
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   call s:createDiffWindows()
   let t:compareFile[2].bufNr = -1
   call s:compareItem(a:files)
endfunction

function! s:createDiffWindows() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Create a new tab and two windows to display the diff.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
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
endfunction

function! vvcs#comparison#create(file) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Create a new tab and display the diff of the first pair of selected files.
"
" \par file    file containing the list of files to be compared.
"
" Each entry on a:list is can be one of the following:
"  * two filenames separeted by a semi-colon
"  * a single filename without version specified -- on this case it will be
"     compared against the previous version based on the current branch/config
"     spec
"
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

   call s:createDiffWindows()

   """""""""""""""""""""""""""""
   "  open review list window  "
   """""""""""""""""""""""""""""
   new
   exe 'silent edit '.a:file
   1  " move to the first line
   let t:compareFile[2].bufNr = bufnr('%')
   """"""""""""""""""""""""""
   "  list window settings  "
   """"""""""""""""""""""""""
   call s:setTempBuffer()
   wincmd J
   setlocal cursorline
   resize 8
   setlocal winfixheight
   " highlight filenames
   " TODO: move to a syntax file when it is created (and documented on the
   " help)
   match SpecialKey /^.\{-}[/\\]\zs[^/\\]\+\ze@@/
   setlocal nowrap
   " 'expandtab' is not useful on this window, and can cause problems. 
   " E.g.: when a variable contains \t it will expand to spaces when its
   " contents are inserted, thus this variable won't match the inserted text
   " on a substitute() used to remove it.
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
   if !s:updateWindowNumbers()
      return
   endif
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
   let item = a:listItem

   if item !~ ';'
      " Change item containing only '/path/file@@version/N' and replace with
      " '/path/file@@version/N-1 ; /path/file@@version/N' 
      let item = substitute(item, '\v^(\s*[^ \t;@]+\@\@[^ \t;]{-})(\d+>)\s*$',
               \ '\=submatch(1).(submatch(2)-1)." ; ".submatch(1).submatch(2)', 
               \ "")
      " TODO: move to a separate dictionary in order to make this code
      " independent of ClearCase; maybe retrieve it from the remote system, in
      " order to fix #14
   endif

   if item !~ ';'
      " single file specified
      let file[0].cmd = "call s:setCurrentLine(".
               \ "vvcs#remote#execute('pred', '". item."')['value'])"
      let file[0].name = fnamemodify(item, ":t")
      let file[1].cmd = 'edit '.item
   else
      " two files specified
      let splitItem = split(item, '\s*;\s*')
      if len(splitItem) != 2
         call vvcs#log#error('invalid number of files: '.len(splitItem))
         return
      endif
      for i in range(len(splitItem))
         let file[i].name = substitute(splitItem[i], '@.*','','')
         let file[i].cmd = "call s:setCurrentLine(".
                  \ "vvcs#remote#execute('catVersion', splitItem[i])['value'])"
      endfor
   endif

   " display the files
   for i in range(2)
      exe t:compareFile[i].winNr.'wincmd w'
      diffoff
      if &buftype == 'nofile'
         setlocal modifiable
         " TODO: use command to delete the buffer which doesn't changes the
         " paste register
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
      " avoid hidding the log file if file[i].cmd fails
      if !s:updateWindowNumbers()
         return
      endif
   endfor

   """""""""""""""""""""""""""""
   "  jump to the first error  "
   """""""""""""""""""""""""""""
   exe t:compareFile[0].winNr.'wincmd w'
   if line('$') > 1 || getline(1) != ''
      normal! gg
      redraw!
      normal! ]c
      redraw
      " try to avoid some redraw problems
      " exe t:compareFile[1].winNr.'wincmd w'
      " redraw
      " wincmd p
      " redraw
      " normal! gg]c
      " redraw
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


function! s:updateWindowNumbers() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Update the window number for the comparison buffers.
" Returns false if some window is not found.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

   """"""""""""""""""""""""""""""""""""""""
   "  check if windows are still present  "
   """"""""""""""""""""""""""""""""""""""""
   for i in range(len(t:compareFile))
      let t:compareFile[i].winNr = bufwinnr(t:compareFile[i].bufNr)
      if t:compareFile[i].bufNr != -1 && t:compareFile[i].winNr  == -1
         call vvcs#log#error("missing comparison window: ".
                  \ t:compareFile[i].name .' ('.t:compareFile[i].bufNr.')')
         return 0
      endif
   endfor
   " echo t:compareFile
   return 1
endfunction


function! s:setCurrentLine(content) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Replace the current line with the specified string (which may spam multiple
" lines).
"
" It avoids some problems from call setline(getline('.'), split('...', '\n')).
" E.g.: if the string starts with a newline them split() will remove it. If
" the keepempty is set, split will include the first empty line, but it will
" also include an extra one at the end if the last line ends in '\n'.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   put =a:content 
   normal! '[kdd
endfunction


let &cpo = save_cpo
" vim: ts=3 sts=0 sw=3 expandtab ff=unix foldmethod=marker :
