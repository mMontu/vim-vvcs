" vvcs.vim: options and initialization, user interface handling
" Maintainer: Marcelo Montu 
" Repository: https://github.com/mMontu/vim-vvcs

let save_cpo = &cpo   " allow line continuation
set cpo&vim

" constants {{{1
let s:VVCS_CODE_REVIEW_BROWSE = "codeReviewBrowse" " cache file name
let s:VVCS_STAGED_MARKER = g:vvcs_review_comment.' Changes staged for commit:'
let s:VVCS_NOT_STAGED_MARKER = g:vvcs_review_comment.
         \ ' Changes not staged for commit:'

function! vvcs#command(cmd, ...) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" same as vvc#op.execute(), using the current file as optional argument if
" none is available. Requires a single optional argument.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let cmdName = 'Vc'.substitute(a:cmd, '\v(.)', '\U\1', '')
   call vvcs#log#startCommand(cmdName)
   if a:0 == 1
      let ret = vvcs#remote#execute(a:cmd, a:1)
   else
      let ret = vvcs#remote#execute(a:cmd, expand("%:p"))
   endif
   if !empty(ret['error'])
      return
   endif
   redraw
   call vvcs#log#msg(cmdName.' done')
   checktime  " warn for loaded files changed outside vim
endfunction

function! vvcs#diff() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Display diff of current file and it predecessor
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   call vvcs#log#startCommand('VcDiff')
   call vvcs#comparison#create([expand("%:p")])
endfunction

function! vvcs#checkout(file) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Checkout and retrieve the specified file
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   call vvcs#log#startCommand('VcCheckout')
   let ret = vvcs#remote#execute('checkout', a:file)
   if !empty(ret['error'])
      return
   endif
   let ret = vvcs#remote#execute('down', a:file)
   if !empty(ret['error'])
      return
   endif
   call vvcs#log#msg('VcCheckout done')
   checktime  " warn for loaded files changed outside vim
endfunction

function! vvcs#codeReview() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Display diff of a list of files
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   call vvcs#log#startCommand('VcCodeReview')
   """"""""""""""""""""""""
   "  Retrieve file list  "
   """"""""""""""""""""""""
   let lastDirCache = vvcs#utils#readCacheFile(s:VVCS_CODE_REVIEW_BROWSE)
   let startDir = empty(lastDirCache) ? '.' : lastDirCache[0]
   let prompt = 'select file list to review'
   if has("browse")
      if exists('b:browsefilter')
         let save_browsefilter = b:browsefilter
      endif
      let b:browsefilter = "All Files\t*\nList Files (*.list)\t*.list\n"
      let reviewFile = browse('', prompt, startDir, '')
      if exists('save_browsefilter')
         let b:browsefilter = save_browsefilter
         unlet save_browsefilter
      else
         unlet b:browsefilter
      endif
   else
      let reviewFile = VvcsInput(prompt.': ', startDir.'/', 'file')
   endif
   if reviewFile == ''
      return
   endif
   call vvcs#utils#writeCacheFile([fnamemodify(reviewFile, ":p:h")], 
            \ s:VVCS_CODE_REVIEW_BROWSE)

   """""""""""""""""""""""""""
   "  Check/adapt file list  "
   """""""""""""""""""""""""""
   let lines = readfile(reviewFile)
   " check for lines with single file and format '/path/file@@version/0'
   for elem in lines
      if elem =~ '\v^[^@;]*\@\@[^ \t@;]+<0\s*$'
         call vvcs#log#error('invalid line on review list: "'. elem.'"')
         return
      endif
   endfor

   " Detect lines containing only '/path/file@@version/N' and replace with
   " '/path/file@@version/N-1 ; /path/file@@version/N' 
   call map(lines, 'substitute(v:val, '.
      \ '''\v^(\s*[^ \t;@]+\@\@[^ \t;]{-})(\d+>)\s*$'', '.
      \ '''\=submatch(1).(submatch(2)-1)." ; ".submatch(1).submatch(2)'', "")')

   """""""""""""""""""""
   "  Prepare display  "
   """""""""""""""""""""
   if len(lines) < 2
      " ensure that review list is displayed
      call add(lines, "")
   endif
   call vvcs#comparison#create(lines)
   if vvcs#comparison#switchToListWindow()
      let cName = bufname('%')
      exe 'silent file '. cName .'\ '.reviewFile
   else
      call vvcs#log#error('codeReview: failed to set review list title')
      return
   endif
endfunction

function! vvcs#listCheckedOut() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Display diff of currently checkouted files and its predecessors
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   call vvcs#log#startCommand('VcListCheckedout')
   let retCheckedoutL = vvcs#remote#execute('checkedoutList')
   if !empty(retCheckedoutL['error'])
      return
   endif
   let fileList = "\n".s:VVCS_STAGED_MARKER."\n\n"
   let fileList .= s:VVCS_NOT_STAGED_MARKER."\n"
   let fileList .= retCheckedoutL['value']
   let fileList .= "\n\n"

   call vvcs#comparison#create(split(fileList, '\n'))
   if vvcs#comparison#switchToListWindow()
      nnoremap <buffer> <silent> - :call vvcs#toggleStaged()<CR>
      nnoremap <buffer> <silent> cc :call vvcs#commitList()<CR>
   else
      call vvcs#log#error('listCheckedOut: failed to create mappings')
      return
   endif
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
   " echom 'startNotStaged = '.startNotStaged
   if startNotStaged != 0
      let lastStaged = search('\S', 'bW')
      " echom 'lastStaged = '.lastStaged
      exe cLine.'move '.lastStaged
      let cLine += 1    " made the cursor end on the next not staged file
   else
      $ " move to end of file
      let lastNotStaged = search('\S', 'bWc')
      " echom 'lastNotStaged = '.lastNotStaged
      exe cLine.'move '.lastNotStaged
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
   let commitMsg = VvcsInput("Commit message: ", "")
   if commitMsg !~ '\S'
      return
   endif
   call filter(lines, 'v:val =~ ''\S''') " remove blank lines
   call map(lines, 'substitute(v:val, ''^\s\+\|\s\+$'', "", "g")') " trim
   for line in lines
      " TODO: execute 'up' on the containing dir and check that the file
      " doesn't appear on the list to verify that the commit is being
      " performed on the correct content - notify the user if the file on
      " remote is different
      let ret = vvcs#remote#execute('commit', line, commitMsg)
      if empty(ret['error'])
         call vvcs#remote#execute('down', line)
         checktime  " warn for loaded files changed outside vim
      else
         call vvcs#log#error("failed to commit '".line."'")
      endif
      " TODO: move successfully commited files to another list, to allow the
      " user to retry the commit after it solves problems like reserved
      " checkouts by another user
   endfor
endfunction

function! vvcs#getRemotePath() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Retrieve remote path of current file
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let remPath = vvcs#remote#toRemotePath(expand("%:p"))
   let @+ = remPath
   call vvcs#log#msg('VcGetRemotePath: '.remPath)

endfunction


let &cpo = save_cpo
" vim: ts=3 sts=0 sw=3 expandtab ff=unix foldmethod=marker :
