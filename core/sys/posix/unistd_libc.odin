#+build linux, windows, darwin, netbsd, openbsd, freebsd, haiku
package posix

import "core:c"

when ODIN_OS == .Windows {
	foreign import lib "system:libucrt.lib"
} else when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

// unistd.h - standard symbolic constants and types

foreign lib {
	/*
	Checks the file named by the pathname pointed to by the path argument for
	accessibility according to the bit pattern contained in amode. 

	Example:
		if (posix.access("/tmp/myfile", posix.F_OK) != .OK) {
			fmt.printfln("/tmp/myfile access check failed: %v", posix.strerror(posix.errno()))
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/access.html ]]
	*/
	@(link_name=LACCESS)
	access :: proc(path: cstring, amode: Mode_Flags = F_OK) -> result ---

	/*
	Causes the directory named by path to become the current working directory.

	Example:
		if (posix.chdir("/tmp") == .OK) {
			fmt.println("changed current directory to /tmp")
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/chdir.html ]]
	*/
	@(link_name=LCHDIR)
	chdir :: proc(path: cstring) -> result ---

	/*
	Exits but, shall not call functions registered with atexit() nor any registered signal handlers.
	Open streams shall not be flushed.
	Whether open streams are closed (without flushing) is implementation-defined. Finally, the calling process shall be terminated with the consequences described below.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/_exit.html ]]
	*/
	_exit :: proc(status: c.int) -> ! ---

	/*
	Places an absolute pathname of the current working directory into buf.

	Returns: buf as a cstring on success, nil (setting errno) on failure

	Example:
		size: int
		path_max := posix.pathconf(".", ._PATH_MAX)
		if path_max == -1 {
			size = 1024
		} else if path_max > 10240 {
			size = 10240
		} else {
			size = int(path_max)
		}

		buf: [dynamic]byte
		cwd: cstring
		for ; cwd == nil; size *= 2 {
			if err := resize(&buf, size); err != nil {
				fmt.panicf("allocation failure: %v", err)
			}

			cwd = posix.getcwd(raw_data(buf), len(buf))
			if cwd == nil {
				errno := posix.errno()
				if errno != .ERANGE {
					fmt.panicf("getcwd failure: %v", posix.strerror(errno))
				}
			}
		}

		fmt.println(path_max, cwd)

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getcwd.html ]]
	*/
	@(link_name=LGETCWD)
	getcwd :: proc(buf: [^]c.char, size: c.size_t) -> cstring ---

	/*
	Remove an (empty) directory.

	]] More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/rmdir.html ]]
	*/
	@(link_name=LRMDIR)
	rmdir :: proc(path: cstring) -> result ---

	/*
	Copy nbyte bytes, from src, to dest, exchanging adjecent bytes.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/swab.html ]]
	*/
	@(link_name=LSWAB)
	swab :: proc(src: [^]byte, dest: [^]byte, nbytes: c.ssize_t) ---

	/*
	Remove a directory entry.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/unlink.html ]]
	*/
	@(link_name=LUNLINK)
	unlink :: proc(path: cstring) -> result ---
}

when ODIN_OS == .Windows {
	@(private) LACCESS :: "_access"
	@(private) LCHDIR  :: "_chdir"
	@(private) LGETCWD :: "_getcwd"
	@(private) LRMDIR  :: "_rmdir"
	@(private) LSWAB   :: "_swab"
	@(private) LUNLINK :: "_unlink"
} else {
	@(private) LACCESS :: "access"
	@(private) LCHDIR  :: "chdir"
	@(private) LGETCWD :: "getcwd"
	@(private) LRMDIR  :: "rmdir"
	@(private) LSWAB   :: "swab"
	@(private) LUNLINK :: "unlink"
}

STDERR_FILENO :: 2
STDIN_FILENO  :: 0
STDOUT_FILENO :: 1

Mode_Flag_Bits :: enum c.int {
	X_OK = log2(X_OK),
	W_OK = log2(W_OK),
	R_OK = log2(R_OK),
}
Mode_Flags :: bit_set[Mode_Flag_Bits; c.int]

#assert(_F_OK == 0)
F_OK :: Mode_Flags{}

when ODIN_OS == .Windows {
	_F_OK :: 0
	X_OK  :: 1
	W_OK  :: 2
	R_OK  :: 4
	#assert(W_OK|R_OK == 6)
}
