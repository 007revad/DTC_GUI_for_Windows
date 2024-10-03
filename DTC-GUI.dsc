#-----------------------------------------------------------------------------#
#    Program:    DTC GUI                                                      #
#    File:       DTC-GUI.dsc                                                  #
#    Author:     007revad                                                     #
#    Contact:    https://github.com/007revad                                  #
#    Copyright:  2024, 007revad                                               #
#-----------------------------------------------------------------------------#

  title DTC GUI

  %%inifile = @path(%0)DTC-GUI.ini
  inifile open, %%inifile
  if @not(@ok())
    warn Failed to open DTC-GUI.ini
    goto Close
  end


REM  DIALOG CREATE,DTC GUI,-1,0,560,156
  DIALOG CREATE,DTC GUI,-1,0,560,156,ONTOP,DRAGDROP
REM *** Modified by Dialog Designer on Thu 3 10 2024 - 13:14 ***
  DIALOG ADD,STYLE,STYLE1,,,B,,RED
  DIALOG ADD,STYLE,STYLE2,,,BC,,00C400
  DIALOG ADD,STYLE,STYLE3,,,BC,,RED
  DIALOG ADD,TEXT,TEXT1,20,18,45,18,In File
  DIALOG ADD,TEXT,TEXT2,50,18,45,18,Out File
  DIALOG ADD,EDIT,EDIT1,18,70,390,18,,,READONLY
  DIALOG ADD,EDIT,EDIT2,48,70,390,18
  DIALOG ADD,BUTTON,Select,15,468,70,24,Select File
  DIALOG ADD,TEXT,TEXT3,50,470,70,18,,,STYLE1
  DIALOG ADD,BUTTON,Compile,80,195,74,24,Compile
  DIALOG ADD,BUTTON,Decompile,80,285,74,24,Decompile
  DIALOG ADD,TEXT,TEXT4,120,20,518,18,,,FITTEXT,STYLE2
  DIALOG ADD,TEXT,TEXT5,120,20,518,18,,,FITTEXT,STYLE3
  dialog disable, Compile
  dialog disable, Decompile
  dialog hide, TEXT5
  DIALOG HIDE
  if @not(@null(%1))
    %%file_in = %1
    gosub VerifyFile
  end
  DIALOG SHOW

:EvLoop
  wait event, 0.5
  goto @event() 


:TIMER
  %%file_out = @dlgtext(EDIT2)
  %%ext_out = @ext(%%file_out)
  if @both(@equal(%%ext_in,%%ext_out),@both(%%ext_in,%%ext_out))
    dialog set, TEXT3, Same Type!
  elsif @file(%%file_out)
    dialog set, TEXT3, File Exists!
  else
    dialog set, TEXT3, 
  end
  if @both(@equal(%%ext_in,dtb),@equal(%%ext_out,dts))
    dialog disable, Compile
    dialog enable, Decompile
  elsif @both(@equal(%%ext_in,dts),@equal(%%ext_out,dtb))
    dialog enable, Compile
    dialog disable, Decompile
  else
    dialog disable, Compile
    dialog disable, Decompile
  end
  goto EvLoop 


:Close
  inifile close, %%inifile
  stop

:VerifyFile
  %%ext_in = @ext(%%file_in)
  %%name = @name(%%file_in)
  %%path = @path(%%file_in) 

  if @equal(%%ext_in,dtb)
    %%ext_out = dts
  elsif @equal(%%ext_in,dts)
    %%ext_out = dtb
  else
    warn "Not a dtb or dts file!"
    exit
  end

  %%file_out = %%path%%name.%%ext_out

  dialog set, EDIT1, %%file_in
  dialog set, EDIT2, %%file_out

  dialog set, TEXT4,
  dialog hide, TEXT5
  exit

:DRAGDROP
  list create,1
  list dropfiles,1
  %%file_in = @item(1) 
  if @ok()
    gosub VerifyFile
  end
  list close,1
  goto Timer

:SelectBUTTON
  %%file_in = @filedlg("dtc files (*.dts,*dtb)|*.dt?",Open file) 
  if @ok()
    gosub VerifyFile
  end
  goto Timer


:SaveBUTTON
  directory change, %%last_save_path
  %%file_out = @filedlg("dtc files (*.dts,*dtb)|*.dt?",Save file) 

  %%ext_out = @ext(%%file_out)
  %%name = @name(%%file_out)
  %%path_out = @path(%%file_out) 

  if @equal(%%ext_in,dtb)
    %%ext_out = dts
  elsif @equal(%%ext_in,dts)
    %%ext_out = dtb
  end

  %%file_out = %%path_out%%name.%%ext_out

  dialog set, EDIT2, %%file_out
  goto Timer


:CompileBUTTON
:DecompileBUTTON
  # Check if dtc.exe exists
  %%dtcpath = @iniread(main, dtc_path)
  %%dtcexe = %%dtcpath\dtc.exe
  if @null(%%dtcpath)
    warn dtc_path not set in DTC-GUI.ini
    goto EvLoop 
  elsif @not(@file(%%dtcpath,D))
    warn dtc_path does not exist! %%dtcpath
    goto EvLoop 
  elsif @not(@file(%%dtcexe))
    warn dtc.exe does not exist! %%dtcexe
    goto EvLoop 
  end

  directory change, %%dtcpath

  # Debug ---------------------------------------------------------------------
  # dtc.exe -q -I dtb -O dts -o "$dts_file" "$dtb_file"
#  dialog set, TEXT3, dtc.exe -q -I %%ext_in -O %%ext_out -o %%name.%%ext_out %%name.%%ext_in
  #----------------------------------------------------------------------------

  # cmd.exe strips a \ from \\<network-path> so we add an extra \
  if @equal(@substr(%%file_in,1,2),\\)
    %%in_file = \%%file_in
  else
    %%in_file = %%file_in
  end
  if @equal(@substr(%%file_out,1,2),\\)
    %%out_file = \%%file_out
  else
    %%out_file = %%file_out
  end

  # Debug ---------------------------------------------------------------------
  #clipboard set,@chr(34)%%dtcexe@chr(34) -q -I %%ext_in -O %%ext_out -o @chr(34)%%out_file@chr(34) @chr(34)%%in_file@chr(34) 
  #----------------------------------------------------------------------------

  runh cmd /C @chr(34)@chr(34)%%dtcexe@chr(34) -q -I %%ext_in -O %%ext_out -o @chr(34)%%out_file@chr(34) @chr(34)%%in_file@chr(34)@chr(34) ,wait 5 ,pipe
  %%pipe = @pipe() 

  if @null(%%pipe)
    dialog set, TEXT4, Finished
  else
    dialog set, TEXT5, Finished with errors!
    dialog show, TEXT5
    info %%pipe ,
  end
  
  wait event
  goto @event() 


