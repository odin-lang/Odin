package main

import "core:fmt"

main :: proc() {
	fmt.printf("Hellope core:build!\n")
	fmt.printf("We defined a string in the build system with the value \"%v\"\n", #config(DEFINED_STRING, "!(INVALID)"))
}