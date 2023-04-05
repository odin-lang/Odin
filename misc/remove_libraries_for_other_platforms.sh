#!/bin/bash
OS=$(uname)

panic() {
	printf "%s\n" "$1"
	exit 1
}

remove_windows_libraries() {
	find . -type f -name '*.dll' | xargs rm -f 
	find . -type f -name '*.lib' | xargs rm -f
	find . -type d -name 'windows' | xargs rm -rf
}

remove_macos_libraries() {
	find . -type f -name '*.dylib' | xargs rm -f 
	find . -type d -name '*macos*' | xargs rm -rf
}

remove_linux_libraries() {
	find . -type f -name '*.so' | xargs rm -f 
	find . -type d -name 'linux' | xargs rm -rf
}

case $OS in
	Linux)
		remove_windows_libraries
		remove_macos_libraries
		;;
	Darwin)
		remove_windows_libraries
		remove_linux_libraries
		;;
	OpenBSD)
		remove_windows_libraries
		remove_macos_libraries
		remove_linux_libraries
		;;
	FreeBSD)
		remove_windows_libraries
		remove_macos_libraries
		remove_linux_libraries
		;;
*)
	panic "Platform unsupported!"
esac
