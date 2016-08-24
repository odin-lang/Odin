@echo off
setlocal EnableDelayedExpansion

set file_input=%1
set name=%1
FOR %%f IN (name) do (
   FOR %%g in (!%%f!) do set "%%f=%%~ng"
)

cl -nologo -O2 -MT -TP -c %file_input% ^
	&& lib -nologo %name%.obj -out:%name%.lib ^
	&& del *.obj
