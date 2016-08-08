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
         \'cmd': '"rsync -azv<overw:v:val?'''':''u''>C --stats ".
            \ s:rsyncExcludePat().
            \ " <path> -e ssh ".g:vvcs_remote_host.":/view/".
            \ g:vvcs_remote_repo."/".g:vvcs_remote_mark."<path>"',
         \'localCommand' : '',
   \},
   \'down' : {
         \'args' : ['<path>', '<overw:>'],
         \'cmd': '"rsync -azv<overw:v:val?'''':''u''>C --stats ".
            \ s:rsyncExcludePat().
            \ " -e ssh ".g:vvcs_remote_host.":/view/".g:vvcs_remote_repo.
            \ "/".g:vvcs_remote_mark."<path> <path>"',
         \'localCommand' : '',
   \},
   \'info' : {
         \'args' : ['<fileversion>', '<prev:>'],
         \'cmd':  '"echo -n \\`cleartool descr -short <prev:v:val?''-pred '' :''''>".
            \ "<fileversion>\\` | sed s/.\\*@//"',
         \'message' : 'retrieving info of <prev:v:val?''previous '':''''><fileversion> ...',
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
         \'adjustLine': 'vvcs#remote#toLocalPath('
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
" the remote root directory, as there is no svn command to retrieve this
" information (it is not present on 'svn info' of svn version 1.6.11)
let g:vvcs#remote#op['svn'] = { 
   \'up' : {
         \'args' : ['<path>', '<overw:>'],
         \'cmd': '"rsync -azv<overw:v:val?'''':''u''>C --stats ".
            \ s:rsyncExcludePat().
            \" <path> -e ssh ".  g:vvcs_remote_host.":".g:vvcs_remote_mark.
            \"<path>"', 
         \'localCommand' : '',
   \},
   \'down' : {
         \'args' : ['<path>', '<overw:>'],
         \'cmd': '"rsync -azv<overw:v:val?'''':''u''>C --stats ".
            \s:rsyncExcludePat().
            \" -e ssh ".g:vvcs_remote_host.":".g:vvcs_remote_mark.
            \"<path> <path>"',
         \'localCommand' : '',
   \},
   \ 'checkedoutList' : {
         \'args' : [],
         \'cmd':  '"svn status ".g:vvcs_fix_path["sub"]',
         \'message' : 'retrieving file list ...',
         \'adjustLine': 'vvcs#remote#toLocalPath('
               \ .'substitute(v:val, ''\v^\S\s*'', "", "g"))',
   \},
   \'isCheckedout' : {
         \'args' : ['<remFile>'],
         \'cmd':  '"svn status <remFile>"',
         \'message' : 'checking for modifications on <remFile> ...',
         \'adjustLine': '!empty(v:val)',
   \},
   \'info' : {
         \'args' : ['<fileversion>', '<prev:>'],
         \'cmd':  '"svn info <prev:v:val?''-r PREV '':''''><fileversion>"',
         \'message' : 'retrieving info '
               \ .'of <prev:v:val?''previous '':''''><fileversion> ...',
         \'adjustAll': 'substitute(v:val, '
               \ .'''\v.*\nURL:\s*(\p+).*Revision:\s*(\d+).*'', ''\1@\2'', '''')',
   \},
   \'catVersion' : {
         \'args' : ['<remFile>'],
         \'cmd': '"svn cat <remFile>"',
         \'silent' : '',
         \'message' : 'retrieving <remFile> ...',
   \},
   \'make' : {
         \'args' : ['<path>'],
         \'cmd':  '"cd ".g:vvcs_remote_mark."<path> && ".g:vvcs_make_cmd',
         \'silent' : '',
         \'message' : 'building <path> ...',
         \'dryRun' : '',
   \},
\}

function! vvcs#remote#execute(key, ...) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Run the command on the g:vvcs#remote#op dict for the specified key. 
"
" The return value starts with g:vvcs_PLUGIN_TAG if some error occurs.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   """"""""""""""""""""""""""""""""""
   "  Check for invalid parameters  "
   """"""""""""""""""""""""""""""""""
   let out = ''
   if !has_key(g:vvcs#remote#op, g:vvcs_remote_vcs)
      return vvcs#log#error('g:vvcs_remote_vcs invalid: '. g:vvcs_remote_vcs.
               \ "; valid values: ".string(keys(g:vvcs#remote#op)))
   endif
   let operation = g:vvcs#remote#op[g:vvcs_remote_vcs]
   if !has_key(operation, a:key)
      return vvcs#log#error('unknown command: '.a:key)
   endif
   if a:0 != len(operation[a:key].args)
      return vvcs#log#error("incorrect number of parameters for '".
               \ a:key."': ".string(a:000))
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
            return g:vvcs_PLUGIN_TAG.'s:handlePath error'
         endif
         " duplicate escapes as the substitute() below will remove them
         let val = escape(val, '\') 
         " apply the transformation from local path to the remote filesystem
         let remPath = vvcs#remote#toRemotePath(val)
         if empty(remPath)
            return g:vvcs_PLUGIN_TAG.'vvcs#remote#toRemotePath error'
         endif
         let cmd = substitute(cmd, g:vvcs_remote_mark . par, remPath, 'g')
      endif
      if par =~ ':'
         let parPattern = substitute(par, ':', ':\\([^>]*\\)', '')
         let cmd = substitute(cmd, parPattern, 
                  \ '\=eval(substitute(submatch(1), "v:val", val, ""))', 'g')
         if exists("l:message")
            let message = substitute(message, parPattern, 
                  \ '\=eval(substitute(submatch(1), "v:val", val, ""))', 'g')
         endif
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
   if has_key(operation[a:key], 'dryRun')
      return cmd
   else
      let out = VvcsSystem(cmd)
   endif

   """""""""""""""""""""""""
   "  Perform adjustments  "
   """""""""""""""""""""""""
   " echom "before adjustments: ".out
   if !g:VvcsSystemShellError
      if has_key(operation[a:key], 'filter')
         let out = join(filter(split(out, "\n"), 
                  \ operation[a:key]['filter']), "\n")
      endif
      if has_key(operation[a:key], 'adjustLine')
         let out = join(map(split(out, "\n"), 
                  \ operation[a:key]['adjustLine']), "\n")
      endif
      if has_key(operation[a:key], 'adjustAll')
         " echom "before: ".out
         " the purpose of adjustAll is to execute a command on the entire
         " result of a remote command, allowing a single substitute() to adapt
         " all the lines
         " using double eval to mimic map() double evaluation
         let out = eval(eval(substitute(
                  \ string(g:vvcs#remote#op['svn']['info']['adjustAll']),
                  \ 'v:val', "''".out."''", 'g')))
         " echom "after: ".out
      endif
   endif

   """""""""""""""""""""""
   "  Check for failure  "
   """""""""""""""""""""""
   if g:VvcsSystemShellError
      let errorMsg = vvcs#log#error("Failed to execute '".a:key."' ("
               \ .g:VvcsSystemShellError.")")
      call vvcs#log#append(split(out, "\n"))
      call vvcs#log#open()
      return errorMsg
   elseif !has_key(operation[a:key], 'silent')
      call vvcs#log#append(split(out, "\n"))
   endif

   return out
endfunction

function! vvcs#remote#toRemotePath(localPath) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Transform from local path to the remote filesystem (which uses forward
" slashes as path separator).
" Return empty string for invalid paths.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   let remPath = s:handlePath(a:localPath)
   if !empty(remPath)
      " use g:vvcs_fix_path without ending slashes (a mismatch could make the
      " result miss a slash)
      let pat = substitute(g:vvcs_fix_path.pat, '[\/]$', '', '')
      let sub = substitute(g:vvcs_fix_path.sub, '[\/]$', '', '')
      let remPath = substitute(remPath, '^'.pat, sub, '')
   endif
   return remPath
endfunction


function! vvcs#remote#toLocalPath(remotePath) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Transformation from remote path to the local filesystem.
" Do not check for invalid paths since it is possible that a file exists on
" the remote filesystem but wasn't copied to the local machine.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   " use g:vvcs_fix_path without ending slashes (a mismatch could make the
   " result miss a slash)
   let pat = substitute(g:vvcs_fix_path.pat, '[\/]$', '', '')
   let sub = substitute(g:vvcs_fix_path.sub, '[\/]$', '', '')
   let locPath = substitute(a:remotePath, '^'.sub, pat, '')
   if exists('+shellslash')
      let locPath = expand(locPath) " change to backslashes if necessary
   endif
   return locPath
endfunction



let &cpo = save_cpo
" vim: ts=3 sts=0 sw=3 expandtab ff=unix foldmethod=marker :
