" Test for options

source check.vim

func Test_whichwrap()
  set whichwrap=b,s
  call assert_equal('b,s', &whichwrap)

  set whichwrap+=h,l
  call assert_equal('b,s,h,l', &whichwrap)

  set whichwrap+=h,l
  call assert_equal('b,s,h,l', &whichwrap)

  set whichwrap+=h,l
  call assert_equal('b,s,h,l', &whichwrap)

  set whichwrap=h,h
  call assert_equal('h', &whichwrap)

  set whichwrap=h,h,h
  call assert_equal('h', &whichwrap)

  set whichwrap&
endfunction

function! Test_isfname()
  " This used to cause Vim to access uninitialized memory.
  set isfname=
  call assert_equal("~X", expand("~X"))
  set isfname&
endfunction

function Test_wildchar()
  " Empty 'wildchar' used to access invalid memory.
  call assert_fails('set wildchar=', 'E521:')
  call assert_fails('set wildchar=abc', 'E521:')
  set wildchar=<Esc>
  let a=execute('set wildchar?')
  call assert_equal("\n  wildchar=<Esc>", a)
  set wildchar=27
  let a=execute('set wildchar?')
  call assert_equal("\n  wildchar=<Esc>", a)
  set wildchar&
endfunction

func Test_wildoptions()
  set wildoptions=
  set wildoptions+=tagfile
  set wildoptions+=tagfile
  call assert_equal('tagfile', &wildoptions)
endfunc

function! Test_options()
  let caught = 'ok'
  try
    options
  catch
    let caught = v:throwpoint . "\n" . v:exception
  endtry
  call assert_equal('ok', caught)

  " Check if the option-window is opened horizontally.
  wincmd j
  call assert_notequal('option-window', bufname(''))
  wincmd k
  call assert_equal('option-window', bufname(''))
  " close option-window
  close

  " Open the option-window vertically.
  vert options
  " Check if the option-window is opened vertically.
  wincmd l
  call assert_notequal('option-window', bufname(''))
  wincmd h
  call assert_equal('option-window', bufname(''))
  " close option-window
  close

  " Open the option-window in a new tab.
  tab options
  " Check if the option-window is opened in a tab.
  normal gT
  call assert_notequal('option-window', bufname(''))
  normal gt
  call assert_equal('option-window', bufname(''))

  " close option-window
  close
endfunction

function! Test_path_keep_commas()
  " Test that changing 'path' keeps two commas.
  set path=foo,,bar
  set path-=bar
  set path+=bar
  call assert_equal('foo,,bar', &path)

  set path&
endfunction

func Test_filetype_valid()
  set ft=valid_name
  call assert_equal("valid_name", &filetype)
  set ft=valid-name
  call assert_equal("valid-name", &filetype)

  call assert_fails(":set ft=wrong;name", "E474:")
  call assert_fails(":set ft=wrong\\\\name", "E474:")
  call assert_fails(":set ft=wrong\\|name", "E474:")
  call assert_fails(":set ft=wrong/name", "E474:")
  call assert_fails(":set ft=wrong\\\nname", "E474:")
  call assert_equal("valid-name", &filetype)

  exe "set ft=trunc\x00name"
  call assert_equal("trunc", &filetype)
endfunc

func Test_syntax_valid()
  if !has('syntax')
    return
  endif
  set syn=valid_name
  call assert_equal("valid_name", &syntax)
  set syn=valid-name
  call assert_equal("valid-name", &syntax)

  call assert_fails(":set syn=wrong;name", "E474:")
  call assert_fails(":set syn=wrong\\\\name", "E474:")
  call assert_fails(":set syn=wrong\\|name", "E474:")
  call assert_fails(":set syn=wrong/name", "E474:")
  call assert_fails(":set syn=wrong\\\nname", "E474:")
  call assert_equal("valid-name", &syntax)

  exe "set syn=trunc\x00name"
  call assert_equal("trunc", &syntax)
endfunc

func Test_keymap_valid()
  if !has('keymap')
    return
  endif
  call assert_fails(":set kmp=valid_name", "E544:")
  call assert_fails(":set kmp=valid_name", "valid_name")
  call assert_fails(":set kmp=valid-name", "E544:")
  call assert_fails(":set kmp=valid-name", "valid-name")

  call assert_fails(":set kmp=wrong;name", "E474:")
  call assert_fails(":set kmp=wrong\\\\name", "E474:")
  call assert_fails(":set kmp=wrong\\|name", "E474:")
  call assert_fails(":set kmp=wrong/name", "E474:")
  call assert_fails(":set kmp=wrong\\\nname", "E474:")

  call assert_fails(":set kmp=trunc\x00name", "E544:")
  call assert_fails(":set kmp=trunc\x00name", "trunc")
endfunc

func Check_dir_option(name)
  " Check that it's possible to set the option.
  exe 'set ' . a:name . '=/usr/share/dict/words'
  call assert_equal('/usr/share/dict/words', eval('&' . a:name))
  exe 'set ' . a:name . '=/usr/share/dict/words,/and/there'
  call assert_equal('/usr/share/dict/words,/and/there', eval('&' . a:name))
  exe 'set ' . a:name . '=/usr/share/dict\ words'
  call assert_equal('/usr/share/dict words', eval('&' . a:name))

  " Check rejecting weird characters.
  call assert_fails("set " . a:name . "=/not&there", "E474:")
  call assert_fails("set " . a:name . "=/not>there", "E474:")
  call assert_fails("set " . a:name . "=/not.*there", "E474:")
endfunc

func Test_cinkeys()
  " This used to cause invalid memory access
  set cindent cinkeys=0
  norm a
  set cindent& cinkeys&
endfunc

func Test_dictionary()
  call Check_dir_option('dictionary')
endfunc

func Test_thesaurus()
  call Check_dir_option('thesaurus')
endfun

func Test_complete()
  " Trailing single backslash used to cause invalid memory access.
  set complete=s\
  new
  call feedkeys("i\<C-N>\<Esc>", 'xt')
  bwipe!
  set complete&
endfun

func Test_set_completion()
  call feedkeys(":set di\<C-A>\<C-B>\"\<CR>", 'tx')
  call assert_equal('"set dictionary diff diffexpr diffopt digraph directory display', @:)

  " Expand boolan options. When doing :set no<Tab>
  " vim displays the options names without "no" but completion uses "no...".
  call feedkeys(":set nodi\<C-A>\<C-B>\"\<CR>", 'tx')
  call assert_equal('"set nodiff digraph', @:)

  call feedkeys(":set invdi\<C-A>\<C-B>\"\<CR>", 'tx')
  call assert_equal('"set invdiff digraph', @:)

  " Expand abbreviation of options.
  call feedkeys(":set ts\<C-A>\<C-B>\"\<CR>", 'tx')
  call assert_equal('"set tabstop thesaurus thesaurusfunc', @:)

  " Expand current value
  call feedkeys(":set fileencodings=\<C-A>\<C-B>\"\<CR>", 'tx')
  call assert_equal('"set fileencodings=ucs-bom,utf-8,default,latin1', @:)

  call feedkeys(":set fileencodings:\<C-A>\<C-B>\"\<CR>", 'tx')
  call assert_equal('"set fileencodings:ucs-bom,utf-8,default,latin1', @:)

  " Expand directories.
  call feedkeys(":set cdpath=./\<C-A>\<C-B>\"\<CR>", 'tx')
  call assert_match('./samples/ ', @:)
  call assert_notmatch('./small.vim ', @:)

  " Expand files and directories.
  call feedkeys(":set tags=./\<C-A>\<C-B>\"\<CR>", 'tx')
  call assert_match('./samples/ ./sautest/ ./screendump.vim ./script_util.vim ./setup.vim ./shared.vim', @:)

  call feedkeys(":set tags=./\\\\ dif\<C-A>\<C-B>\"\<CR>", 'tx')
  call assert_equal('"set tags=./\\ diff diffexpr diffopt', @:)
  set tags&

  " Expand values for 'filetype'
  call feedkeys(":set filetype=sshdconfi\<Tab>\<C-B>\"\<CR>", 'xt')
  call assert_equal('"set filetype=sshdconfig', @:)
  call feedkeys(":set filetype=a\<C-A>\<C-B>\"\<CR>", 'xt')
  call assert_equal('"set filetype=' .. getcompletion('a*', 'filetype')->join(), @:)
endfunc

func Test_set_errors()
  call assert_fails('set scroll=-1', 'E49:')
  call assert_fails('set backupcopy=', 'E474:')
  call assert_fails('set regexpengine=3', 'E474:')
  call assert_fails('set history=10001', 'E474:')
  call assert_fails('set numberwidth=21', 'E474:')
  call assert_fails('set colorcolumn=-a')
  call assert_fails('set colorcolumn=a')
  call assert_fails('set colorcolumn=1,')
  call assert_fails('set cmdheight=-1', 'E487:')
  call assert_fails('set cmdwinheight=-1', 'E487:')
  if has('conceal')
    call assert_fails('set conceallevel=-1', 'E487:')
    call assert_fails('set conceallevel=4', 'E474:')
  endif
  call assert_fails('set helpheight=-1', 'E487:')
  call assert_fails('set history=-1', 'E487:')
  call assert_fails('set report=-1', 'E487:')
  call assert_fails('set shiftwidth=-1', 'E487:')
  call assert_fails('set sidescroll=-1', 'E487:')
  call assert_fails('set tabstop=-1', 'E487:')
  call assert_fails('set textwidth=-1', 'E487:')
  call assert_fails('set timeoutlen=-1', 'E487:')
  call assert_fails('set updatecount=-1', 'E487:')
  call assert_fails('set updatetime=-1', 'E487:')
  call assert_fails('set winheight=-1', 'E487:')
  call assert_fails('set tabstop!', 'E488:')
  call assert_fails('set xxx', 'E518:')
  call assert_fails('set beautify?', 'E518:')
  call assert_fails('set undolevels=x', 'E521:')
  call assert_fails('set tabstop=', 'E521:')
  call assert_fails('set comments=-', 'E524:')
  call assert_fails('set comments=a', 'E525:')
  call assert_fails('set foldmarker=x', 'E536:')
  call assert_fails('set commentstring=x', 'E537:')
  call assert_fails('set complete=x', 'E539:')
  call assert_fails('set rulerformat=%-', 'E539:')
  call assert_fails('set rulerformat=%(', 'E542:')
  call assert_fails('set rulerformat=%15(%%', 'E542:')
  call assert_fails('set statusline=%$', 'E539:')
  call assert_fails('set statusline=%{', 'E540:')
  call assert_fails('set statusline=%(', 'E542:')
  call assert_fails('set statusline=%)', 'E542:')

  if has('cursorshape')
    " This invalid value for 'guicursor' used to cause Vim to crash.
    call assert_fails('set guicursor=i-ci,r-cr:h', 'E545:')
    call assert_fails('set guicursor=i-ci', 'E545:')
    call assert_fails('set guicursor=x', 'E545:')
    call assert_fails('set guicursor=r-cr:horx', 'E548:')
    call assert_fails('set guicursor=r-cr:hor0', 'E549:')
  endif
  call assert_fails('set backupext=~ patchmode=~', 'E589:')
  call assert_fails('set winminheight=10 winheight=9', 'E591:')
  call assert_fails('set winminwidth=10 winwidth=9', 'E592:')
  call assert_fails("set showbreak=\x01", 'E595:')
  call assert_fails('set t_foo=', 'E846:')
  if has('python') || has('python3')
    call assert_fails('set pyxversion=6', 'E474:')
  endif
  call assert_fails("let &tabstop='ab'", 'E521:')
  call assert_fails('set sessionoptions=curdir,sesdir', 'E474:')
  call assert_fails('set foldmarker={{{,', 'E474:')
  call assert_fails('set sessionoptions=sesdir,curdir', 'E474:')
  call assert_fails('set listchars=trail:· ambiwidth=double', 'E834:')
  set listchars&
  call assert_fails('set fillchars=stl:· ambiwidth=double', 'E835:')
  set fillchars&
  call assert_fails('set fileencoding=latin1,utf-8', 'E474:')
  set nomodifiable
  call assert_fails('set fileencoding=latin1', 'E21:')
  set modifiable&
endfunc

" Must be executed before other tests that set 'term'.
func Test_000_term_option_verbose()
  if has('nvim') || has('gui_running')
    return
  endif
  let verb_cm = execute('verbose set t_cm')
  call assert_notmatch('Last set from', verb_cm)

  let term_save = &term
  set term=ansi
  let verb_cm = execute('verbose set t_cm')
  call assert_match('Last set from.*test_options.vim', verb_cm)
  let &term = term_save
endfunc

func Test_set_ttytype()
  " Nvim does not support 'ttytype'.
  if !has('nvim') && !has('gui_running') && has('unix')
    " Setting 'ttytype' used to cause a double-free when exiting vim and
    " when vim is compiled with -DEXITFREE.
    set ttytype=ansi
    call assert_equal('ansi', &ttytype)
    call assert_equal(&ttytype, &term)
    set ttytype=xterm
    call assert_equal('xterm', &ttytype)
    call assert_equal(&ttytype, &term)
    try
      set ttytype=
      call assert_report('set ttytype= did not fail')
    catch /E529/
    endtry

    " Some systems accept any terminal name and return dumb settings,
    " check for failure of finding the entry and for missing 'cm' entry.
    try
      set ttytype=xxx
      call assert_report('set ttytype=xxx did not fail')
    catch /E522\|E437/
    endtry

    set ttytype&
    call assert_equal(&ttytype, &term)
  endif
endfunc

func Test_set_all()
  set tw=75
  set iskeyword=a-z,A-Z
  set nosplitbelow
  let out = execute('set all')
  call assert_match('textwidth=75', out)
  call assert_match('iskeyword=a-z,A-Z', out)
  call assert_match('nosplitbelow', out)
  set tw& iskeyword& splitbelow&
endfunc

func Test_set_values()
  " The file is only generated when running "make test" in the src directory.
  if filereadable('opt_test.vim')
    source opt_test.vim
  endif
endfunc

func Test_renderoptions()
  throw 'skipped: Nvim does not support renderoptions'
  " Only do this for Windows Vista and later, fails on Windows XP and earlier.
  " Doesn't hurt to do this on a non-Windows system.
  if windowsversion() !~ '^[345]\.'
    set renderoptions=type:directx
    set rop=type:directx
  endif
endfunc

func ResetIndentexpr()
  set indentexpr=
endfunc

func Test_set_indentexpr()
  " this was causing usage of freed memory
  set indentexpr=ResetIndentexpr()
  new
  call feedkeys("i\<c-f>", 'x')
  call assert_equal('', &indentexpr)
  bwipe!
endfunc

func Test_backupskip()
  " Option 'backupskip' may contain several comma-separated path
  " specifications if one or more of the environment variables TMPDIR, TMP,
  " or TEMP is defined.  To simplify testing, convert the string value into a
  " list.
  let bsklist = split(&bsk, ',')

  if has("mac")
    let found = (index(bsklist, '/private/tmp/*') >= 0)
    call assert_true(found, '/private/tmp not in option bsk: ' . &bsk)
  elseif has("unix")
    let found = (index(bsklist, '/tmp/*') >= 0)
    call assert_true(found, '/tmp not in option bsk: ' . &bsk)
  endif

  " If our test platform is Windows, the path(s) in option bsk will use
  " backslash for the path separator and the components could be in short
  " (8.3) format.  As such, we need to replace the backslashes with forward
  " slashes and convert the path components to long format.  The expand()
  " function will do this but it cannot handle comma-separated paths.  This is
  " why bsk was converted from a string into a list of strings above.
  "
  " One final complication is that the wildcard "/*" is at the end of each
  " path and so expand() might return a list of matching files.  To prevent
  " this, we need to remove the wildcard before calling expand() and then
  " append it afterwards.
  if has('win32')
    let item_nbr = 0
    while item_nbr < len(bsklist)
      let path_spec = bsklist[item_nbr]
      let path_spec = strcharpart(path_spec, 0, strlen(path_spec)-2)
      let path_spec = substitute(expand(path_spec), '\\', '/', 'g')
      let bsklist[item_nbr] = path_spec . '/*'
      let item_nbr += 1
    endwhile
  endif

  " Option bsk will also include these environment variables if defined.
  " If they're defined, verify they appear in the option value.
  for var in  ['$TMPDIR', '$TMP', '$TEMP']
    if exists(var)
      let varvalue = substitute(expand(var), '\\', '/', 'g')
      let varvalue = substitute(varvalue, '/$', '', '')
      let varvalue .= '/*'
      let found = (index(bsklist, varvalue) >= 0)
      call assert_true(found, var . ' (' . varvalue . ') not in option bsk: ' . &bsk)
    endif
  endfor

  " Duplicates from environment variables should be filtered out (option has
  " P_NODUP).  Run this in a separate instance and write v:errors in a file,
  " so that we see what happens on startup.
  let after =<< trim [CODE]
      let bsklist = split(&backupskip, ',')
      call assert_equal(uniq(copy(bsklist)), bsklist)
      call writefile(['errors:'] + v:errors, 'Xtestout')
      qall
  [CODE]
  call writefile(after, 'Xafter')
  " let cmd = GetVimProg() . ' --not-a-term -S Xafter --cmd "set enc=utf8"'
  let cmd = GetVimProg() . ' -S Xafter --cmd "set enc=utf8"'

  let saveenv = {}
  for var in ['TMPDIR', 'TMP', 'TEMP']
    let saveenv[var] = getenv(var)
    call setenv(var, '/duplicate/path')
  endfor

  exe 'silent !' . cmd
  call assert_equal(['errors:'], readfile('Xtestout'))

  " restore environment variables
  for var in ['TMPDIR', 'TMP', 'TEMP']
    call setenv(var, saveenv[var])
  endfor

  call delete('Xtestout')
  call delete('Xafter')

  " Duplicates should be filtered out (option has P_NODUP)
  let backupskip = &backupskip
  set backupskip=
  set backupskip+=/test/dir
  set backupskip+=/other/dir
  set backupskip+=/test/dir
  call assert_equal('/test/dir,/other/dir', &backupskip)
  let &backupskip = backupskip
endfunc

func Test_copy_winopt()
  set hidden

  " Test copy option from current buffer in window
  split
  enew
  setlocal numberwidth=5
  wincmd w
  call assert_equal(4,&numberwidth)
  bnext
  call assert_equal(5,&numberwidth)
  bw!
  call assert_equal(4,&numberwidth)

  " Test copy value from window that used to be display the buffer
  split
  enew
  setlocal numberwidth=6
  bnext
  wincmd w
  call assert_equal(4,&numberwidth)
  bnext
  call assert_equal(6,&numberwidth)
  bw!

  " Test that if buffer is current, don't use the stale cached value
  " from the last time the buffer was displayed.
  split
  enew
  setlocal numberwidth=7
  bnext
  bnext
  setlocal numberwidth=8
  wincmd w
  call assert_equal(4,&numberwidth)
  bnext
  call assert_equal(8,&numberwidth)
  bw!

  " Test value is not copied if window already has seen the buffer
  enew
  split
  setlocal numberwidth=9
  bnext
  setlocal numberwidth=10
  wincmd w
  call assert_equal(4,&numberwidth)
  bnext
  call assert_equal(4,&numberwidth)
  bw!

  set nohidden
endfunc

func Test_shortmess_F()
  new
  call assert_match('\[No Name\]', execute('file'))
  set shortmess+=F
  call assert_match('\[No Name\]', execute('file'))
  call assert_match('^\s*$', execute('file foo'))
  call assert_match('foo', execute('file'))
  set shortmess-=F
  call assert_match('bar', execute('file bar'))
  call assert_match('bar', execute('file'))
  set shortmess&
  bwipe
endfunc

func Test_shortmess_F2()
  e file1
  e file2
  " Accommodate Nvim default.
  set shortmess-=F
  call assert_match('file1', execute('bn', ''))
  call assert_match('file2', execute('bn', ''))
  set shortmess+=F
  call assert_true(empty(execute('bn', '')))
  " call assert_false(test_getvalue('need_fileinfo'))
  call assert_true(empty(execute('bn', '')))
  " call assert_false(test_getvalue('need_fileinfo'))
  set hidden
  call assert_true(empty(execute('bn', '')))
  " call assert_false(test_getvalue('need_fileinfo'))
  call assert_true(empty(execute('bn', '')))
  " call assert_false(test_getvalue('need_fileinfo'))
  set nohidden
  call assert_true(empty(execute('bn', '')))
  " call assert_false(test_getvalue('need_fileinfo'))
  call assert_true(empty(execute('bn', '')))
  " call assert_false(test_getvalue('need_fileinfo'))
  " Accommodate Nvim default.
  set shortmess-=F
  call assert_match('file1', execute('bn', ''))
  call assert_match('file2', execute('bn', ''))
  bwipe
  bwipe
endfunc

func Test_local_scrolloff()
  set so=5
  set siso=7
  split
  call assert_equal(5, &so)
  setlocal so=3
  call assert_equal(3, &so)
  wincmd w
  call assert_equal(5, &so)
  wincmd w
  setlocal so<
  call assert_equal(5, &so)
  setlocal so=0
  call assert_equal(0, &so)
  setlocal so=-1
  call assert_equal(5, &so)

  call assert_equal(7, &siso)
  setlocal siso=3
  call assert_equal(3, &siso)
  wincmd w
  call assert_equal(7, &siso)
  wincmd w
  setlocal siso<
  call assert_equal(7, &siso)
  setlocal siso=0
  call assert_equal(0, &siso)
  setlocal siso=-1
  call assert_equal(7, &siso)

  close
  set so&
  set siso&
endfunc

func Test_visualbell()
  set belloff=
  set visualbell
  call assert_beeps('normal 0h')
  set novisualbell
  set belloff=all
endfunc

" Test for the 'write' option
func Test_write()
  new
  call setline(1, ['L1'])
  set nowrite
  call assert_fails('write Xfile', 'E142:')
  set write
  close!
endfunc

" Test for 'buftype' option
func Test_buftype()
  new
  call setline(1, ['L1'])
  set buftype=nowrite
  call assert_fails('write', 'E382:')
  close!
endfunc

" Test for setting option values using v:false and v:true
func Test_opt_boolean()
  set number&
  set number
  call assert_equal(1, &nu)
  set nonu
  call assert_equal(0, &nu)
  let &nu = v:true
  call assert_equal(1, &nu)
  let &nu = v:false
  call assert_equal(0, &nu)
  set number&
endfunc

func Test_opt_winminheight_term()
  " See test/functional/legacy/options_spec.lua
  CheckRunVimInTerminal

  " The tabline should be taken into account.
  let lines =<< trim END
    set wmh=0 stal=2
    below sp | wincmd _
    below sp | wincmd _
    below sp | wincmd _
    below sp
  END
  call writefile(lines, 'Xwinminheight')
  let buf = RunVimInTerminal('-S Xwinminheight', #{rows: 11})
  call term_sendkeys(buf, ":set wmh=1\n")
  call WaitForAssert({-> assert_match('E36: Not enough room', term_getline(buf, 11))})

  call StopVimInTerminal(buf)
  call delete('Xwinminheight')
endfunc

func Test_opt_winminheight_term_tabs()
  " See test/functional/legacy/options_spec.lua
  CheckRunVimInTerminal

  " The tabline should be taken into account.
  let lines =<< trim END
    set wmh=0 stal=2
    split
    split
    split
    split
    tabnew
  END
  call writefile(lines, 'Xwinminheight')
  let buf = RunVimInTerminal('-S Xwinminheight', #{rows: 11})
  call term_sendkeys(buf, ":set wmh=1\n")
  call WaitForAssert({-> assert_match('E36: Not enough room', term_getline(buf, 11))})

  call StopVimInTerminal(buf)
  call delete('Xwinminheight')
endfunc

" Test for setting option value containing spaces with isfname+=32
func Test_isfname_with_options()
  set isfname+=32
  setlocal keywordprg=:term\ help.exe
  call assert_equal(':term help.exe', &keywordprg)
  set isfname&
  setlocal keywordprg&
endfunc

" Test that resetting laststatus does change scroll option
func Test_opt_reset_scroll()
  " See test/functional/legacy/options_spec.lua
  CheckRunVimInTerminal
  let vimrc =<< trim [CODE]
    set scroll=2
    set laststatus=2
  [CODE]
  call writefile(vimrc, 'Xscroll')
  let buf = RunVimInTerminal('-S Xscroll', {'rows': 16, 'cols': 45})
  call term_sendkeys(buf, ":verbose set scroll?\n")
  call WaitForAssert({-> assert_match('Last set.*window size', term_getline(buf, 15))})
  call assert_match('^\s*scroll=7$', term_getline(buf, 14))
  call StopVimInTerminal(buf)

  " clean up
  call delete('Xscroll')
endfunc

" vim: shiftwidth=2 sts=2 expandtab
