@echo off
setlocal EnableDelayedExpansion

set file_input=%1
set name=%1
FOR %%f IN (name) do (
   FOR %%g in (!%%f!) do set "%%f=%%~ng"
)

call clang -O2 -c %file_input% -o %name%.o ^
	&& call ar %name%.o -rcs %name%.lib
