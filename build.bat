@echo off

set base_dir=W:\Odin
:: Make sure this is a decent name and not generic
set exe_name=odin.exe

:: Debug = 0, Release = 1
set release_mode=0

set compiler_flags= -nologo -Oi -TP -W4 -fp:fast -fp:except- -Gm- -MP -FC -Z7 -GS- -EHsc- -GR-

if %release_mode% EQU 0 ( rem Debug
	set compiler_flags=%compiler_flags% -Od -MDd -Z7
) else ( rem Release
	set compiler_flags=%compiler_flags% -O2 -MT
)

set compiler_warnings= ^
	-we4013 -we4706 ^
	-wd4100 -wd4127 -wd4189 ^
	-wd4201 -wd4204 -wd4244 ^
	-wd4306 ^
	-wd4480 ^
	-wd4505 -wd4512 -wd4550

set compiler_includes=-I"C:\Program Files\LLVM\include"

set libs= kernel32.lib user32.lib gdi32.lib opengl32.lib ^
	-libpath:"C:\Program Files\LLVM\lib"

	rem LLVMX86Disassembler.lib ^
	rem LLVMX86AsmParser.lib ^
	rem LLVMX86CodeGen.lib ^
	rem LLVMSelectionDAG.lib ^
	rem LLVMAsmPrinter.lib ^
	rem LLVMCodeGen.lib ^
	rem LLVMTarget.lib ^
	rem LLVMScalarOpts.lib ^
	rem LLVMInstCombine.lib ^
	rem LLVMInstrumentation.lib ^
	rem LLVMProfileData.lib ^
	rem LLVMTransformUtils.lib ^
	rem LLVMBitWriter.lib ^
	rem LLVMAnalysis.lib ^
	rem LLVMX86Desc.lib ^
	rem LLVMObject.lib ^
	rem LLVMMCParser.lib ^
	rem LLVMBitReader.lib ^
	rem LLVMMCDisassembler.lib ^
	rem LLVMX86Info.lib ^
	rem LLVMX86AsmPrinter.lib ^
	rem LLVMMC.lib ^
	rem LLVMX86Utils.lib ^
	rem LLVMCore.lib ^
	rem LLVMSupport.lib



set linker_flags= -incremental:no -opt:ref -subsystem:console

rem Debug
if %release_mode% EQU 0 (set linker_flags=%linker_flags% -debug)

set compiler_settings=%compiler_includes% %compiler_flags% %compiler_warnings%
set linker_settings=%libs% %linker_flags%


set build_dir= "%base_dir%\bin\"
if not exist %build_dir% mkdir %build_dir%
pushd %build_dir%
	del *.pdb > NUL 2> NUL
	del *.ilk > NUL 2> NUL

	del ..\misc\*.pdb > NUL 2> NUL
	del ..\misc\*.ilk > NUL 2> NUL

	cl %compiler_settings% "%base_dir%\src\main.cpp" ^
		/link %linker_settings% -OUT:%exe_name% ^
		&& call run.bat

	:do_not_compile_exe
popd
:end_of_build

