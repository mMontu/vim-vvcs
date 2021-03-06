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
   let startWin = winnr()
   echomsg '<EchoAllWindows: '.winnr('$').'>'
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
      echomsg ''
   endfor
   exe startWin.'wincmd w'
endfunction

function! ClearRegisters() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Set unusual content on registers to detect if any changes
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   redir => l:register_out
   silent register
   redir end
   let l:register_list = split(l:register_out, '\n')
   call remove(l:register_list, 0) " remove header (-- Registers --)
   call map(l:register_list, "substitute(v:val, '^.\\(.\\).*', '\\1', '')")
   call filter(l:register_list, 'v:val !~ "[%#=.:]"') " skip readonly registers
   for i in range(len(l:register_list))
      exe 'let @'.l:register_list[i]."= '".strftime("%d/%m/%Y %H:%M:%S")." . ".i."'"
   endfor
endfunction
function! SaveRegisters() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Save the contents of registers in order to check with CheckRegisters()
" Ignore some read-only registers, as =, % and #
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   if !exists('g:vvcs_saved_registers')
      call ClearRegisters()
   endif
   redir => l:register_out
   silent register
   redir end
   let g:vvcs_saved_registers = split(l:register_out, '\n')
   call remove(g:vvcs_saved_registers, 0)
   call filter(g:vvcs_saved_registers, 'v:val !~ "^\"[%#=]"')
endfunction
function! CheckRegisters() " {{{1
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Check registers contents against the values stored with SaveRegisters()
" This is function uses TAP (:h VimTAP). If this becomes a problem it is
" possible to change it to return a value indicanting success, which should be
" included on the .msgok files.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
   call vimtest#StartTap()
   call vimtap#Plan(3)
   call vimtap#Is(exists('g:vvcs_saved_registers'), 1, 
            \ "SaveRegisters() called first")

   " store the previous register contents and call SaveRegisters again in
   " order to read the new contents
   let l:prev_registers = g:vvcs_saved_registers
   call SaveRegisters()

   call vimtap#Is(len(g:vvcs_saved_registers), len(l:prev_registers),
            \ "check lenght of lists")

   for i in range(len(l:prev_registers))
      if l:prev_registers[i] !=# g:vvcs_saved_registers[i]
         break
      endif
   endfor
   call vimtap#Is(g:vvcs_saved_registers[i], l:prev_registers[i], 
            \ "register ".split(g:vvcs_saved_registers[i])[0])
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
         \'readOnly.h': "readOnly.h previous contents\n",
         \'readWrite.h': "readWrite.h previous contents\n\n",
         \'checkoutOk.h': "\ncheckoutOk.h previous contents",
         \'invalidDir.h': 'cleartool: Error: Unable to access '.
         \   '"/AuxFiles/invalidDir.h": No such file or directory.',
   \},
   \'\<cat\> \S*@@\S*$': {
         \'\v\S*newFile\S*\@\@\S*\/0$' : "",
         \'\v\S*\S*\@\@(readWrite|checkoutOk)\.h_previous$' : "%s contents\n\n",
         \'\v\S*\@\@\S*$' : "%s contents\n",
   \},
   \'\<cat\>\s\+[^@]\+\>': {
         \'readOnly.h_previous': "readOnly.h previous contents\n",
         \'readWrite.h_previous': "readWrite.h previous contents\n\n",
         \'invalidDir.h': 'cleartool: Error: Unable to access '.
         \   '"/AuxFiles/invalidDir.h": No such file or directory.',
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
         \'.': "15-Jul-2014    user     checkout version \"/vobs/readWrite.h\" from /my/branch/1 (unreserved)\n".
         \     "13-Jul-2014    user     checkout version \"/vobs/checkoutOk.h\" from /my/branch/4 (unreserved)\n",
   \},
   \'\<echo\> .*cleartool descr -short -pred': {
         \'@@\zs[^\\]*': "substitute('%s', '\\d\\+$', '\\=submatch(0)-1', '')",
         \'readOnly.h[^@]': "readOnly.h_previous",
         \'readWrite.h[^@]': "readWrite.h_previous",
         \'checkoutOk.h[^@]': "checkoutOk.h_previous",
         \'invalidDir.h[^@]': 'cleartool: Error: Unable to access '.
         \   '"/AuxFiles/invalidDir.h[^@]": No such file or directory.',
         \'newFile\.h': "/main/myBranch/0",
   \},
   \'\<echo\> .*cleartool descr -short [^-]': {
         \'@@\zs[^\\]*': "%s",
         \'readWrite.h[^@]': "checkedout",
         \'checkoutOk.h[^@]': "checkoutOk.h",
         \'readOnly.h[^@]': "readOnly.h",
         \'invalidDir.h[^@]': 'cleartool: Error: Unable to access '.
         \   '"/AuxFiles/invalidDir.h": No such file or directory.',
         \'newFile\.h': "/main/myBranch/1",
   \},
\}

function! VvcsSystem(expr)
   let g:VvcsSystemShellError = 0
   let remoteCmd = substitute(a:expr, matchstr(g:vvcs_remote_cmd, 
            \ '.\{-}\ze[''"]*%s'), '', '')
   if  remoteCmd =~# 'sshError\.h'
      let g:VvcsSystemShellError = 1
      return 'ssh: Could not resolve hostname xyzabc: Name or '.
               \  'service not known'
   endif
   for cmd in keys(s:systemStub)
      if match(remoteCmd, cmd) != -1
         for key in reverse(sort(keys(s:systemStub[cmd])))
            if match(remoteCmd, key) != -1
               if s:systemStub[cmd][key] =~? '\<Error\>\|\<Fail'
                  let g:VvcsSystemShellError = 1
               endif
               if match(s:systemStub[cmd][key], '%s') != -1
                  let val = substitute(s:systemStub[cmd][key], '%s', 
                           \ matchstr(remoteCmd, key), '')
                  if val =~# '^substitute('
                     let val = eval(val)
                  endif
                  return val
               else
                  return s:systemStub[cmd][key]
               endif
            endif
         endfor
      endif
   endfor
   let g:VvcsSystemShellError = 1
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

