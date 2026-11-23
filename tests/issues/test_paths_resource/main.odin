package main

import win32 "core:sys/windows"

main :: proc() {
	name := transmute(win32.LPCWSTR)uintptr(1)
	kind := transmute(win32.LPCWSTR)uintptr(10)
	if win32.FindResourceW(nil, name, kind) == nil {
		panic("the resource was not linked in")
	}
}
