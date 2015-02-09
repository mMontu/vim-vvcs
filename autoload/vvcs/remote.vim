" vvcs#remote: functionality directly related to execution of remote commands
" Maintainer: Marcelo Montu 
" Repository: https://github.com/mMontu/vim-vvcs

let save_cpo = &cpo   " allow line continuation
set cpo&vim

function! s:handlePath(path) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Change relative to absolute paths. Return empty string for invalid paths.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let ret = fnamemodify(a:path, ":p")
   if !isdirectory(ret) && !filereadable(ret)
      call vvcs#log#error("invalid path: '".ret."'")
      return ''
   endif
   if exists('+shellslash')
      " adapt for ms-windows paths
      if !&shellslash
         setlocal shellslash!
         " change backslashes to slashes in path separator
         let ret = expand(ret)
         setlocal shellslash!
      endif
   endif
   let ret = escape(fnameescape(ret), '\')
   return ret
endfunction

function! s:rsyncExcludePat() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Return string containing rsync option to ignore several files.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let ret = ''
   for pat in g:vvcs_exclude_patterns
      let ret .= '--exclude "' . pat . '" '
   endfor
   return ret
endfunction


" g:vvcs#remote#op dictionary {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" common commands used to work on remote machines
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:vvcs#remote#op = {}
let g:vvcs#remote#op['ClearCase'] = { 
   \'up' : {
         \'args' : ['<path>', '<overw:>'],
         \'cmd': '"rsync -azv<overw:v:val?'''':''u''>C ".s:rsyncExcludePat().
            \ " <path> -e ssh ".g:vvcs_remote_host.":/view/".
            \ g:vvcs_remote_branch."/".g:vvcs_remote_mark."<path>"',
         \'localCommand' : '',
   \},
   \'down' : {
         \'args' : ['<path>', '<overw:>'],
         \'cmd': '"rsync -azv<overw:v:val?'''':''u''>C ".s:rsyncExcludePat().
            \ " -e ssh ".g:vvcs_remote_host.":/view/".g:vvcs_remote_branch.
            \ "/".g:vvcs_remote_mark."<path> <path>"',
         \'localCommand' : '',
   \},
   \'pred' : {
         \'args' : ['<filepath>'],
         \'cmd':  '"cat ".g:vvcs_remote_mark.
            \"<filepath>@@\`cleartool descr -pred -short ".g:vvcs_remote_mark.
            \"<filepath>\\`"',
         \'silent' : '',
         \'message' : 'retrieving previous version of <filepath> ...',
   \},
   \'checkout' : {
         \'args' : ['<path>'],
         \'cmd': '"ct co -unreserved -nc ".g:vvcs_remote_mark."<path>"',
   \},
   \'commit' : {
         \'args' : ['<path>', '<comment>'],
         \'cmd': '''ct ci -c \"<comment>\" ''.g:vvcs_remote_mark."<path>"',
         \'message' : 'committing <path> ...',
   \},
   \ 'checkedoutList' : {
         \'args' : [],
         \'cmd':  '"ct lsco -avobs -cview"',
         \'message' : 'retrieving file list ...',
         \'filter': 'v:val !~ "\\vadded (directory|file) element"',
         \'adjust': 'vvcs#remote#toLocalPath('
               \ .'substitute(v:val, ''\v.*"([^"]{-})".*'', "\\1", "g"))',
   \},
   \'catVersion' : {
         \'args' : ['<remFile>'],
         \'cmd': '"cat <remFile>"',
         \'silent' : '',
         \'message' : 'retrieving <remFile> ...',
   \},
   \'-c' : {
         \'args' : ['<cmd>'],
         \'cmd': '"<cmd>"',
   \},
\}


" Note: checkedoutList for svn assumes that g:vvcs_fix_path['sub'] contains
" the remote root directory, as it there is no svn command to retrieve this
" information (it is not present on 'svn info' of svn version 1.6.11)
let g:vvcs#remote#op['svn'] = { 
   \'up' : {
         \'args' : ['<path>', '<overw:>'],
         \'cmd': '"rsync -azv<overw:v:val?'''':''u''>C  ".s:rsyncExcludePat().
         \" <path> -e ssh ".  g:vvcs_remote_host.":".g:vvcs_remote_mark.
         \"<path>"', 'localCommand' : '',
   \},
   \'down' : {
         \'args' : ['<path>', '<overw:>'],
         \'cmd': '"rsync -azv<overw:v:val?'''':''u''>C ".s:rsyncExcludePat().
            \" -e ssh ".g:vvcs_remote_host.":".g:vvcs_remote_mark.
            \"<path> <path>"',
         \'localCommand' : '',
   \},
   \'pred' : {
         \'args' : ['<filepath>'],
         \'cmd':  '"svn cat --non-interactive -r HEAD ".g:vvcs_remote_mark.
            \ "<filepath>"',
         \'silent' : '',
         \'message' : 'retrieving previous version of <filepath> ...',
   \},
   \ 'checkedoutList' : {
         \'args' : [],
         \'cmd':  '"svn status ".g:vvcs_fix_path["sub"]',
         \'message' : 'retrieving file list ...',
         \'adjust': 'vvcs#remote#toLocalPath('
               \ .'substitute(v:val, ''\v^\S\s*'', "", "g"))',
   \},
\}

function! vvcs#remote#execute(key, ...) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Run the command on the g:vvcs#remote#op dict for the specified key. 
"
" Returns a dictionary (ret), where ret['error'] contains the error message
" and ret['value'] contains valid information iff empty(ret['error']).
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   """"""""""""""""""""""""""""""""""
   "  Check for invalid parameters  "
   """"""""""""""""""""""""""""""""""
   let ret = {'error' : '', 'value' : ''}
   if !has_key(g:vvcs#remote#op, g:vvcs_remote_vcs)
      let ret['error'] = vvcs#log#error('g:vvcs_remote_vcs invalid: '.
               \ g:vvcs_remote_vcs."; valid values: ".
               \ string(keys(g:vvcs#remote#op)))
      return ret
   endif
   let operation = g:vvcs#remote#op[g:vvcs_remote_vcs]
   if !has_key(operation, a:key)
      let ret['error'] = vvcs#log#error('unknown command: '.a:key)
      return ret
   endif
   if a:0 != len(operation[a:key].args)
      let ret['error'] = vvcs#log#error("incorrect number of parameters for '".
               \ a:key."': ".string(a:000))
      return ret
   endif

   """""""""""""""""""""""""""""""""""""""""""""""""""""""""
   "  Insert paremters on the remote command placeholders  "
   """""""""""""""""""""""""""""""""""""""""""""""""""""""""
   if has_key(operation[a:key], 'message')
      let message = operation[a:key]['message']
   endif
   let cmd = eval(operation[a:key].cmd)
   for i in range(len(operation[a:key].args))
      let par = operation[a:key].args[i]
      let val = a:000[i]
      if par =~# 'path'
         let val = s:handlePath(val)
         if empty(val)
            let ret['error'] = 's:handlePath error'
            return ret
         endif
         " duplicate escapes as the substitute() below will remove them
         let val = escape(val, '\') 
         " apply the transformation from local path to the remote filesystem
         let remPath = vvcs#remote#toRemotePath(val)
         if empty(remPath)
            let ret['error'] = 'vvcs#remote#toRemotePath error'
            return ret
         endif
         let cmd = substitute(cmd, g:vvcs_remote_mark . par, remPath, 'g')
      endif
      if par =~ ':'
         let parPattern = substitute(par, ':', ':\\([^>]*\\)', '')
         let cmd = substitute(cmd, parPattern, 
                  \ '\=eval(substitute(submatch(1), "v:val", val, ""))', 'g')
      endif
      let cmd = substitute(cmd, par, val, 'g')
      if exists("l:message")
         let message = substitute(message, par, val, 'g')
      endif
   endfor

   """"""""""""""""""""""""""""
   "  Execute remote command  "
   """"""""""""""""""""""""""""
   call vvcs#log#append(["'Will execute: ".cmd."'"])
   if !has_key(operation[a:key], 'localCommand')
      let cmd = printf(g:vvcs_remote_cmd, cmd)
   endif
   if has_key(operation[a:key], 'message')
      call vvcs#log#msg(message)
   endif
   let ret['value'] = VvcsSystem(cmd)
   if has_key(operation[a:key], 'filter')
      let ret['value'] = join(filter(split(ret['value'], "\n"), 
               \ operation[a:key]['filter']), "\n")
   endif
   if has_key(operation[a:key], 'adjust')
      let ret['value'] = join(map(split(ret['value'], "\n"), 
               \ operation[a:key]['adjust']), "\n")
   endif

   """""""""""""""""""""""
   "  Check for failure  "
   """""""""""""""""""""""
   if g:VvcsSystemShellError
      let ret['error'] = vvcs#log#error("Failed to execute '".a:key."' ("
               \ .g:VvcsSystemShellError.")")
      call vvcs#log#append(split(ret['value'], "\n"))
      call vvcs#log#open()
      return ret
   elseif !has_key(operation[a:key], 'silent')
      call vvcs#log#append(split(ret['value'], "\n"))
   endif

   return ret
endfunction

function! vvcs#remote#toRemotePath(localPath) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Transform from local path to the remote filesystem (which uses forward
" slashes as path separator).
" Return empty string for invalid paths.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let remPath = s:handlePath(a:localPath)
   if !empty(remPath)
      let remPath = substitute(remPath, '^'.g:vvcs_fix_path.pat,
                  \ g:vvcs_fix_path.sub, '')
   endif
   return remPath
endfunction


function! vvcs#remote#toLocalPath(remotePath) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Transformation from remote path to the local filesystem.
" Do not check for invalid paths since it is possible that a file exists on
" the remote filesystem but wasn't copied to the local machine.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let locPath = substitute(a:remotePath, '^'.g:vvcs_fix_path.sub,
                  \ g:vvcs_fix_path.pat, '')
   if exists('+shellslash')
      let locPath = expand(locPath) " change to backslashes if necessary
   endif
   return locPath
endfunction



let &cpo = save_cpo
" vim: ts=3 sts=0 sw=3 expandtab ff=unix foldmethod=marker :
