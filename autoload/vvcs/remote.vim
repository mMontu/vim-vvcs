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
let g:vvcs#remote#op = { 
   \'up' : {
         \'args' : ['<path>'],
         \'cmd': "rsync -azv ".s:rsyncExcludePat()." <path> -e ssh ".
         \ g:vvcs_remote_host.":/view/".g:vvcs_remote_branch.'/'.
         \ g:vvcs_remote_mark."<path>",
         \'localCommand' : '',
   \},
   \'down' : {
         \'args' : ['<path>'],
         \'cmd': "rsync -azv ".s:rsyncExcludePat()." -e ssh ".
         \ g:vvcs_remote_host.":/view/".g:vvcs_remote_branch.'/'.
         \ g:vvcs_remote_mark."<path> <path>",
         \'localCommand' : '',
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
         \'cmd': "ct co -unreserved -nc ".g:vvcs_remote_mark."<path>",
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
         \'returnResult' : '',
         \'fileList' : '',
   \},
\}


function! vvcs#remote#execute(key, keepRes, ...) " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Run the command on the g:vvcs#remote#op dict for the specified key. The
" quickfix is filled with the log of the execution. If keepRes is not set the
" quickfix is cleared before start logging.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   if !has_key(g:vvcs#remote#op, a:key)
      call vvcs#log#error('unknown command: ' . a:key)
      return 1
   endif
   if a:0 != len(g:vvcs#remote#op[a:key].args)
      call vvcs#log#error("incorrect number of parameters for '".a:key.
               \ "': ".string(a:000))
      return 1
   endif

   let cmd = g:vvcs#remote#op[a:key].cmd
   for i in range(len(g:vvcs#remote#op[a:key].args))
      let par = g:vvcs#remote#op[a:key].args[i]
      let val = a:000[i]
      if par =~# 'path'
         let val = s:handlePath(val)
         " duplicate escapes as the substitute() below will remove them
         let val = escape(val, '\') 
         if val == ''
            return 1
         endif
         " apply the transformation from local path to the remote filesystem
         let remPath = substitute(val, '^'.g:vvcs_fix_path.pat,
                  \ g:vvcs_fix_path.sub, '')
         let cmd = substitute(cmd, g:vvcs_remote_mark . par, remPath, 'g')
      endif
      let cmd = substitute(cmd, par, val, 'g')
   endfor

   exe (a:keepRes ?'caddexp' : 'cgetexpr').' ''Will execute: '.cmd."'"
   call vvcs#log#append(["'Will execute: ".cmd."'"])
   if !has_key(g:vvcs#remote#op[a:key], 'localCommand')
      let cmd = printf(g:vvcs_remote_cmd, cmd)
   endif
   let systemOut = VvcsSystem(cmd)
   if has_key(g:vvcs#remote#op[a:key], 'fileList')
      " apply the transformation from remote path to the local filesystem on
      " each line of the file list received
      let systemOut = join(
            \ map(split(systemOut, "\n"), 
            \ 'substitute(v:val, g:vvcs_fix_path.sub, g:vvcs_fix_path.pat,"")'),
            \ "\n")
   endif
   if has_key(g:vvcs#remote#op[a:key], 'inlineResult')
      put =systemOut
      normal! ggdd
   elseif has_key(g:vvcs#remote#op[a:key], 'returnResult')
      call vvcs#log#append(split(systemOut, "\n"))
      return systemOut
   else
      call vvcs#log#append(split(systemOut, "\n"))
      " caddexp printf(g:vvcs_remote_cmd, cmd)
      caddexp systemOut
      if exists('g:vvcs_debug')
         copen
         wincmd p
      endif
   endif
endfunction




let &cpo = save_cpo
" vim: ts=3 sts=0 sw=3 expandtab ff=unix foldmethod=marker :
