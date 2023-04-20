#!/bin/bash
OS=$(uname)

panic() {
	printf "%s\n" "$1"
	exit 1
}

assert_vendor() {
	if [ $(basename $(pwd)) != 'vendor' ]; then
		panic "Not in vendor directory!"
	fi
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
		assert_vendor
		remove_windows_libraries
		remove_macos_libraries
		;;
	Darwin)
		assert_vendor
		remove_windows_libraries
		remove_linux_libraries
		;;
	OpenBSD)
		assert_vendor
		remove_windows_libraries
		remove_macos_libraries
		remove_linux_libraries
		;;
	FreeBSD)
		assert_vendor
		remove_windows_libraries
		remove_macos_libraries
		remove_linux_libraries
		;;
*)
	panic "Platform unsupported!"
esac
