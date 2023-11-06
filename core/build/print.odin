package build

import "core:fmt"
import "core:io"
import "core:os"
import "core:log"

/*
	Note(Dragos): These functions are to separate the type of output for easier testing. We could remove them eventually once the final API is in place
*/

_ :: fmt
_ :: io
_ :: os

printf_info :: proc(format: string, args: ..any, location := #caller_location) {
	log.infof(format, args, location)
}

// for printing shell programs/scripts
printf_program :: proc(format: string, args: ..any, location := #caller_location) {
	log.infof(format, args, location)
}

printf_warning :: proc(format: string, args: ..any, location := #caller_location) {
	log.warnf(format, args, location)
}

printf_error :: proc(format: string, args: ..any, location := #caller_location) {
	log.errorf(format, args, location)
}