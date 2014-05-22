" File: vvcs.vim
" Author: Marcelo Montu 
" Description: Aid development on remote machines
" Created: 2014 Mar 18

let save_cpo = &cpo   " allow line continuation
set cpo&vim

" options {{{1
if !exists("g:vvcs_fix_path")
   let g:vvcs_fix_path = { 'pat' : '', 'sub' : '' }
endif
if !exists("g:vvcs_remote_cmd")
   let g:vvcs_remote_cmd = "%s"
endif
if !exists("g:vvcs_remote_mark")
   let g:vvcs_remote_mark = "<remote>"
endif
if !exists("g:vvcs_local_host")
   let g:vvcs_local_host = "<local_host>"
endif
if !exists("g:vvcs_exclude_patterns")
   let g:vvcs_exclude_patterns = ['*.[ao]', '*.class', '.cmake.state', '*.swp', 
            \ 'core.[0-9][0-9]*', 'lib*.so', 'lib*.so.[0-9]', 'lost+found/',
            \ '*.jar', '*.gz']
endif
if !exists("g:vvcs_cache_dir")
   let g:vvcs_cache_dir = $HOME.'/.cache/vvcs'
endif

" constants {{{1
let s:VVCS_CODE_REVIEW_LIST_TITLE = "CodeReview:"
let s:VVCS_CODE_REVIEW_DIFF_LABEL = ['OLD', 'NEW']
let s:VVCS_CODE_REVIEW_BROWSE = "codeReviewBrowse"
let s:VVCS_STAGED_MARKER = '# Changes staged for commit:'
let s:VVCS_NOT_STAGED_MARKER = '# Changes not staged for commit:'
let s:VVCS_COMMIT_MSG_MARKER = 'comment:'

" Initialization {{{1
if exists('*mkdir') && !isdirectory(g:vvcs_cache_dir)
   silent! call mkdir(g:vvcs_cache_dir, 'p')
endif


function! vvcs#handlePath(path) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Change relative to absolute paths. Return empty string for invalid paths.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let ret = fnamemodify(a:path, ":p")
   if !isdirectory(ret) && !filereadable(ret)
      call vvcs#error("invalid path: '".ret."'")
      return ''
   endif
   let ret = escape(fnameescape(ret), '\') " adapt for ms-windows paths
   return ret
endfunction

function! vvcs#error(msg) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Format and output an error message
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   echohl WarningMsg
   echomsg '[vvcs plugin] '.a:msg
   echohl None
endfunction

function! vvcs#rsyncExcludePat() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Return string containing rsync option to ignore several files.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let ret = ''
   for pat in g:vvcs_exclude_patterns
      let ret .= '--exclude \"' . pat . '\" '
   endfor
   return ret
endfunction



" g:vvcs#op dictionary {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" common commands used to work on remote machines
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:vvcs#op = { 
   \'up' : {
         \'args' : ['<path>'],
         \'cmd': "/usr/bin/rsync -azv ".vvcs#rsyncExcludePat()." -e ssh ".
            \ g:vvcs_local_host.":<path> ".g:vvcs_remote_mark."<path>",
   \},
   \'down' : {
         \'args' : ['<path>'],
         \'cmd': "/usr/bin/rsync -azv ".vvcs#rsyncExcludePat()." -e ssh ".
            \ g:vvcs_remote_mark."<path> ".g:vvcs_local_host.":<path> ",
   \},
   \'pred' : {
         \'args' : ['<filepath>'],
         \'cmd':  'cat '.g:vvcs_remote_mark.
            \'<filepath>@@\`cleartool descr -pred -short '.g:vvcs_remote_mark.
            \'<filepath>\`',
         \'inlineResult' : '',
   \},
   \'checkout' : {
         \'args' : ['<path>'],
         \'cmd': "ct co -nc ".g:vvcs_remote_mark."<path>",
   \},
   \'commit' : {
         \'args' : ['<path>', '<comment>'],
         \'cmd': 'ct ci -c \"<comment>\" '.g:vvcs_remote_mark.'<path>',
   \},
   \'-c' : {
         \'args' : ['<cmd>'],
         \'cmd': "<cmd>",
   \},
   \'-cInlineResult' : {
         \'args' : ['<cmd>'],
         \'cmd': "<cmd>",
         \'inlineResult' : '',
   \},
   \ 'checkedoutList' : {
         \'args' : [],
         \'cmd':  'ct lsco -avobs -cview',
         \'inlineResult' : '',
   \},
\}

function! vvcs#execute(key, keepRes, ...) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Run the command on the g:vvcs#op dict for the specified key. The
" quickfix is filled with the log of the execution. If keepRes is not set the
" quickfix is cleared before start logging.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   if !has_key(g:vvcs#op, a:key)
      call vvcs#error('unknown command: ' . a:key)
      return 1
   endif
   if a:0 != len(g:vvcs#op[a:key].args)
      echom "incorrect number of parameters for '".a:key."': ".string(a:000)
      return 1
   endif

   let cmd = g:vvcs#op[a:key].cmd
   for i in range(len(g:vvcs#op[a:key].args))
      let par = g:vvcs#op[a:key].args[i]
      let val = a:000[i]
      if par =~# 'path'
         let val = vvcs#handlePath(val)
         " duplicate escapes as the substitute() below will remove them
         let val = escape(val, '\') 
         if val == ''
            return 1
         endif
         " apply the transformation from local path to the remote filesystem
         let remPath = substitute(val, g:vvcs_fix_path.pat,
                  \ g:vvcs_fix_path.sub, '')
         let cmd = substitute(cmd, g:vvcs_remote_mark.par, remPath, 'g')
      endif
      let cmd = substitute(cmd, par, val, 'g')
   endfor

   exe (a:keepRes ?'caddexp' : 'cgetexpr').' "Will execute: '.cmd.'"'
   let systemOut = VvcsSystem(printf(g:vvcs_remote_cmd, cmd))
   if !has_key(g:vvcs#op[a:key], 'inlineResult')
      " caddexp printf(g:vvcs_remote_cmd, cmd)
      caddexp systemOut
      if exists('g:vvcs_debug')
         copen
         wincmd p
      endif
   else
      put =systemOut
      normal! ggdd
   endif
endfunction


function! vvcs#diff(file) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" displays the diff between the file specified and its predecessor on a new
" tab page
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   " let currentTab = tabpagenr()
   tabe
   " exe "nnoremap <buffer> q :diffo! <bar> tabc <bar> tabnext" currentTab "<CR>"
   call vvcs#diffDisplay(a:file)
   normal! gg]c
endfunction

function! vvcs#diffDisplay(file) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Read previous version of specified file on current window, then open the
" current version on a split and perform a diff. 
" Update s:compareFile variable accordingly.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   " exe "read !rf pred " . a:file
   vnew
   1wincmd w
   call vvcs#execute('pred', 0, a:file)
   call vvcs#setTempBuffer()
   call vvcs#compareFilesCommonMappings()
   diffthis
   2wincmd w
   exe "edit " . a:file
   let s:compareFile[1].bufNr = bufnr('%')
   let currentFt = &filetype
   diffthis
   wincmd p
   let &filetype=currentFt
endfunction

function! vvcs#diffLine() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Open the diff for the files on current line of comparison window
" @requires: must be called from vvcs#compareFiles()
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let file = substitute(getline('.'), '@.*','','')
   diffo!
   exe s:compareFile[1].winNr.'wincmd w'
   quit
   exe s:compareFile[0].winNr.'wincmd w'
   setlocal modifiable
   normal! ggdG
   call vvcs#diffDisplay(file)
endfunction

function! vvcs#setTempBuffer() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Select settings of a temporary/scratch buffer
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   setlocal buftype=nofile
   setlocal bufhidden=delete
   setlocal noswapfile
   setlocal nomodifiable
   setlocal textwidth=0 " avoid automatic line break
endfunction

function! vvcs#command(cmd, ...) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" same as vvc#op.execute(), using the current file as optional argument if
" none is available. Requires a single optional argument.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   if a:0 == 1
      call vvcs#execute(a:cmd, 0, a:1)
   else
      call vvcs#execute(a:cmd, 0, expand("%:p"))
   endif
   checktime  " warn for loaded files changed outside vim
endfunction

function! vvcs#checkout(file) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Checkout and retrieve the specified file
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   call vvcs#execute('checkout', 0, a:file)
   call vvcs#execute('down', 1, a:file)
   checktime  " warn for loaded files changed outside vim
endfunction

function! vvcs#codeReview() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Display diff of a list of files
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   """"""""""""""""""""""""
   "  Retrieve file list  "
   """"""""""""""""""""""""
   let lastDirCache = vvcs#readCacheFile(s:VVCS_CODE_REVIEW_BROWSE)
   let startDir = empty(lastDirCache) ? '.' : lastDirCache[0]
   let prompt = 'select file list to review'
   if has("browse")
      if exists('b:browsefilter')
         let save_browsefilter = b:browsefilter
      endif
      let b:browsefilter = "All Files\t*\nList Files (*.list)\t*.list\n"
      let fileList = browse('', prompt, startDir, '')
      if exists('save_browsefilter')
         let b:browsefilter = save_browsefilter
         unlet save_browsefilter
      else
         unlet b:browsefilter
      endif
   else
      let fileList = VvcsInput(prompt.': ', startDir.'/', 'file')
   endif
   if fileList == ''
      return
   endif
   call vvcs#writeCacheFile([fnamemodify(fileList, ":p:h")], 
            \ s:VVCS_CODE_REVIEW_BROWSE)

   """"""""""""""""""""""""""""""""""""""""
   "  Open new tab and display file list  "
   """"""""""""""""""""""""""""""""""""""""
   tabe
   vnew
   1wincmd w
   call vvcs#setTempBuffer()
   let s:compareFile[0].bufNr = bufnr('%')
   call vvcs#compareFilesCommonMappings()
   exe 'silent file '.s:VVCS_CODE_REVIEW_DIFF_LABEL[0]
   2wincmd w
   call vvcs#setTempBuffer()
   let s:compareFile[1].bufNr = bufnr('%')
   call vvcs#compareFilesCommonMappings()
   exe 'silent file '.s:VVCS_CODE_REVIEW_DIFF_LABEL[1]
   new
   exe '0read '.fileList
   exe 'silent file '.s:VVCS_CODE_REVIEW_LIST_TITLE .'\ '.fileList
   " Detect lines containing '/path/file@@version/N' and replace with
   " '/path/file@@version/N ; /path/file@@version/LATEST' 
   " procedure: match any line starting with '/path/file@@version/N' that
   " isn't doesn't contains ';' or 'LATEST', copy it, append ';' followed by the
   " copy, replacing the 'N' by 'LATEST'
   setlocal textwidth=0 " avoid automatic line break
   silent g/\v^[^@;]*\@\@((;|latest)@!.)*$/normal! y$A ; 0dvT/aLATEST
   call vvcs#setTempBuffer()
   let s:compareFile[2].bufNr = bufnr('%')
   wincmd J
   setlocal cursorline
   resize 8
   setlocal winfixheight
   call vvcs#compareFilesCommonMappings()
   " highlight filenames
   match SpecialKey /^.\{-}[/\\]\zs[^/\\]\+\ze@@/
   setlocal nowrap
   " TODO use argument to vvcs#compareFiles on the mappings instead of
   " s:CompareFileFunc in order to allow more than one simultaneous
   " comparison; s:CompareFileFunc should be changed to b:CompareFileFunc on
   " the file list buffer, and the \j \k mappings would have to change the
   " jump to be based on the buffer name
   let s:CompareFileFunc = function('vvcs#codeReviewOpen')
   nnoremap <buffer> <silent> <CR> :call vvcs#compareFiles(0)<CR>
   nnoremap <buffer> <silent> J :call vvcs#compareFiles(1)<CR>
   nnoremap <buffer> <silent> K :call vvcs#compareFiles(-1)<CR>
   1  " start on the first line

   """""""""""""""""""""""""
   "  Open the first diff  "
   """""""""""""""""""""""""
   " trigger the diff on the first line of the list
   normal J
endfunction

function! vvcs#codeReviewOpen() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Open the diff for the files on current line of comparison window
" @requires: must be called from vvcs#compareFiles()
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   " read the filenames
   let file = split(getline('.'), '\s*;\s*')
   " echo 'files = 'file
   if len(file) != 2
      call vvcs#error('codeReviewOpen: invalid number of files: '.len(file))
      return
   endif

   " display the files
   for i in range(2)
      exe s:compareFile[i].winNr.'wincmd w'
      diffoff
      setlocal modifiable
      normal! ggdG
      exe 'silent file '.s:VVCS_CODE_REVIEW_DIFF_LABEL[i].'\ '.
               \ substitute(file[i], '@.*','','')
      call vvcs#execute('-cInlineResult', i, 'cat '.file[i])
      " trigger autocmd to detect filetype and execute any filetype plugins
      doautocmd BufNewFile
      if line('$') > 1
         " check before 'diffthis' to avoid redraw problem when file is empty
         diffthis
      endif
      setlocal nomodifiable
   endfor
endfunction


function! vvcs#compareFilesCommonMappings() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" mappings applicable to all compareFile windows
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   nnoremap <buffer> <c-down> ]c
   nnoremap <buffer> <c-up> [c
   nnoremap <buffer> J ]c
   nnoremap <buffer> K [c
   nnoremap <buffer> <silent> q 
            \ :if confirm("Quit comparison?", "&Yes\n&No") == 1 <bar> 
            \ diffo! <bar> tabc <bar> endif<CR>
   nnoremap <buffer> <silent> <leader>j :call vvcs#compareFiles(1)<CR>
   nnoremap <buffer> <silent> <leader>k :call vvcs#compareFiles(-1)<CR>
endfunction


" s:compareFile holds the bufNumber for the 3 comparison windows
let s:compareFile = [ 
         \ {'name' : 'first diff'  , 'bufNr' : -1 , 'winNr' : -1},
         \ {'name' : 'second diff' , 'bufNr' : -1 , 'winNr' : -1},
         \ {'name' : 'file list'   , 'bufNr' : -1 , 'winNr' : -1},
\ ]
" TODO after moving to a separate dict this could be set only on
" vvcs#listCheckedOut
let s:compareMarkers = [
         \ s:VVCS_STAGED_MARKER,
         \ s:VVCS_NOT_STAGED_MARKER,
\ ]

function! vvcs#compareFiles(offset) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Handle selection of a line in the file list.
" The offset parameter indicates the line relative to current cursor position.
" Empty lines and lines starting with any of the strings on the compareMarkers
" list are skipped.
"
" Function reference s:CompareFileFunc is called when the cursor is on the line
" containing information about the files to be compared.
" It expects that s:compareFile dict contains the bufNumber for each of the
" comparison windows on current tab page.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

   for i in range(len(s:compareFile))
      let s:compareFile[i].winNr = bufwinnr(s:compareFile[i].bufNr)
      if s:compareFile[i].winNr  == -1
         call vvcs#error("missing comparison window: ".s:compareFile[i].name)
         return
      endif
   endfor
   " echo s:compareFile
   " return
   exe s:compareFile[2].winNr.'wincmd w'
   call cursor(line('.') + a:offset, 0)

   " skip empty and marker lines
   while getline('.') !~ '\S' || index(s:compareMarkers, getline('.')) != -1
      if (a:offset >= 0 && line('.') == line('$')) ||
               \ (a:offset < 0 && line('.') == 1)
         return
      endif
      call cursor(line('.') + (a:offset >= 0 ? 1 : -1), 0)
   endw
   redraw  " avoid that cursor move outside window

   call call(s:CompareFileFunc, [])

   " jump to the first error
   exe s:compareFile[0].winNr.'wincmd w'
   if line('$') > 1
      normal! gg]c
      " try to avoid some redraw problems
      exe s:compareFile[1].winNr.'wincmd w'
      normal! gg]c
      wincmd p
      redraw!
   else
      diffo!
      exe s:compareFile[1].winNr.'wincmd w'
   endif
endfunction


function! vvcs#listCheckedOut() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Display diff of currently checkouted files and its predecessors
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   """"""""""""""""""""""""""""""""""""""""
   "  Open new tab and display file list  "
   """"""""""""""""""""""""""""""""""""""""
   tabe
   call vvcs#setTempBuffer()
   " TODO: factor out the creation of the new tab from this function and reuse
   " it in vvcs#codeReview() and vvcs#diffDisplay() functions, which already
   " contain the fix for issue #8
   let s:compareFile[0].bufNr = bufnr('%')
   call vvcs#compareFilesCommonMappings()
   silent file Previous\ Version
   vnew
   let s:compareFile[1].bufNr = bufnr('%')
   new
   call append(0, '')
   call append(1, s:VVCS_STAGED_MARKER)
   call append(2, '')
   call append(3, s:VVCS_NOT_STAGED_MARKER)
   call append(4, '')
   4
   "  Retrieve file list
   silent call vvcs#execute('checkedoutList', 0)
   " change output to '/path/file@@version/N'
   %s/\v.*"([^"]+)"\s+from\s+(\S+).*/\1@@\2/e
   exe 'silent file '.s:VVCS_CODE_REVIEW_LIST_TITLE
   call vvcs#setTempBuffer()
   let s:compareFile[2].bufNr = bufnr('%')
   wincmd J
   setlocal cursorline
   resize 8
   setlocal winfixheight
   call vvcs#compareFilesCommonMappings()
   " highlight filenames
   match SpecialKey /^.\{-}[/\\]\zs[^/\\]\+\ze@@/
   setlocal nowrap
   " TODO use argument to vvcs#compareFiles on the mappings instead of
   " s:CompareFileFunc in order to allow more than one simultaneous comparison
   let s:CompareFileFunc = function('vvcs#diffLine')
   nnoremap <buffer> <silent> <CR> :call vvcs#compareFiles(0)<CR>
   nnoremap <buffer> <silent> J :call vvcs#compareFiles(1)<CR>
   nnoremap <buffer> <silent> K :call vvcs#compareFiles(-1)<CR>
   nnoremap <buffer> <silent> - :call vvcs#toggleStaged()<CR>
   nnoremap <buffer> <silent> <leader>cc :call vvcs#commitList()<CR>
   1  " start on the first line

   """""""""""""""""""""""""
   "  Open the first diff  "
   """""""""""""""""""""""""
   " trigger the diff on the first line of the list
   exe "normal \<CR>"
endfunction

function! vvcs#writeCacheFile(lines, file) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Write list of lines to file on cache directory (an existing file is
" overwritten)
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   if !isdirectory(g:vvcs_cache_dir)
      call vvcs#error("writeCacheFile(): no cache directory")
      return
   endif
   silent! call writefile(a:lines, g:vvcs_cache_dir.'/'.a:file)
endfunction

function! vvcs#readCacheFile(file) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Return list of lines from file on cache directory
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let fileName = g:vvcs_cache_dir.'/'.a:file
   if !filereadable(fileName)
      return []
   endif
   return readfile(fileName)
endfunction

function! vvcs#toggleStaged() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Toggles 'stage for changes' state of file on current line.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   if getline('.') !~ '\S'
      return
   endif
   setlocal modifiable
   let cLine = line('.')
   " check current state of the file - expects that staged files appears at
   " the beginning, followed by not staged files
   let startNotStaged = search(s:VVCS_NOT_STAGED_MARKER, 'bW')
   if startNotStaged != 0
      let commitMsg = VvcsInput("Commit message: ", "")
      if commitMsg =~ '\S'
         let lastStaged = search('\S', 'bW')
         exe cLine.'move '.lastStaged
         exe "normal! A\t".s:VVCS_COMMIT_MSG_MARKER.' '.commitMsg
         let cLine += 1    " made the cursor end on the next not staged file
      endif
   else
      $ " move to end of file
      let lastNotStaged = search('\S', 'bW')
      exe cLine.'move '.lastNotStaged
      call setline('.', substitute(getline('.'), '\s*'.
               \ s:VVCS_COMMIT_MSG_MARKER.'.*', '', ''))
   endif
   setlocal nomodifiable
   " restore cursor position when successful or aborting (no commit msg)
   exe cLine
endfunction

function! vvcs#commitList() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Commit stated files using the comment on the same line
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   """""""""""""""""""
   "  Retrieve list  "
   """""""""""""""""""
   let startStaged = search(s:VVCS_STAGED_MARKER, 'w')
   let startNotStaged = search(s:VVCS_NOT_STAGED_MARKER, 'w')
   let lines = getline(startStaged+1, startNotStaged-1)
   call filter(lines, 'v:val =~ "\S"') " remove blank lines
   call map(lines, 'substitute(v:val, ''^\s\+\|\s\+$'', "", "g")') " trim
   for line in lines
      let piece = split(line, '\s*'.s:VVCS_COMMIT_MSG_MARKER.'\s*') 
      " remove any version identifier
      let filename = substitute(piece[0], '@@.*', '', '')
      " TODO: execute 'up' on the containing dir and check that the file
      " doesn't appear on the list to verify that the commit is being
      " performed on the correct content - notify the user if the file on
      " remote is different
      call vvcs#execute('commit', 1, filename, piece[1])
      " TODO: after implementing error checking execute 'down' as the file may
      " have changed to 'readonly'
   endfor
endfunction



let &cpo = save_cpo
" vim: ts=3 sts=0 sw=3 expandtab ff=unix foldmethod=marker :
