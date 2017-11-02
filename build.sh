#!/bin/bash
#
# NOTE:  POSIX prefers 'printf' over 'echo'.

missing_llvm=0
missing_clang=0

# Check if LLVM is installed on system
if ! hash llvm-ar 2> /dev/null; then
    printf "[ERROR]  LLVM component not found:  llvm-ar\n"
    missing_llvm=1
fi
if ! hash llvm-as 2> /dev/null; then
    printf "[ERROR]  LLVM component not found:  llvm-as\n"
    missing_llvm=1
fi

# Check if clang is installed on system
if ! hash clang 2> /dev/null; then
    printf "[ERROR]  Clang compiler not found:  clang\n"
    missing_clang=1
fi

if [ $missing_llvm -eq 1 -a $missing_clang -eq 0 ]; then
    printf "\nIn Ubuntu run 'sudo apt install llvm'\n\n"
    exit 1 
fi

if [ $missing_llvm -eq 0 -a $missing_clang -eq 1 ]; then
    printf "\nIn Ubuntu run 'sudo apt install clang'\n\n"
    exit 1 
fi

if [ $missing_llvm -eq 1 -a $missing_clang -eq 1 ]; then
    printf "\nIn Ubuntu run 'sudo apt install llvm clang'\n\n"
    exit 1 
fi

release_mode=0

warnings_to_disable="-std=c++11 -Wno-switch -Wno-pointer-sign -Wno-tautological-constant-out-of-range-compare -Wno-tautological-compare -Wno-macro-redefined -Wno-writable-strings"
libraries="-pthread -ldl -lm -lstdc++"
other_args=""
compiler="clang"

if [ "$release_mode" -eq "0" ]; then
	other_args="${other_args} -g -fno-inline-functions"
fi
if [[ "$(uname)" == "Darwin" ]]; then

	# Set compiler to clang on MacOS
	# MacOS provides a symlink to clang called gcc, but it's nice to be explicit here.
	compiler="clang"

	other_args="${other_args} -liconv"
fi

printf "LLVM & clang installed on system.\n"
printf "Building Odin...\n\n"

printf "${compiler} src/main.cpp ${warnings_to_disable} ${libraries} ${other_args} -o odin\n"
${compiler} src/main.cpp ${warnings_to_disable} ${libraries} ${other_args} -o odin

printf "\nTesting Odin...\n\n"
printf "./odin run examples/demo.odin\n"
./odin run examples/demo.odin

