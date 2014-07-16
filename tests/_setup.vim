source ../plugin/vvcs.vim
" Mainly due to autoload folder
let &runtimepath = expand('<sfile>:p:h:h') . ',' . &runtimepath

" let the tests use their own cache directory
let g:vvcs_cache_dir = 'AuxFiles/.cache/vvcs'

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                             Utility functions                              "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! EchoAllWindows()
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" echo the title, diff status and contents of each window
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   for i in range(1, winnr('$'))
      exec 'echomsg "echo window '.i.':"'
      exec i.'wincmd w'
      exec "normal \<c-g>"
      set diff?
      if line('$') > 1 || getline(1) != ''
         g/^/
      else
         echomsg '<empty file>'
      endif
   endfor
endfunction


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
         \'readOnly.h': 'readOnly.h previous contents',
         \'readWrite.h': 'readWrite.h previous contents',
         \'checkoutOk.h': 'checkoutOk.h previous contents',
         \'invalidDir.h': 'cleartool: Error: Unable to access '.
         \   '"/AuxFiles/invalidDir.h": No such file or directory.',
   \},
   \'\<cat\> \S*@@\S*$': {
         \'readOnly\.h\>\|readWrite\.h\>\|checkoutOk\.h\>' : "%s contents\n\n",
         \'newFile\.h\S\+\/[^0]\d*$' : "%s contents\n\n",
         \'newFile\.h\S\+\/0\>$' : "",
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
   \'\<ct lsco -avobs -cview\>' : {
         \'.': "15-Jul-2014    user     checkout version \"AuxFiles/readWrite.h\" from /my/branch/1 (unreserved)\n".
         \     "13-Jul-2014    user     checkout version \"AuxFiles/checkoutOk.h\" from /my/branch/4 (unreserved)\n",
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
"                            Stub for input/confirm calls                    "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:inputStub = {
   \'list to review' : "missing initialization: g:inputStub['list to review']",
   \'Commit message' : "commmitMsg",
   \'Quit comparison' : "1",
\}

function! VvcsInput(...)
   if a:0 > 0
      echomsg a:1
      for key in keys(g:inputStub)
         if match(a:1, key) != -1
            return g:inputStub[key]
         endif
      endfor
   endif
   return "VvcsInput: no stub for '".string(a:000)."'"
endfunction

function! VvcsConfirm(...) "
   return call(function("VvcsInput"), a:000)
endfunction

