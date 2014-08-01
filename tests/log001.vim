" Test log commands 

echomsg '>> Log several messages'
call vvcs#log#clear()
call vvcs#log#error("Error 1")
call vvcs#log#msg("Msg 1")
call vvcs#log#startCommand("Cmd 1")
call vvcs#log#append(["Cmd log line 1", "Cmd log line 2", "Cmd log line 3"])
call vvcs#log#open()
call EchoAllWindows()
quit

echomsg '>> Clear and display log'
call vvcs#log#clear()
call vvcs#log#open()
call EchoAllWindows()
quit

echomsg '>> Check that log is disable when vvcs_log_location is empty'
let g:vvcs_log_location = ""
call vvcs#log#clear()
call vvcs#log#error("Error 1")
call vvcs#log#msg("Msg 1")
call vvcs#log#startCommand("Cmd 1")
call vvcs#log#append(["Cmd log line 1", "Cmd log line 2", "Cmd log line 3"])
call vvcs#log#open()
call EchoAllWindows()

call vimtest#Quit()
