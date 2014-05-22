source ../plugin/vvcs.vim
" Mainly due to autoload folder
let &runtimepath = expand('<sfile>:p:h:h') . ',' . &runtimepath

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                           Stub for system calls                            "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let rsyncPrefix = "receiving file list ... done\n"
let rsyncSuffix = "sent 186 bytes  received 138 bytes  58.91 bytes/sec\n".
         \ 'total size is 2170  speedup is 6.70'

let s:systemStub = {
   \'\<rsync\>' : {
         \'readWrite.h': rsyncPrefix."\n".rsyncSuffix,
         \'checkoutOk.h': rsyncPrefix."\n".rsyncSuffix,
         \'readOnly.h': rsyncPrefix.'rsync: rename "/AuxFiles/readOnly.h'.
         \  '.KvXBFe -> /AuxFiles/readOnly.h" failed: Read-only file '.
         \  'system (30)"'."\n".rsyncSuffix."\nrsync error: some files could".
         \  " not be transferred (code 23) at main.c(1146)",
         \'invalidDir.h': rsyncPrefix.'rsync: mkstemp "/AuxFiles/readOnly.h'.
         \  '.KvXBFe" failed: No such file or directory (2)"'."\n".rsyncSuffix.
         \  "\nrsync error: some files could not be transferred (code 23) at ".
         \  "main.c(1146)",
   \},
   \'\<cat\>.*cleartool descr -pred': {
         \'readOnly.h' : 'readOnly.h previous contents',
         \'invalidDir.h': 'cleartool: Error: Unable to access '.
         \   '"/AuxFiles/invalidDir.h": No such file or directory.',
   \},
   \'\<cat\> \S*@@\S*$': {
         \'readOnly.h' : '%s contents',
   \},
   \'\<ct co\>' : {
         \'readOnly.h': 'Checked out "/AuxFiles/readOnly.h" from version '.
         \  '"/main/myBranch/2".',
         \'checkoutOk.h': 'Checked out "/AuxFiles/checkoutOk.h" from version '.
         \  '"/main/myBranch/2".',
         \'readWrite.h': 'cleartool: Error: Element /AuxFiles/readWrite.h" '.
         \  'is already checked out to view "myView".',
         \'invalidDir.h': 'cleartool: Error: Unable to access "/AuxFiles/'.
         \  'invalidDir.h": No such file or directory.',
   \},
   \'\<ct ci\>' : {
         \'readWrite.h': 'Checked in "/AuxFiles/readWrite.h" version '.
         \  '"/main/myBranch/2".',
         \'readOnly.h': 'cleartool: Error: No branch of element is checked '.
         \  'out to view "/main/myBranch/2"'."\ncleartool: Error: Unable to ".
         \  'find checked out version for "/AuxFiles/readOnly.h".',
         \'invalidDir.h': 'cleartool: Error: Element name not found: '.
         \  '"/AuxFiles/invalidDir.h".',
   \},
\}

function! VvcsSystem(expr)
   let remoteCmd = substitute(a:expr, matchstr(g:vvcs_remote_cmd, 
            \ '.\{-}\ze[''"]*%s'), '', '')
   if  remoteCmd =~ 'sshError\.h'
      return 'ssh: Could not resolve hostname xyzabc: Name or '.
               \  'service not known'
   endif
   for cmd in keys(s:systemStub)
      if match(remoteCmd, cmd) != -1
         for key in keys(s:systemStub[cmd])
            if match(remoteCmd, key) != -1
               if match(s:systemStub[cmd][key], '%s') != -1
                  return substitute(s:systemStub[cmd][key], '%s', 
                           \ split(remoteCmd)[1], '')
               else
                  return s:systemStub[cmd][key]
               endif
            endif
         endfor
      endif
   endfor
   return "VvcsSystem: no stub for '".a:expr."' (remoteCmd = ".remoteCmd.")"
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                            Stub for input calls                            "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:inputStub = {
   \'list to review' : "missing initialization: g:inputStub['list to review']",
   \'Commit message' : "commmitMsg",
\}

function! VvcsInput(...)
   if a:0 > 0
      for key in keys(g:inputStub)
         if match(a:1, key) != -1
            return g:inputStub[key]
         endif
      endfor
   endif
   return "VvcsInput: no stub for '".string(a:000)."'"
endfunction

