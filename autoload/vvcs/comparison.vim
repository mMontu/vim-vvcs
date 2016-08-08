" vvcs#comparison: display file comparison on a new tab
" Maintainer: Marcelo Montu 
" Repository: https://github.com/mMontu/vim-vvcs

let save_cpo = &cpo   " allow line continuation
set cpo&vim

" constants {{{1
let s:VVCS_CODE_REVIEW_DIFF_LABEL = ['OLD', 'NEW']

" g:vvcs#comparison#get dictionary {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" common (local) tasks for each version control system
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:vvcs#comparison#get = {}
let g:vvcs#comparison#get.ClearCase = {}  " {{{2
function! g:vvcs#comparison#get['ClearCase'].pathAndVersion(index, list) dict
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Return a pair of path@version for the line on a list of files. 
"
" Each line on the list may contain:
"
"  * two filenames separeted by a semi-colon (TODO: or spaces)
"  * a single filename without version specified -- on this case it will be
"     compared against the previous version based on the current branch/config
"     spec
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let item = a:list[a:index]
   if isdirectory(vvcs#remote#toLocalPath(item))
      return [] " no diff for directories
   endif

   let ret = []
   if item =~ ';'
      " two files specified
      let splitItem = split(item, '\s*;\s*')
      if len(splitItem) != 2
         return [g:vvcs_PLUGIN_TAG.'invalid number of files: '.len(splitItem)]
      else
         let ret = splitItem
      endif
   else  " item !~ ';'
      if item =~ "@@"
         let [path, rev] = split(item, '@@')
         let rev = '@@'.rev
      else
         let [path, rev] = [item, '']
      endif
      " remote command info expects remote path and possible version identifier
      if filereadable(path)
         let path = vvcs#remote#toRemotePath(path)
         " call vvcs#log#msg("converted path: ".path)
      endif
      call add(ret, path."@@".vvcs#remote#execute('info', path.rev, 1))
      if ret[len(ret)-1] !~# '\V'.g:vvcs_PLUGIN_TAG
         call add(ret, path."@@".vvcs#remote#execute('info', path.rev, 0))
      endif
   endif

   return ret
endfunction

let g:vvcs#comparison#get.svn = {}  " {{{2
function! g:vvcs#comparison#get['svn'].pathAndVersion(index, list) dict
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Return a pair of path@version for the line on a list of files. 
"
" The list may contains:
"
"  * no branch/revision specified: shows diff between the current and previous
"     version on the working copy
"  * file name(s) followed by branch/revision identification on separated
"     lines
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let item = a:list[a:index]
   if isdirectory(vvcs#remote#toLocalPath(item))
      return [] " no diff for directories
   endif

   let ret = []
   
   let COMMMITED_REV_PAT = '\vCommitted revision\s*(\d+)\..*'
   let revIdx = vvcs#utils#indexRegex(a:list, COMMMITED_REV_PAT, a:index, 0, 1)
   let rev = -1
   if revIdx != -1
      let rev = substitute(a:list[revIdx], COMMMITED_REV_PAT, '\1', '')
   endif
   " call vvcs#log#msg("revision: ".rev)

   if rev != -1
      " search branch
      let BRANCH_PAT = '\vCommitted revision\s*\d+\.\s*(\S+).*'
      let branchIdx = vvcs#utils#indexRegex(a:list, BRANCH_PAT, a:index, 0, 1)
      if branchIdx == -1
         let ret = [g:vvcs_PLUGIN_TAG.'unable to determine the branch']
      else
         let item = substitute(item, '\v^\s*Sending\s+', '', '')
         let branch = substitute(a:list[branchIdx], BRANCH_PAT, '\1', '')
         " call vvcs#log#msg("branch: ".branch)
         " let item = g:vvcs_remote_repo.'/'.branch.'/'.item.'@'.rev
         " call add(ret, vvcs#remote#execute('info', item, 1))
         " call add(ret, vvcs#remote#execute('info', item, 0))
         let item = g:vvcs_remote_repo.'/'.branch.'/'.item
         call add(ret, item.'@'.(rev-1))
         call add(ret, item.'@'.rev)
      endif
   else  " rev == -1
      if filereadable(item)
         " commands below expect remote path
         let item = vvcs#remote#toRemotePath(item)
         " call vvcs#log#msg("converted path: ".item)
      endif

      let isCheckedout = vvcs#remote#execute('isCheckedout', item)
      if isCheckedout =~# g:vvcs_PLUGIN_TAG
         return [isCheckedout]
      endif

      if isCheckedout
         call add(ret, vvcs#remote#execute('info', item, 0))
         if ret[len(ret)-1] !~# '\V'.g:vvcs_PLUGIN_TAG
            call add(ret, item."@checkedout")
         endif
      else
         call add(ret, vvcs#remote#execute('info', item, 1))
         if ret[len(ret)-1] !~# '\V'.g:vvcs_PLUGIN_TAG
            call add(ret, vvcs#remote#execute('info', item, 0))
            " NOTE: maybe change the line above to @checkedout to avoid one
            " 'info' if it becomes too slow; 
         endif
      endif
   endif

   return ret
endfunction

function! vvcs#comparison#createSingle(files) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Create a new tab with two windows and display the diff of file specified in
" the string a:file.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   call s:createDiffWindows()
   let t:compareFile[2].bufNr = -1
   call s:compareItem(0, [a:files])
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
   let initialWindow = winnr()
   exe t:compareFile[2].winNr.'wincmd w'
   call cursor(line('.') + a:offset, 0)

   """""""""""""""""""""""""""""""""""""""""""""""""
   "  skip empty, commented and unimportant lines  "
   """""""""""""""""""""""""""""""""""""""""""""""""
   let IGNORE_PAT = ['Committed revision', 'Transmitting file data']
   let ignore = '('.join(IGNORE_PAT, '|').')'
   let comment = '('.join(g:vvcs_review_comment, '|').')'
   while getline('.') =~ '\v^\s*%($|('.ignore.'|'.comment.'))'
      if (a:offset >= 0 && line('.') == line('$')) ||
               \ (a:offset < 0 && line('.') == 1)
         return
      endif
      call cursor(line('.') + (a:offset >= 0 ? 1 : -1), 0)
   endw
   redraw  " avoid that cursor move outside window
   let files = getline(0, '$') 
   if g:vvcs_remote_vcs =~# 'ClearCase'
      let files = map(files, 
               \ 'substitute(v:val, "\\v\\s*".comment.".*", "", "")')
   endif
   call s:compareItem(line('.')-1, files)
   exe initialWindow.'wincmd w'
endfunction

function! s:compareItem(index, list) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Handle a line in the file list or a single diff 
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   " call vvcs#log#msg("index: ".a:index.", list: ".string(a:list))
   let pathAndVer = g:vvcs#comparison#get[g:vvcs_remote_vcs].pathAndVersion(
            \ a:index, a:list)
   " call vvcs#log#msg("vers: ".string(pathAndVer))
   " return
   if empty(pathAndVer)
      call vvcs#log#msg("no diff to display")
      return
   else
      for elem in pathAndVer
         if elem =~# '\V'.g:vvcs_PLUGIN_TAG
            call vvcs#log#error(substitute(elem, g:vvcs_PLUGIN_TAG, '', ''))
            return
         endif
      endfor
   endif

   let file = [
            \ {'name' : '', 'cmd' : ''},
            \ {'name' : '', 'cmd' : ''},
   \ ]
   for i in range(len(pathAndVer))
      let splitPath = split(pathAndVer[i], '@\+')
      if pathAndVer[i] =~ 'checkedout'
         let file[i].cmd = 'silent edit '.vvcs#remote#toLocalPath(splitPath[0])
      else
         " remove the repo identification or use the tail of the file name
         if splitPath[0] =~ g:vvcs_remote_repo
            let path = substitute(splitPath[0], g:vvcs_remote_repo, '', '')
         else
            let path = fnamemodify(splitPath[0], ":t")
         endif
         let versTail = substitute(splitPath[1], '\v.*/([^/]+/[^/]+$)', '\1', '')
         let file[i].name = "[".versTail."] ".path
         let file[i].cmd = "call s:setLines(".
                  \ "vvcs#remote#execute('catVersion', '".pathAndVer[i]."'))"
      endif
   endfor

   diffoff!
   " display the files
   for i in range(2)
      exe t:compareFile[i].winNr.'wincmd w'
      enew
      call s:setTempBuffer()
      setlocal modifiable
      call s:commonMappings()
      exe 'silent file '.
               \ s:getTempFileName(s:VVCS_CODE_REVIEW_DIFF_LABEL[i], file[i].name)
      exe file[i].cmd
      " if &buftype != 'nofile'
         let t:compareFile[i].bufNr = bufnr('%') " bufNr changes if cmd is edit
      " endif
      " trigger autocmd to detect filetype and execute any filetype plugins
      silent doautocmd BufNewFile
      if !exists("noDiff") && (line('$') > 1 || getline(1) != '')
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
      " normal! ]c
      " redraw!
      " normal! zb
      " redraw!
      " try to avoid some redraw problems
      exe t:compareFile[1].winNr.'wincmd w'
      normal! gg
      redraw!
      wincmd p
      " redraw
      " normal! gg]c
      " redraw
   else
      diffo!
      exe t:compareFile[1].winNr.'wincmd w'
      redraw! " avoid hit-enter message
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
   " 'q' closes without confirmation when there is no review list
   nnoremap <buffer> <silent> q 
            \ :if t:compareFile[2].bufNr == -1 <bar><bar>
            \        VvcsConfirm("Quit comparison?", "&Yes\n&No") == 1 <bar>
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


function! s:setLines(content) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Replace the current line with the specified string (which may spam multiple
" lines).
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   " Using :put avoids some problems from call setline(getline('.'),
   " split('...', '\n')). E.g.: if the string starts with a newline them
   " split() will remove it. If the keepempty is set, split will include the
   " first empty line, but it will also include an extra one at the end if the
   " last line ends in '\n'.
   "
   " Note that both ':put =var' and 'setline()' don't work for a:content that
   " contains text in dos format -- '^M' is displayed at every line. It seems
   " that the file format option is ignored for these commands.
   silent put =a:content 
   " delete original line
   silent '[-1delete _
endfunction

function! s:getTempFileName(prefix, currentName) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Return the name for a temporary file, suitable for :file command.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let name = a:prefix.' '.a:currentName

   " check if the name is already in used
   let i = 1
   while buflisted(name)
      let name = a:prefix.' ('.i.') '.a:currentName
      let i += 1
   endw

   " escape spaces for :file command
   let name = substitute(name, ' ', '\\&', 'g')
   return name
endfunction



let &cpo = save_cpo
" vim: ts=3 sts=0 sw=3 expandtab ff=unix foldmethod=marker :
