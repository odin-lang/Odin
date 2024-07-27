package posix

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// sys/utsname.h = system name structure

foreign lib {
	/*
	Stores information identifying the current system in the given structure.

	Returns: non-negative on success, -1 (setting errno) on failure

	NOTE: have a look at `core:sys/info` for similar/better system information.
	
	Example:
		uname: posix.utsname
		posix.uname(&uname)
		fmt.printfln("%#v", uname)

	Possible Output:
		utsname{
			sysname = Darwin,
			nodename = Laytans-MacBook-Pro.local,
			release = 23.5.0,
			version = Darwin Kernel Version 23.5.0: Wed May  1 20:16:51 PDT 2024; root:xnu-11331.111.3~1/RELEASE_ARM64_T8103,
			machine = arm64,
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/uname.html ]]
	*/
	uname :: proc(uname: ^utsname) -> c.int ---
}

when ODIN_OS == .Darwin || ODIN_OS == .FreeBSD || ODIN_OS == .NetBSD || ODIN_OS == .OpenBSD {

	@(private)
	_SYS_NAMELEN :: 256

	utsname :: struct {
		sysname:  [_SYS_NAMELEN]c.char `fmt:"s,0"`, /* [PSX] name of OS */
		nodename: [_SYS_NAMELEN]c.char `fmt:"s,0"`, /* [PSX] name of this network node */
		release:  [_SYS_NAMELEN]c.char `fmt:"s,0"`, /* [PSX] release level */
		version:  [_SYS_NAMELEN]c.char `fmt:"s,0"`, /* [PSX] version level */
		machine:  [_SYS_NAMELEN]c.char `fmt:"s,0"`, /* [PSX] hardware type */
	}

} else {
	#panic("posix is unimplemented for the current target")
}
