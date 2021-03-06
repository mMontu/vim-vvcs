" vvcs.vim: options and initialization, user interface handling
" Maintainer: Marcelo Montu 
" Repository: https://github.com/mMontu/vim-vvcs

let save_cpo = &cpo   " allow line continuation
set cpo&vim

" constants {{{1
let s:VVCS_CODE_REVIEW_BROWSE = "codeReviewBrowse" " cache file name
let s:VVCS_STAGED_MARKER = g:vvcs_review_comment[0].' Changes staged for commit:'
let s:VVCS_NOT_STAGED_MARKER = g:vvcs_review_comment[0].
         \ ' Changes not staged for commit:'
let s:VVCS_LIST_CHECKEDOUT_FILE = "listCheckedout.review" 

function! vvcs#up(overwrite, ...) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Send files on specified path (default: g:vvcs_default_path) to the remote
" machine.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let path = fnamemodify((a:0 ? a:1 : eval(g:vvcs_default_path)), ":p")
   if vvcs#utils#isProjectLogFile(path)
      if VvcsConfirm("This seems to be a log file, thus it shouldn't be ".
               \ "edited locally.\nProceed sending it to ".
               \ "the remote machine?", "&Continue\n&Abort", 2) != 1 
         return
      endif
   endif
   call vvcs#log#startCommand('VcUp', path)
   let ret = vvcs#remote#execute('up', path, a:overwrite)
   if ret =~# '^\V'.g:vvcs_PLUGIN_TAG
      call vvcs#log#commandFailed('VcUp')
   endif
   call vvcs#log#commandSucceed('VcUp', substitute(ret, 
            \ '\v.*files transferred: (\d+).*', 
            \ '\=submatch(1)." file".(submatch(1) == 1 ? "" : "s")', ''))
endfunction

function! vvcs#down(overwrite, autoread, ...) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Retrieve files on specified path (default: g:vvcs_default_path) from the
" remote machine.
" If a:autoread is set (or the file is in g:vvcs_project_log path) and a
" single file is specified then it is reloaded without confirmation.
" Return true if succeeds.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let path = fnamemodify((a:0 ? a:1 : eval(g:vvcs_default_path)), ":p")
   call vvcs#log#startCommand('VcDown', path)
   let ret = vvcs#remote#execute('down', path, a:overwrite)
   if ret =~# '^\V'.g:vvcs_PLUGIN_TAG
      call vvcs#log#commandFailed('VcDown')
      return 0
   endif
   let restoreBuf = 0
   if a:autoread || vvcs#utils#isProjectLogFile(path)
      let bufNum = bufnr(path)
      let bufAutoRead = getbufvar(bufNum, "&autoread")
      if bufNum != -1 && !bufAutoRead
         " skip reload confirmation by temporary setting 'autoread'
         call setbufvar(bufNum, "&autoread", 1)
         let restoreBuf = 1
      endif
   endif
   checktime  " warn for loaded files changed outside vim
   if restoreBuf
      call setbufvar(bufNum, "&autoread", 0)
   endif
   call vvcs#log#commandSucceed('VcDown', substitute(ret, 
            \ '\v.*files transferred: (\d+).*', 
            \ '\=submatch(1)." file".(submatch(1) == 1 ? "" : "s")', ''))
   return 1
endfunction

function! vvcs#diff() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Display diff of current file and it predecessor
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   call vvcs#comparison#createSingle(expand("%:p"))
endfunction

function! vvcs#checkout(autoread, file) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Checkout and retrieve the specified file
"
" If the file is readonly/unmofied or a:autoread is set it will be reloaded
" without asking for confirmation. 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   call vvcs#log#startCommand('VcCheckout')
   let ret = vvcs#remote#execute('checkout', a:file)
   if ret !~# '^\V'.g:vvcs_PLUGIN_TAG
      if vvcs#down(1, a:autoread || (&readonly && !&modified), a:file)
         call vvcs#log#commandSucceed('VcCheckout')
         return
      endif
   endif
   call vvcs#log#commandFailed('VcCheckout')
endfunction

function! vvcs#codeReview() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Display diff of a list of files
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   " TODO: move to utils#browse(prompt, histCacheFile?)
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
      " TODO: replace .list with the extension select for syntax highlight
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

   """"""""""""""""""""""""
   "  display comparison  "
   """"""""""""""""""""""""
   call vvcs#comparison#create(reviewFile)
endfunction

function! vvcs#listCheckedOut() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Display diff of currently checkouted files and its predecessors
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let retCheckedoutL = vvcs#remote#execute('checkedoutList')
   if retCheckedoutL =~# '^\V'.g:vvcs_PLUGIN_TAG
      return
   endif
   let fileList = "\n".s:VVCS_STAGED_MARKER."\n\n"
   let fileList .= s:VVCS_NOT_STAGED_MARKER."\n"
   let fileList .= retCheckedoutL
   let fileList .= "\n\n"
   let file = vvcs#utils#writeCacheFile(split(fileList, '\n'), 
            \ s:VVCS_LIST_CHECKEDOUT_FILE)

   call vvcs#comparison#create(file)
   if vvcs#comparison#switchToListWindow()
      nnoremap <buffer> <silent> - :call vvcs#toggleStaged()<CR>
      nnoremap <buffer> <silent> cc :call vvcs#commitList()<CR>
      " TODO: include v? to display help file, similar to fugitive g?
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
      call vvcs#log#msg("empty message - aborted")
      return
   endif
   call vvcs#log#startCommand('Commit')
   let fail = 0
   call filter(lines, 'v:val =~ ''\S''') " remove blank lines
   call map(lines, 'substitute(v:val, ''^\s\+\|\s\+$'', "", "g")') " trim
   for line in lines
      " TODO: execute 'up' on the containing dir and check that the file
      " doesn't appear on the list to verify that the commit is being
      " performed on the correct content - notify the user if the file on
      " remote is different
      let ret = vvcs#remote#execute('commit', line, commitMsg)
      if ret !~# '^\V'.g:vvcs_PLUGIN_TAG
         exe 'VcDown! '.line
      else
         call vvcs#log#error("failed to commit '".line."'")
         let fail = 1
      endif
      " TODO: move successfully commited files to another list, to allow the
      " user to retry the commit after it solves problems like reserved
      " checkouts by another user
   endfor
   if fail
      call vvcs#log#commandFailed('Commit')
   else
      call vvcs#log#commandSucceed('Commit')
   endif
endfunction

function! vvcs#getRemotePath() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Retrieve remote path of current file
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let remPath = vvcs#remote#toRemotePath(expand("%:p"))
   let @+ = remPath
   call vvcs#log#msg('VcGetRemotePath: '.remPath)
endfunction

function! vvcs#make(...) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Execute a build at specified path (default: g:vvcs_default_path) on the
" remote machine.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let path = fnamemodify((a:0 ? a:1 : eval(g:vvcs_default_path)), ":p")
   exe "VcUp ".path
   call vvcs#log#startCommand('VcMake', path)
   let makeprgSave = &makeprg
   let &makeprg = vvcs#remote#execute('make', path)
   echom "&makeprg = ".&makeprg
   " XXX how to handle the different paths for VcUp and make? extracting 'cd
   " path' from g:vvcs_make_cmd may not work if it refers to a directory that
   " is only present at remote directory 
   " maybe it is better to change vvcs_default_path to vvcs_sync_path, and
   " create a vvcs_make_path - make cd to vvcs_make_path, run make, then
   " cd to the previous dir
   " maybe don't change the current dir on vim, just pass the path to
   " remote#execute(..., 'dryRun')
   cd Debug
   pwd
   " it is easier to fill the quickfix using make; it also has the advantage
   " of displaying the regular behavior of a make (triggering autocmds, etc)
   " XXX XXX XXX this works only if "augroup changeQfCmdDir" is disabled
   make
   let &makeprg = makeprgSave
   " XXX echom "ret = ".ret
   " XXX if ret =~# '^\V'.g:vvcs_PLUGIN_TAG
   " XXX    quit " close the log window
   " XXX endif
   " XXX " based on  https://github.com/MarcWeber/vim-addon-qf-layout
   " XXX copen
   " XXX setl modifiable
   " XXX %delete
   " XXX call append(1, split(ret, "\n"))
  
   " XXX maybe call make directly here, either replicating part of remote.vim
   " here in order to include the ssh command, or include an extra key on the
   " dictionary (dry-run) in order to return the command without executing;
   " It maybe necessary to execute the 'cd Debug' at the start of the
   " g:vvcs_make_cmd in order to find the files from the quickfix

   " XXX maybe copy part from function! MakeMake() on .vimrc
endfunction


let &cpo = save_cpo
" vim: ts=3 sts=0 sw=3 expandtab ff=unix foldmethod=marker :
