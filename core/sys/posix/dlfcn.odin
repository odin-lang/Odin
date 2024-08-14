package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else when ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD {
	foreign import lib "system:dl"
} else {
	foreign import lib "system:c"
}

// dlfcn.h - dynamic linking

foreign lib {
	/*
	inform the system that the object referenced by a handle returned from a previous dlopen() 
	invocation is no longer needed by the application.

	Returns: 0 on success, non-zero on failure (use dlerror() for more information)

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/dlclose.html ]]
	*/
	dlclose :: proc(handle: Symbol_Table) -> c.int ---

	/*
	return a null-terminated character string (with no trailing <newline>) that describes
	the last error that occurred during dynamic linking processing.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/dlerror.html ]]
	*/
	dlerror :: proc() -> cstring ---

	/*
	Make the symbols (function identifiers and data object identifiers) in the executable object
	file specified by file available to the calling program.

	Returns: a reference to the symbol table on success, nil on failure (use dlerror() for more information)

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/dlopen.html ]]
	*/
	dlopen :: proc(file: cstring, mode: RTLD_Flags) -> Symbol_Table ---

	/*
	Obtain the address of a symbol (a function identifier or a data object identifier)
	defined in the symbol table identified by the handle argument.

	Returns: the address of the matched symbol on success, nil on failure (use dlerror() for more information)

	Example:
		handle := posix.dlopen("/usr/home/me/libfoo.so", posix.RTLD_LOCAL + { .RTLD_LAZY })
		defer posix.dlclose(handle)

		if handle == nil {
			panic(string(posix.dlerror()))
		}

		foo: proc(a, b: int) -> int
		foo = auto_cast posix.dlsym(handle, "foo")

		if foo == nil {
			panic(string(posix.dlerror()))
		}

		fmt.printfln("foo(%v, %v) == %v", 1, 2, foo(1, 2))

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/dlsym.html ]]
	*/
	dlsym :: proc(handle: Symbol_Table, name: cstring) -> rawptr ---
}

RTLD_Flag_Bits :: enum c.int {
	LAZY   = log2(RTLD_LAZY),
	NOW    = log2(RTLD_NOW),
	GLOBAL = log2(RTLD_GLOBAL),

 	// NOTE: use with `posix.RTLD_LOCAL + { .OTHER_FLAG, .OTHER_FLAG }`, unfortunately can't be in
	// this bit set enum because it is 0 on some platforms and a value on others.
	// LOCAL = RTLD_LOCAL

	_MAX = 31,
}
RTLD_Flags :: bit_set[RTLD_Flag_Bits; c.int]

Symbol_Table :: distinct rawptr

when ODIN_OS == .Darwin {

	RTLD_LAZY    :: 0x1
	RTLD_NOW     :: 0x2
	_RTLD_LOCAL  :: 0x4
	RTLD_GLOBAL  :: 0x8

	RTLD_LOCAL   :: RTLD_Flags{RTLD_Flag_Bits(log2(_RTLD_LOCAL))}

} else when ODIN_OS == .FreeBSD || ODIN_OS == .OpenBSD {

	RTLD_LAZY    :: 1
	RTLD_NOW     :: 2
	_RTLD_LOCAL  :: 0
	RTLD_GLOBAL  :: 0x100

	RTLD_LOCAL   :: RTLD_Flags{}

} else when ODIN_OS == .NetBSD {

	RTLD_LAZY    :: 0x1
	RTLD_NOW     :: 0x2
	_RTLD_LOCAL  :: 0x200
	RTLD_GLOBAL  :: 0x100

	RTLD_LOCAL   :: RTLD_Flags{RTLD_Flag_Bits(log2(_RTLD_LOCAL))}

} else {
	#panic("posix is unimplemented for the current target")
}

