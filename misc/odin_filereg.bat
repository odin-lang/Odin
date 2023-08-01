@echo off
@echo Odin file registration
set REG_OPT=/f
set REG_ROOT=HKCR
set ODIN_FILE=%REG_ROOT%\Odin.File
set ODIN_SOURCE_FILE_EXT=%REG_ROOT%\.odin
set ODIN_FOLDER=%REG_ROOT%\Folder\shell\odin
set ODIN_FOLDER_COMMAND=%ODIN_FOLDER%\command
set ACTION=help
set CALL_MODE=batch
set PAUSE_MODE=always
set CONTEXT_MENU_FILE=true
set CONTEXT_MENU_FOLDER=true
for %%x in (%*) do (
	if "%%~x"=="-add" (
		set ACTION=add
   	) else if "%%~x"=="-remove" (
		set ACTION=remove
	) else if "%%~x"=="-help" (
		set ACTION=help
   	) else if "%%~x"=="-use-exe" (
   		set CALL_MODE=exe
   	) else if "%%~x"=="-use-batch" (
   		set CALL_MODE=batch
	) else if "%%~x"=="-use-comspec" (
   		set CALL_MODE=comspec
	) else if "%%~x"=="-pause-on-errors" (
   		set PAUSE_MODE=onerrors
	) else if "%%~x"=="-pause-always" (
   		set PAUSE_MODE=always
	) else if "%%~x"=="-pause-never" (
   		set PAUSE_MODE=never
	) else if "%%~x"=="-context-none" (
   		set CONTEXT_MENU_FILE=false
   		set CONTEXT_MENU_FOLDER=false
	) else if "%%~x"=="-context-file" (
   		set CONTEXT_MENU_FILE=true
   		set CONTEXT_MENU_FOLDER=false
	) else if "%%~x"=="-context-folder" (
   		set CONTEXT_MENU_FILE=false
   		set CONTEXT_MENU_FOLDER=true
	) else if "%%~x"=="-context-all" (
   		set CONTEXT_MENU_FILE=true
   		set CONTEXT_MENU_FOLDER=true
	)
)
if "%ACTION%"=="help" (
	goto show_help
)
:check_permissions
net session >nul 2>&1
if %errorLevel% neq 0 (
	echo Administrative permissions required.
	goto end_of_script
)
if "%ACTION%"=="add" (
	goto add_file_reg
) else if "%ACTION%"=="remove" (
	goto remove_file_reg
) else (
	goto end_of_script
)

:add_file_reg
if not defined ODIN_ROOT (
	echo ODIN_ROOT is NOT defined
	goto end_of_script
)
@echo ODIN_ROOT=%ODIN_ROOT%
set ODIN_EXE=%%ODIN_ROOT%%\odin.exe
if %CALL_MODE%==batch (
	set ODIN_CMD="%%ODIN_ROOT%%\odin.bat run \"%%w\""
	set ODIN_FOLDER_CMD="%%ODIN_ROOT%%\odin.bat %%x \"%%1\""
	set ODIN_BAT=%ODIN_ROOT%\odin.bat
	echo Writeing %ODIN_ROOT%\odin.bat
	echo @Title Odin %%1 %%~f2> %ODIN_ROOT%\odin.bat
	echo @cd %%~f2>> %ODIN_ROOT%\odin.bat
	echo odin.exe %%1 .>> %ODIN_ROOT%\odin.bat
	if %PAUSE_MODE%==onerrors (
		echo @if %%errorlevel%% neq 0 pause>> %ODIN_ROOT%\odin.bat
	) else if %PAUSE_MODE%==always (
		echo @pause>> %ODIN_ROOT%\odin.bat
	)
) else if %CALL_MODE%==comspec (
	if %PAUSE_MODE%==always (
		set ODIN_CMD="%%comspec%% /c %ODIN_EXE% run \"%%w\"&&pause"
		set ODIN_FOLDER_CMD="%%comspec%% /c %ODIN_EXE% %%x \"%%1\"&&pause"
	) else (
		set ODIN_CMD="%%comspec%% /c %ODIN_EXE% run \"%%w\""
		set ODIN_FOLDER_CMD="%%comspec%% /c %ODIN_EXE% %%x \"%%1\""
	)
) else (
	set ODIN_CMD="%ODIN_EXE% run \"%%w\""
	set ODIN_FOLDER_CMD="%ODIN_EXE% %%x \"%%1\""
)
@echo on
reg add "%ODIN_FILE%" /ve /d "Odin source file" %REG_OPT%
reg add "%ODIN_SOURCE_FILE_EXT%" /ve /d "%ODIN_FILE%" %REG_OPT%
if %CONTEXT_MENU_FILE%==true (
	reg add "%ODIN_FILE%\DefaultIcon" /d "%ODIN_EXE%,1" /t REG_EXPAND_SZ %REG_OPT%
	reg add "%ODIN_FILE%\shell" %REG_OPT%
	reg add "%ODIN_FILE%\shell\run" /ve /d "Odin Run" %REG_OPT%
	reg add "%ODIN_FILE%\shell\run\command" /d %ODIN_CMD% /t REG_EXPAND_SZ %REG_OPT%
)
if %CONTEXT_MENU_FOLDER%==true (
	reg add "%ODIN_FOLDER%" /v "MUIVerb" /d "Odin" %REG_OPT%
	reg add "%ODIN_FOLDER%" /v "subcommands" /d "" %REG_OPT%
	reg add "%ODIN_FOLDER%" /v "Icon" /d "%ODIN_EXE%,0" /t REG_EXPAND_SZ %REG_OPT%
	@for %%x in (build,run,check) do (
		reg add "%ODIN_FOLDER%\Shell\%%x" /d "%%x" %REG_OPT%
		reg add "%ODIN_FOLDER%\Shell\%%x\command" /d %ODIN_FOLDER_CMD% /t REG_EXPAND_SZ %REG_OPT%
	)
)
@echo off
goto end_of_script

:remove_file_reg
@echo on
reg delete "%ODIN_FOLDER%" %REG_OPT%
reg delete "%ODIN_SOURCE_FILE_EXT%" %REG_OPT%
reg delete "%ODIN_FILE%" %REG_OPT%
@echo off
goto end_of_script

:show_help
echo.
echo Usage: %~n0 [options]
echo.
echo options: (*) is default
echo.
echo -help             Show help
echo -add              Add application and file extensions
echo -remove           Remove application and file extensions
echo.
echo -use-batch        Use a batch file to call Odin.exe (*)
echo -use-exe          Call Odin.exe directly
echo -use-comspec      Use the defined comspec to call Odin (%comspec%)
echo.
echo -pause-always     Always pause (*)
echo -pause-on-errors  Only pause on error
echo -pause-never      Never pause
echo.
echo -context-none     Register .odin file extentions only
echo -context-file     Add Odin context menu for .odin file extentions
echo -context-folder   Add Odin context menu to folders
echo -context-all      Add both (*)
echo.
echo Note: Using a batch file works best with the pause
echo See:  https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/reg
echo.
@pushd %~dp0..
if not defined ODIN_ROOT (
    echo Environment variable ODIN_ROOT is NOT defined, set it to the folder path for Odin.exe
    echo This can be done by executing the following command:
    echo setx ODIN_ROOT %CD%
) else (
    odin.exe report
    echo.
)
@popd
goto check_permissions

:end_of_script
