Test Environment Setup~

VVCS automated tests uses runVimTests framework and VimTAP plugin:

   http://www.vim.org/scripts/script.php?script_id=2565
   http://www.vim.org/scripts/script.php?script_id=2213

Installation details can be found with "help runVimTests-installation". What
follows is a short summary:


1) For easier use bundle/runVimTests/bin/ should be in your path. If you
   intend to run the framework from shells started from Vim (as I do) you can
   use something like the following in your .vimrc:
>
   if $path !~# 'bin/runVimTests.cmd'
      let $path .= ';'.fnamemodify(globpath(&rtp, "bin/runVimTests.cmd"), ":p:h")
   endif
<
   Otherwise just add it to the system global path environment variable.
   

2) There are three ways of executing the tests: 
   - without loading any settings/plugins
   - loading only from system wide (default) 
   - loading user settings

   It is recommended test the plugin without loading user settings to ensure
   the plugin doesn't depends on any personal setting.

   But without loading user settings runVimTests and VimTAP are not loaded.
   One option to load them is the plugin user configuration. To do this, put
   the following in a file on bundle/runVimTests/bin/runVimTestsSetup.vim:
>
   runtime bundle/runVimTests/autoload/vimtest.vim
   runtime bundle/VimTAP-0.3/autoload/vimtap.vim
<
   On newer versions of runVimTests this may not be necessary depending on how
   you organize your plugins.

3) The latest VimTAP version, 0.4, isn't compatible with version 0.3, which
   is used in documentation examples and the vvcs tests.

4) Requires Vim 7.2 or newer. If running on Windows, a few tools are also necessary:
   grep, sed and diff.

5) You can check if the installation is OK by entering bundle/runVimTests
   folder and run the following:
>
   $ runVimTests tests/runVimTests/successful.suite
<
   which should print something like:

      9 files with 19 tests; 0 skipped, 19 run: 19 OK, 0 failures, 0 errors.

   From bundle/vvcs/tests the following command
>
   $ runVimTests .
<
   yields something similar to
>
   6 files with 8 tests; 0 skipped, 8 run: 8 OK, 0 failures, 0 errors.


vim:tw=78:ts=8:ft=help:norl:
