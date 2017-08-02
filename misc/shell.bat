@echo off

set bdir=%~dp0
SET sdir=%cd%
IF EXIST "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Auxiliary\Build\vcvarsall.bat" (
    CALL "C:\Program Files (x86)\Microsoft Visual Studio\2017\Professional\VC\Auxiliary\Build\vcvarsall.bat" x64 1> NUL
) ELSE (
    IF EXIST "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" (
        CALL "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" x64 1> NUL
    ) ELSE (
        IF EXIST "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" (
            CALL "C:\Program Files (x86)\Microsoft Visual Studio 12.0\VC\vcvarsall.bat" x64 1> NUL
        ) ELSE (
            IF EXIST "C:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\vcvarsall.bat" (
                CALL "C:\Program Files (x86)\Microsoft Visual Studio 11.0\VC\vcvarsall.bat" x64 1> NUL
            ) ELSE (
                ECHO Could not find "vcvarsall.bat". Ensure your have the VC++ compiler installed.
            )
        )
    )
)

set _NO_DEBUG_HEAP=1
cd %sdir%
set path=%bdir%;%path%
cls
