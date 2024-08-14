package posix

import "core:c"

when ODIN_OS == .Darwin {
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
	access :: proc(path: cstring, amode: Mode_Flags = F_OK) -> result ---

	/*
	Equivalent to `access` but relative paths are resolved based on `fd`.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/access.html ]]
	*/
	faccessat :: proc(fd: FD, path: cstring, amode: Mode_Flags, flag: AT_Flags) -> result ---

	/*
	The alarm() function shall cause the system to generate a SIGALRM signal for the process after the number of realtime seconds specified by seconds have elapsed. Processor scheduling delays may prevent the process from handling the signal as soon as it is generated.

	If seconds is 0, a pending alarm request, if any, is canceled.

	Returns: the time left on the previous alarm() or 0

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/alarm.html ]]
	*/
	alarm :: proc(seconds: c.uint) -> c.uint ---

	/*
	Causes the directory named by path to become the current working directory.

	Example:
		if (posix.chdir("/tmp") == .OK) {
			fmt.println("changed current directory to /tmp")
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/chdir.html ]]
	*/
	chdir :: proc(path: cstring) -> result ---

	/*
	Equivalent to chdir but instead of a path the fildes is resolved to a directory.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/fchdir.html ]]
	*/
	fchdir :: proc(fildes: FD) -> result ---

	/*
	Changes the user and group ownership of a file.

	If owner or group is specified as (uid_t)-1 or (gid_t)-1, respectively, the corresponding ID of the file shall not be changed.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/chown.html ]]
	*/
	@(link_name=LCHOWN)
	chown :: proc(path: cstring, owner: uid_t, group: gid_t) -> result ---

	/*
	Equivalent to chown expect that it takes a file descriptor.

	Example:
		fildes := posix.open("/home/cnd/mod1", {.RDWR})
		pwd := posix.getpwnam("jones")
		grp := posix.getgrnam("cnd")
		posix.fchown(fildes, pwd.pw_uid, grp.gr_gid)

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/fchown.html ]]
	*/
	@(link_name=LFCHOWN)
	fchown :: proc(fildes: FD, owner: uid_t, mode: gid_t) -> result ---

	/*
	Equivalent to fchown except that relative paths are based on the given fildes.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/chown.html ]]
	*/
	fchownat :: proc(fildes: FD, path: cstring, owner: uid_t, group: gid_t, flag: AT_Flags) -> result ---

	/*
	If path points to a symbolic link, the owner and group of the link itself is changed.
	Equivalent to chown on normal files.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/lchown.html ]]
	*/
	@(link_name=LLCHOWN)
	lchown :: proc(path: cstring, owner: uid_t, group: gid_t) -> result ---

	/*
	Deallocates the file descriptor indicated by fildes. 

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/close.html ]]
	*/
	close :: proc(fildes: FD) -> result ---

	/*
	Return configuration-defined string values.
	Its use and purpose are similar to sysconf(), but it is used where string values rather than numeric values are returned.

	Returns: 0 (setting errno) if `name` is invalid, need `buf` `len` if buf is `nil`, amount of bytes added to buf otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/confstr.html ]]
	*/
	confstr :: proc(name: CS, buf: [^]c.char, len: c.size_t) -> c.size_t ---

	/*
	Determines the current value of a configurable limit or option that is associated with a file or directory.

	Returns: value on success, -1 (setting errno) on failure, -1 (no errno) if the variable should be taken from limits

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/fpathconf.html ]]
	*/
	pathconf :: proc(path: cstring, name: PC) -> c.long ---

	/*
	Equivalent to pathconf but takes a file descriptor instead of a path.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/fpathconf.html ]]
	*/
	fpathconf :: proc(fildes: FD, name: PC) -> c.long ---

	/*
	Determines the current value of configurable system limit or options.

	Returns: value on success, -1 (setting errno) on failure, -1 (no errno) if the variable should be taken from limits

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sysconf.html ]]
	*/
	sysconf :: proc(name: SC) -> c.long ---

	/*
	A string encoding function. The algorithm is implementation-defined.

	The use of crypt() for anything other than password hashing is not recommended.

	Returns: a static string overwritten by subsequent calls, `nil` (setting errno) on failure
	*/
	crypt :: proc(key: cstring, salt: cstring) -> cstring ---

	/*
	An implementation-defined encoding algorithm.
	The key generated by setkey() is used to encrypt the string block with encrypt().

	block must be 64 bytes.

	decode controls if the block is encoded or decoded.

	May set errno to ENOSYS if the functionality is not supported.

	Example:
		block: [64]byte
		copy(block[:], "Hello, World!")

		posix.set_errno(.NONE)
		posix.encrypt(raw_data(block[:]), decode=false)
		assert(posix.errno() == .NONE, "encrypt not supported")

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/encrypt.html ]]
	*/
	encrypt :: proc(block: [^]c.char, decode: b32) ---

	/*
	Returns a new file descriptor referring to the one given, sharing locks, clearing CLOEXEC.

	Returns: -1 (setting errno) on failure, the new file descriptor on success

	Example:
		// Redirecting stdout to a file:
		file := posix.open("/tmp/out", { .RDWR })
		posix.close(1)
		posix.dup(file)
		posix.close(file)

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/dup.html ]] 
	*/
	dup :: proc(fildes: FD) -> FD ---

	/*
	Causes the file descriptor fildes2 to refer to the same open file description as
	the file descriptor fildes and to share any locks, and shall return fildes2.

	Returns: -1 (setting errno) on failure, fildes2 on success

	Example:
		// Redirecting stderr to stdout:
		posix.dup2(1, 2)

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/dup.html ]] 
	*/
	dup2 :: proc(fildes, fildes2: FD) -> FD ---

	/*
	Exits but, shall not call functions registered with atexit() nor any registered signal handlers.
	Open streams shall not be flushed.
	Whether open streams are closed (without flushing) is implementation-defined. Finally, the calling process shall be terminated with the consequences described below.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/_exit.html ]]
	*/
	_exit :: proc(status: c.int) -> ! ---

	/*
	The exec family of functions shall replace the current process image with a new process image.
	The new image shall be constructed from a regular, executable file called the new process image file.
	There shall be no return from a successful exec,
	because the calling process image is overlaid by the new process image.

	Takes arguments as varargs and the last of them must be nil.

	Example:
		ret := posix.execl("/bin/ls", "ls", "-l", nil)
		fmt.panicf("could not execute: %v %v", ret, posix.strerror(posix.errno()))

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/execl.html ]]
	*/
	execl :: proc(path: cstring, arg0: cstring, #c_vararg args: ..cstring) -> c.int ---

	/*
	The exec family of functions shall replace the current process image with a new process image.
	The new image shall be constructed from a regular, executable file called the new process image file.
	There shall be no return from a successful exec,
	because the calling process image is overlaid by the new process image.

	Takes arguments as varargs and the last of them must be nil.
	After the arguments an array of environment strings (also nil terminated) is expected.

	Example:
		env := []cstring{
			"HOME=/usr/home",
			"LOGNAME=home",
			nil,
		}
		ret := posix.execle("/bin/ls", "ls", cstring("-l"), cstring(nil), raw_data(env))
		fmt.panicf("could not execute: %v", posix.strerror(posix.errno()))

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/execl.html ]]
	*/
	execle :: proc(path: cstring, arg0: cstring, #c_vararg args: ..any) -> c.int ---

	/*
	The exec family of functions shall replace the current process image with a new process image.
	The new image shall be constructed from a regular, executable file called the new process image file.
	There shall be no return from a successful exec,
	because the calling process image is overlaid by the new process image.

	If file does not contain a slash the PATH environment variable is searched for a matching file.
	Takes arguments as varargs and the last of them must be nil.

	Example:
		ret := posix.execlp("ls", "-l", cstring(nil))
		fmt.panicf("could not execute: %v, %v", ret, posix.strerror(posix.errno()))

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/execl.html ]]
	*/
	execlp :: proc(file: cstring, arg0: cstring, #c_vararg args: ..cstring) -> c.int ---

	/*
	The exec family of functions shall replace the current process image with a new process image.
	The new image shall be constructed from a regular, executable file called the new process image file.
	There shall be no return from a successful exec,
	because the calling process image is overlaid by the new process image.

	Takes arguments as an array which should be nil terminated.

	Example:
		args := []cstring{ "ls", "-l", nil }
		ret := posix.execv("/bin/ls", raw_data(args))
		fmt.panicf("could not execute: %v, %v", ret, posix.strerror(posix.errno()))

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/execl.html ]]
	*/
	execv :: proc(path: cstring, argv: [^]cstring) -> c.int ---

	/*
	The exec family of functions shall replace the current process image with a new process image.
	The new image shall be constructed from a regular, executable file called the new process image file.
	There shall be no return from a successful exec,
	because the calling process image is overlaid by the new process image.

	If file does not contain a slash the PATH environment variable is searched for a matching file.
	Takes arguments as an array which should be nil terminated.

	Example:
		cmd := []cstring{ "ls", "-l", nil }
		ret := posix.execvp("ls", raw_data(cmd))
		fmt.panicf("could not execute: %v, %v", ret, posix.strerror(posix.errno()))

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/execl.html ]]
	*/
	execvp :: proc(file: cstring, argv: [^]cstring) -> c.int ---

	/*
	The exec family of functions shall replace the current process image with a new process image.
	The new image shall be constructed from a regular, executable file called the new process image file.
	There shall be no return from a successful exec,
	because the calling process image is overlaid by the new process image.

	Takes arguments as an array which should be nil terminated.
	Takes environment variables as an array which should be nil terminated.

	Example:
		cmd := []cstring{ "ls", "-l", nil }
		env := []cstring{ "HOME=/usr/home", "LOGNAME=home", nil }
		ret := posix.execve("/bin/ls", raw_data(cmd), raw_data(env))
		fmt.panicf("could not execute: %v, %v", ret, posix.strerror(posix.errno()))

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/execl.html ]]
	*/
	execve :: proc(path: cstring, argv: [^]cstring, envp: [^]cstring) -> c.int ---

	/*
	The exec family of functions shall replace the current process image with a new process image.
	The new image shall be constructed from a regular, executable file called the new process image file.
	There shall be no return from a successful exec,
	because the calling process image is overlaid by the new process image.

	Equivalent to execve but takes a file descriptor instead of a path.

	Example:
		ls := posix.open("/bin/ls", { .EXEC })
		cmd := []cstring{ "ls", "-l", nil }
		env := []cstring{ "HOME=/usr/home", "LOGNAME=home", nil }
		ret := posix.fexecve(ls, raw_data(cmd), raw_data(env))
		fmt.panicf("could not execute: %v, %v", ret, posix.strerror(posix.errno()))

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/execl.html ]]
	*/
	fexecve :: proc(fd: FD, argv: [^]cstring, envp: [^]cstring) -> c.int ---

	/*
	Example:
		for i, entry := 0, posix.environ[0]; entry != nil; i, entry = i+1, posix.environ[i] {
			fmt.println(entry)
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/execl.html ]]
	*/
	environ: [^]cstring

	/*
	Forcec all currently queued I/O operations associated with the file indicated by file descriptor
	fildes to the synchronized I/O completion state.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/fdatasync.html ]]
	*/
	fdatasync :: proc(fd: FD) -> result ---

	/*
	The fork() function shall create a new process.
	The new process (child process) shall be an exact copy of the calling process (parent process).
	With some exceptions outlined below.

	Result: -1 (setting errno) on failure, otherwise 0 to the child process and the child process id to the parent process.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/fork.html ]]
	*/
	fork :: proc() -> pid_t ---

	/*
	Requests that all data for the open file descriptor named by fildes is to be transferred
	to the storage device associated with the file described by fildes.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/fsync.html ]]
	*/
	fsync :: proc(fildes: FD) -> result ---

	/*
	Truncates a file to the specified length.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/truncate.html ]]
	*/
	truncate :: proc(path: cstring, length: off_t) -> result ---

	/*
	Truncates a file to the specified length.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/ftruncate.html ]]
	*/
	ftruncate :: proc(fildes: FD, length: off_t) -> result ---

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
	getcwd :: proc(buf: [^]c.char, size: c.size_t) -> cstring ---

	/*
	Returns the effective group ID of the calling process.

	Returns: the ID, no failure is defined

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getegid.html ]]
	*/
	getegid :: proc() -> gid_t ---

	/*
	Returns the effective user ID of the calling process.

	Returns: the ID, no failure is defined

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/geteuid.html ]]
	*/
	geteuid :: proc() -> uid_t ---

	/*
	Returns the real group ID of the calling process.

	Returns: the ID, no failure is defined

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getgid.html ]]
	*/
	getgid :: proc() -> gid_t ---

	/*
	Fills the grouplist array with the current supplementary group IDs of the calling process.

	Returns: -1 (setting errno) on failure, desired grouplist length if gidsetsize is 0, amount of IDs added otherwise

	Example:
		length := posix.getgroups(0, nil)
		if length == -1 {
			fmt.panicf("getgroups failure: %v", posix.strerror(posix.errno()))
		}

		groups := make([]posix.gid_t, length) or_else panic("allocation failure")
		if posix.getgroups(length, raw_data(groups)) != length {
			fmt.panicf("getgroups failure: %v", posix.strerror(posix.errno()))
		}

		fmt.println(groups)

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getgroups.html ]]
	*/
	getgroups :: proc(gidsetsize: c.int, grouplist: [^]gid_t) -> c.int ---

	/*
	Retrieves a 32-bit identifier for the current host.

	Returns: the ID, no failure is defined

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/gethostid.html ]]
	*/
	gethostid :: proc() -> c.long ---

	/*
	Returns the standard host name for the current machine.

	Host names are limited to HOST_NAME_MAX bytes.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/gethostname.html ]]
	*/
	gethostname :: proc(name: [^]c.char, namelen: c.size_t) -> result ---

	/*
	Returns a string containing the user name associated by the login activity.

	Returns: nil (setting errno) on failure, the login name otherwise in a potentially static buffer overwritten by subsequent calls

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getlogin.html ]]
	*/
	getlogin :: proc() -> cstring ---

	/*
	Equivalent to getlogin but puts the name in the name buffer given.

	The name is limited to LOGIN_NAME_MAX bytes.

	Example:
		max := posix.sysconf(posix._SC_LOGIN_NAME_MAX)+1
		buf := make([]byte, max)
		posix.getlogin_r(raw_data(buf), uint(len(max)))
		fmt.printfln("login: %v", cstring(buf))

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getlogin.html ]]
	*/
	getlogin_r :: proc(name: [^]c.char, namelen: c.size_t) -> Errno ---

	/*
	A command-line parser, see linked docs.

	Example:
		// The following code fragment shows how you might process the arguments for a utility that
		// can take the mutually-exclusive options a and b and the options f and o, both of which
		// require arguments.

		bflg, aflg, errflg: bool
		ifile: string
		ofile: string

		for {
			c := posix.getopt(i32(len(runtime.args__)), raw_data(runtime.args__), ":abf:o:")
			(c != -1) or_break

			switch c {
			case 'a':
				if bflg {
					errflg = true
				} else {
					aflg = true
				}
			case 'b':
				if aflg {
					errflg = true
				} else {
					bflg = true
				}
			case 'f':
				ifile = string(posix.optarg)
			case 'o':
				ofile = string(posix.optarg)
			case ':': /* -f or -o without operand */
				fmt.eprintfln("Option -%c requires an operand", posix.optopt)
				errflg = true
			case '?':
				fmt.eprintfln("Unrecognized option: '-%c'", posix.optopt)
				errflg = true
			}
		}

		if errflg {
			fmt.eprintfln("usage: . . . ")
			posix.exit(2)
		}

		// Loop through remaining arguments:
		for ; posix.optind < i32(len(runtime.args__)); posix.optind += 1 {
			fmt.println(runtime.args__[posix.optind])
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getopt.html ]]
	*/
	getopt :: proc(argc: c.int, argv: [^]cstring, optstring: cstring) -> c.int ---

	optarg: cstring
	opterr: c.int
	optind: c.int
	optopt: c.int

	/*
	Returns the process group ID of the process whose process ID is equal to pid.
	If pid is 0, it returns the process group ID of the calling process.

	Returns: -1 on failure, the ID otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getpgid.html ]]
	*/
	getpgid :: proc(pid: pid_t) -> pid_t ---

	/*
	Returns the process group ID of the calling process.

	Returns: no failure

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getpgrp.html ]]
	*/
	getpgrp :: proc() -> pid_t ---

	/*
	Returns the ID of the calling process.

	Returns: no failure

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getpid.html ]]
	*/
	getpid :: proc() -> pid_t ---

	/*
	Returns the parent process ID.

	Returns: no failure

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getppid.html ]]
	*/
	getppid :: proc() -> pid_t ---


	/*
	Get the process group ID of the session leader.
	If pid is 0, it is the current process.

	Returns: -1 (setting errno) on failure, the pid otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getsid.html ]]
	*/
	getsid :: proc(pid: pid_t) -> pid_t ---

	/*
	Returns the real user ID of the calling process.

	Returns: no failure

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getuid.html ]]
	*/
	getuid :: proc() -> uid_t ---

	/*
	Tests whether fildes is associated with a terminal device.

	Returns: false (setting errno) if fildes is invalid or not a terminal, true otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/isatty.html ]]
	*/
	isatty :: proc(fildes: FD) -> b32 ---

	/*
	Creates a new link for the existing file path1 to path2.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/link.html ]]
	*/
	link :: proc(path1: cstring, path2: cstring) -> result ---

	/*
	If path1 is relative it is relative to directory fd1.
	If path2 is relative it is relative to directory fd2.
	If flag is { .SYMLINK_FOLLOW } path1 is resolved to its link if it is a link.
	Equivalent to link otherwise.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/link.html ]]
	*/
	linkat :: proc(fd1: FD, path1: cstring, fd2: FD, path2: cstring, flag: AT_Flags) -> result ---

	/*
	Creates a symbolic link called path2 that contains a link to path1.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/symlink.html ]]
	*/
	symlink :: proc(path1: cstring, path2: cstring) -> result ---

	/*
	Equivalent to symlink but relative paths are resolved to dir fd.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/symlink.html ]]
	*/
	symlinkat :: proc(path1: cstring, fd: FD, path2: cstring) -> result ---

	/*
	Locks sections of a file with advisory-mode locks.

	Example:
		fildes := posix.open("/home/cnd/mod1", { .RDWR })
		if posix.lockf(fildes, .TLOCK, 10000) != .OK {
			errno := posix.errno(); #partial switch errno {
			case .EACCES, .EAGAIN:
				// File is already locked.
			case:
				// Other error.
				fmt.panicf("lockf failure: %v", posix.strerror(errno))
			}
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/lockf.html ]]
	*/
	lockf :: proc(fildes: FD, function: Lock_Function, size: off_t) -> result ---

	/*
	Sets the file offset of the given file descriptor.

	If whence is .SET, the offset is set
	If whence is .CUR, the offset is the current offset + given offset
	If whence is .END, the offset is set to the size of the file + given offset

	Returns: the resulting offset or -1 (setting errno)

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/lseek.html ]]
	*/
	lseek :: proc(fildes: FD, offset: off_t, whence: Whence) -> off_t ---

	/*
	Changes the nice value of a process.

	Higher values result in less favorable scheduling.

	Because -1 is a valid nice value, checking failure would be done by first setting errno to .NONE
	and then calling nice.

	Returns: the new nice value, or -1 (setting) errno on failure

	Example:
		posix.set_errno(.NONE)
		niceness := posix.nice(-20)
		if errno := posix.errno(); niceness == -1 && errno != .NONE {
			fmt.panicf("nice failure: %v", posix.strerror(errno))
		}
		fmt.printfln("Niceness is now: %v", niceness)

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/nice.html ]]
	*/
	nice :: proc(incr: c.int) -> c.int ---

	/*
	Suspend the thread until a signal is received.

	Returns: -1 (setting errno to EINTR)

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pause.html ]]
	*/
	pause :: proc() -> c.int ---

	/*
	Create an interprocess channel.

	Example:
		fildes: [2]posix.FD
		if posix.pipe(&fildes) != .OK {
			// Handle error ...
		}

		switch posix.fork() {
		case -1:
			// Handle error ...

		case 0: /* Child - reads from pipe */
			BSIZE :: 100
			buf: [BSIZE]byte
			nbytes: int

			posix.close(fildes[1])                                  /* Write end is unused */
			nbytes = posix.read(fildes[0], raw_data(buf[:]), BSIZE) /* Get data from pipe */
			/* At this point, a further read would see end-of-file ... */
			posix.close(fildes[0])                                  /* Finished with pipe */

			fmt.println(string(buf[:nbytes]))

			posix.exit(0)

		case: /* Parent - write to pipe */
			msg := raw_data(transmute([]byte)string("Hello world\n"))
			posix.close(fildes[0])           /* Read end is unused */
			posix.write(fildes[1], msg, 12); /* Write data on pipe */
			posix.close(fildes[1])
			posix.exit(0)
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pipe.html ]]
	*/
	pipe :: proc(fildes: ^[2]FD) -> result ---

	/*
	Read from a file.

	Returns: the amount of bytes read or -1 (setting errno) on failure

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pread.html ]]
	*/
	read :: proc(fd: FD, buf: [^]byte, nbyte: c.size_t) -> c.ssize_t ---

	/*
	Equivalent to read on a specified offset instead of the internal offset.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/pread.html ]]
	*/
	pread :: proc(fd: FD, buf: [^]byte, nbyte: c.size_t, offset: off_t) -> c.ssize_t ---

	/*
	Write on a file.

	Returns: the amount of bytes written or -1 (setting errno) on failure.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/write.html ]]
	*/
	write :: proc(fd: FD, buf: [^]byte, buflen: c.size_t) -> c.ssize_t ---

	/*
	Equivalent to write on a specified offset instead of the internal offset.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/write.html ]]
	*/
	pwrite :: proc(fd: FD, buf: [^]byte, buflen: c.size_t, offset: off_t) -> c.ssize_t ---

	/*
	Read the contents of a symbolic link.

	Returns: the amount of bytes read or -1 (setting errno) on failure.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/readlink.html ]]
	*/
	readlink :: proc(path: cstring, buf: [^]byte, bufsize: c.size_t) -> c.ssize_t ---

	/*
	Equivalent to readlink but relative paths are resolved based on the dir fd.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/readlink.html ]]
	*/
	readlinkat :: proc(fd: FD, path: cstring, buf: [^]byte, bufsize: c.size_t) -> c.ssize_t ---

	/*
	Remove an (empty) directory.

	]] More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/rmdir.html ]]
	*/
	rmdir :: proc(path: cstring) -> result ---

	/*
	Set the effective group ID.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setegid.html ]]
	*/
	setegid :: proc(gid: gid_t) -> result ---

	/*
	Sets the effective user ID.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/seteuid.html ]]
	*/
	seteuid :: proc(uid: uid_t) -> result ---

	/*
	Sets the group ID.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setgid.html ]]
	*/
	setgid :: proc(gid: gid_t) -> result ---

	/*
	Set process group ID.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setpgid.html ]]
	*/
	setpgid :: proc(pid: pid_t, pgid: pid_t) -> result ---

	/*
	Set the process group ID to that of the process.

	Returns: the process group id, no failures are defined

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setpgrp.html ]]
	*/
	setpgrp :: proc() -> pid_t ---

	/*
	Set the real and effective group IDs.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setregid.html ]]
	*/
	setregid :: proc(rgid: gid_t, egid: gid_t) -> result ---

	/*
	Set real and effective user IDs.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setreuid.html ]]
	*/
	setreuid :: proc(ruid: uid_t, euid: uid_t) -> result ---

	/*
	Create session and set process group ID.

	Returns: the new process group ID or -1 (setting errno) on failure

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setsid.html ]]
	*/
	setsid :: proc() -> pid_t ---

	/*
	Set user ID.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setuid.html ]]
	*/
	setuid :: proc(uid: uid_t) -> result ---

	/*
	Suspend execution for an interval of time.

	Returns: the time left to sleep (may be > 0 in case of signals)

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sleep.html ]]
	*/
	sleep :: proc(seconds: c.uint) -> c.uint ---

	/*
	Copy nbyte bytes, from src, to dest, exchanging adjecent bytes.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/swab.html ]]
	*/
	swab :: proc(src: [^]byte, dest: [^]byte, nbytes: c.ssize_t) ---

	/*
	Schedule file system updates.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/sync.html ]]
	*/
	sync :: proc() ---

	/*
	Get the foreground process group ID.

	Returns: -1 (setting errno) on failure, the id otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/tcgetpgrp.html ]]
	*/
	tcgetpgrp :: proc(fildes: FD) -> pid_t ---

	/*
	Set the foreground process group ID.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/tcsetpgrp.html ]]
	*/
	tcsetpgrp :: proc(fildes: FD, pgid_id: pid_t) -> result ---

	/*
	Find the path name of a terminal.

	Returns: nil (setting errno) on failure, the name, which may be invalidated by subsequent calls on success

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/ttyname.html ]]
	*/
	ttyname :: proc(fildes: FD) -> cstring ---

	/*
	Equivalent to ttyname but name is placed into the buf.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/ttyname.html ]]
	*/
	ttyname_r :: proc(fildes: FD, name: [^]byte, namesize: c.size_t) -> Errno ---

	/*
	Remove a directory entry.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/unlink.html ]]
	*/
	unlink :: proc(path: cstring) -> result ---

	/*
	Equivalent to unlink or rmdir (if flag is .REMOVEDIR) but relative paths are relative to the dir fd.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/unlink.html ]]
	*/
	unlinkat :: proc(fd: FD, path: cstring, flag: AT_Flags) -> result ---
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

CS :: enum c.int {
	_PATH                           = _CS_PATH,
	_POSIX_V6_ILP32_OFF32_CFLAGS    = _CS_POSIX_V6_ILP32_OFF32_CFLAGS,
	_POSIX_V6_ILP32_OFF32_LDFLAGS   = _CS_POSIX_V6_ILP32_OFF32_LDFLAGS,
	_POSIX_V6_ILP32_OFF32_LIBS      = _CS_POSIX_V6_ILP32_OFF32_LIBS,
	_POSIX_V6_ILP32_OFFBIG_CFLAGS   = _CS_POSIX_V6_ILP32_OFFBIG_CFLAGS,
	_POSIX_V6_ILP32_OFFBIG_LDFLAGS  = _CS_POSIX_V6_ILP32_OFFBIG_LDFLAGS,
	_POSIX_V6_ILP32_OFFBIG_LIBS     = _CS_POSIX_V6_ILP32_OFFBIG_LIBS,
	_POSIX_V6_LP64_OFF64_CFLAGS     = _CS_POSIX_V6_LP64_OFF64_CFLAGS,
	_POSIX_V6_LP64_OFF64_LDFLAGS    = _CS_POSIX_V6_LP64_OFF64_LDFLAGS,
	_POSIX_V6_LP64_OFF64_LIBS       = _CS_POSIX_V6_LP64_OFF64_LIBS,
	_POSIX_V6_LPBIG_OFFBIG_CFLAGS   = _CS_POSIX_V6_LPBIG_OFFBIG_CFLAGS,
	_POSIX_V6_LPBIG_OFFBIG_LDFLAGS  = _CS_POSIX_V6_LPBIG_OFFBIG_LDFLAGS,
	_POSIX_V6_LPBIG_OFFBIG_LIBS     = _CS_POSIX_V6_LPBIG_OFFBIG_LIBS,
	_POSIX_V6_WIDTH_RESTRICTED_ENVS	= _CS_POSIX_V6_WIDTH_RESTRICTED_ENVS,
}

PC :: enum c.int {
	_2_SYMLINK          = _PC_2_SYMLINK,
	_ALLOC_SIZE_MIN     = _PC_ALLOC_SIZE_MIN,
	_ASYNC_IO           = _PC_ASYNC_IO,
	_CHOWN_RESTRICTED   = _PC_CHOWN_RESTRICTED,
	_FILESIZEBITS       = _PC_FILESIZEBITS,
	_LINK_MAX           = _PC_LINK_MAX,
	_MAX_CANON          = _PC_MAX_CANON,
	_MAX_INPUT          = _PC_MAX_INPUT,
	_NAME_MAX           = _PC_NAME_MAX,
	_NO_TRUNC           = _PC_NO_TRUNC,
	_PATH_MAX           = _PC_PATH_MAX,
	_PIPE_BUF           = _PC_PIPE_BUF,
	_PRIO_IO            = _PC_PRIO_IO,
	_REC_INCR_XFER_SIZE = _PC_REC_INCR_XFER_SIZE,
	_REC_MAX_XFER_SIZE  = _PC_REC_MAX_XFER_SIZE,
	_REC_MIN_XFER_SIZE  = _PC_REC_MIN_XFER_SIZE,
	_REC_XFER_ALIGN     = _PC_REC_XFER_ALIGN,
	_SYMLINK_MAX        = _PC_SYMLINK_MAX,
	_SYNC_IO            = _PC_SYNC_IO,
	_VDISABLE           = _PC_VDISABLE,
}

SC :: enum c.int {
	_2_C_BIND                     = _SC_2_C_BIND,
	_2_C_DEV                      = _SC_2_C_DEV,
	_2_CHAR_TERM                  = _SC_2_CHAR_TERM,
	_2_FORT_DEV                   = _SC_2_FORT_DEV,
	_2_FORT_RUN                   = _SC_2_FORT_RUN,
	_2_LOCALEDEF                  = _SC_2_LOCALEDEF,
	_2_PBS                        = _SC_2_PBS,
	_2_PBS_ACCOUNTING             = _SC_2_PBS_ACCOUNTING,
	_2_PBS_CHECKPOINT             = _SC_2_PBS_CHECKPOINT,
	_2_PBS_LOCATE                 = _SC_2_PBS_LOCATE,
	_2_PBS_MESSAGE                = _SC_2_PBS_MESSAGE,
	_2_PBS_TRACK                  = _SC_2_PBS_TRACK,
	_2_SW_DEV                     = _SC_2_SW_DEV,
	_2_UPE                        = _SC_2_UPE,
	_2_VERSION                    = _SC_2_VERSION,
	_ADVISORY_INFO                = _SC_ADVISORY_INFO,
	_AIO_LISTIO_MAX               = _SC_AIO_LISTIO_MAX,
	_AIO_MAX                      = _SC_AIO_MAX,
	_AIO_PRIO_DELTA_MAX           = _SC_AIO_PRIO_DELTA_MAX,
	_ARG_MAX                      = _SC_ARG_MAX,
	_ASYNCHRONOUS_IO              = _SC_ASYNCHRONOUS_IO,
	_ATEXIT_MAX                   = _SC_ATEXIT_MAX,
	_BARRIERS                     = _SC_BARRIERS,
	_BC_BASE_MAX                  = _SC_BC_BASE_MAX,
	_BC_DIM_MAX                   = _SC_BC_DIM_MAX,
	_BC_SCALE_MAX                 = _SC_BC_SCALE_MAX,
	_BC_STRING_MAX                = _SC_BC_STRING_MAX,
	_CHILD_MAX                    = _SC_CHILD_MAX,
	_CLK_TCK                      = _SC_CLK_TCK,
	_CLOCK_SELECTION              = _SC_CLOCK_SELECTION,
	_COLL_WEIGHTS_MAX             = _SC_COLL_WEIGHTS_MAX,
	_CPUTIME                      = _SC_CPUTIME,
	_DELAYTIMER_MAX               = _SC_DELAYTIMER_MAX,
	_EXPR_NEST_MAX                = _SC_EXPR_NEST_MAX,
	_FSYNC                        = _SC_FSYNC,
	_GETGR_R_SIZE_MAX             = _SC_GETGR_R_SIZE_MAX,
	_GETPW_R_SIZE_MAX             = _SC_GETPW_R_SIZE_MAX,
	_HOST_NAME_MAX                = _SC_HOST_NAME_MAX,
	_IOV_MAX                      = _SC_IOV_MAX,
	_IPV6                         = _SC_IPV6,
	_JOB_CONTROL                  = _SC_JOB_CONTROL,
	_LINE_MAX                     = _SC_LINE_MAX,
	_LOGIN_NAME_MAX               = _SC_LOGIN_NAME_MAX,
	_MAPPED_FILES                 = _SC_MAPPED_FILES,
	_MEMLOCK                      = _SC_MEMLOCK,
	_MEMLOCK_RANGE                = _SC_MEMLOCK_RANGE,
	_MEMORY_PROTECTION            = _SC_MEMORY_PROTECTION,
	_MESSAGE_PASSING              = _SC_MESSAGE_PASSING,
	_MONOTONIC_CLOCK              = _SC_MONOTONIC_CLOCK,
	_MQ_OPEN_MAX                  = _SC_MQ_OPEN_MAX,
	_MQ_PRIO_MAX                  = _SC_MQ_PRIO_MAX,
	_NGROUPS_MAX                  = _SC_NGROUPS_MAX,
	_OPEN_MAX                     = _SC_OPEN_MAX,
	_PAGE_SIZE                    = _SC_PAGE_SIZE,
	_PAGESIZE                     = _SC_PAGESIZE,
	_PRIORITIZED_IO               = _SC_PRIORITIZED_IO,
	_PRIORITY_SCHEDULING          = _SC_PRIORITY_SCHEDULING,
	_RAW_SOCKETS                  = _SC_RAW_SOCKETS,
	_RE_DUP_MAX                   = _SC_RE_DUP_MAX,
	_READER_WRITER_LOCKS          = _SC_READER_WRITER_LOCKS,
	_REALTIME_SIGNALS             = _SC_REALTIME_SIGNALS,
	_REGEXP                       = _SC_REGEXP,
	_RTSIG_MAX                    = _SC_RTSIG_MAX,
	_SAVED_IDS                    = _SC_SAVED_IDS,
	_SEM_NSEMS_MAX                = _SC_SEM_NSEMS_MAX,
	_SEM_VALUE_MAX                = _SC_SEM_VALUE_MAX,
	_SEMAPHORES                   = _SC_SEMAPHORES,
	_SHARED_MEMORY_OBJECTS        = _SC_SHARED_MEMORY_OBJECTS,
	_SHELL                        = _SC_SHELL,
	_SIGQUEUE_MAX                 = _SC_SIGQUEUE_MAX,
	_SPAWN                        = _SC_SPAWN,
	_SPIN_LOCKS                   = _SC_SPIN_LOCKS,
	_SPORADIC_SERVER              = _SC_SPORADIC_SERVER,
	_SS_REPL_MAX                  = _SC_SS_REPL_MAX,
	_STREAM_MAX                   = _SC_STREAM_MAX,
	_SYMLOOP_MAX                  = _SC_SYMLOOP_MAX,
	_SYNCHRONIZED_IO              = _SC_SYNCHRONIZED_IO,
	_THREAD_ATTR_STACKADDR        = _SC_THREAD_ATTR_STACKADDR,
	_THREAD_ATTR_STACKSIZE        = _SC_THREAD_ATTR_STACKSIZE,
	_THREAD_CPUTIME               = _SC_THREAD_CPUTIME,
	_THREAD_DESTRUCTOR_ITERATIONS = _SC_THREAD_DESTRUCTOR_ITERATIONS,
	_THREAD_KEYS_MAX              = _SC_THREAD_KEYS_MAX,
	_THREAD_PRIO_INHERIT          = _SC_THREAD_PRIO_INHERIT,
	_THREAD_PRIO_PROTECT          = _SC_THREAD_PRIO_PROTECT,
	_THREAD_PRIORITY_SCHEDULING   = _SC_THREAD_PRIORITY_SCHEDULING,
	_THREAD_PROCESS_SHARED        = _SC_THREAD_PROCESS_SHARED,
	_THREAD_SAFE_FUNCTIONS        = _SC_THREAD_SAFE_FUNCTIONS,
	_THREAD_SPORADIC_SERVER       = _SC_THREAD_SPORADIC_SERVER,
	_THREAD_STACK_MIN             = _SC_THREAD_STACK_MIN,
	_THREAD_THREADS_MAX           = _SC_THREAD_THREADS_MAX,
	_THREADS                      = _SC_THREADS,
	_TIMEOUTS                     = _SC_TIMEOUTS,
	_TIMER_MAX                    = _SC_TIMER_MAX,
	_TIMERS                       = _SC_TIMERS,
	_TRACE                        = _SC_TRACE,
	_TRACE_EVENT_FILTER           = _SC_TRACE_EVENT_FILTER,
	_TRACE_EVENT_NAME_MAX         = _SC_TRACE_EVENT_NAME_MAX,
	_TRACE_INHERIT                = _SC_TRACE_INHERIT,
	_TRACE_LOG                    = _SC_TRACE_LOG,
	_TRACE_NAME_MAX               = _SC_TRACE_NAME_MAX,
	_TRACE_SYS_MAX                = _SC_TRACE_SYS_MAX,
	_TRACE_USER_EVENT_MAX         = _SC_TRACE_USER_EVENT_MAX,
	_TTY_NAME_MAX                 = _SC_TTY_NAME_MAX,
	_TYPED_MEMORY_OBJECTS         = _SC_TYPED_MEMORY_OBJECTS,
	_TZNAME_MAX                   = _SC_TZNAME_MAX,
	_V6_ILP32_OFF32               = _SC_V6_ILP32_OFF32,
	_V6_ILP32_OFFBIG              = _SC_V6_ILP32_OFFBIG,
	_V6_LP64_OFF64                = _SC_V6_LP64_OFF64,
	_V6_LPBIG_OFFBIG              = _SC_V6_LPBIG_OFFBIG,
	_VERSION                      = _SC_VERSION,
	_XOPEN_CRYPT                  = _SC_XOPEN_CRYPT,
	_XOPEN_ENH_I18N               = _SC_XOPEN_ENH_I18N,
	_XOPEN_REALTIME               = _SC_XOPEN_REALTIME,
	_XOPEN_REALTIME_THREADS       = _SC_XOPEN_REALTIME_THREADS,
	_XOPEN_SHM                    = _SC_XOPEN_SHM,
	_XOPEN_STREAMS                = _SC_XOPEN_STREAMS,
	_XOPEN_UNIX                   = _SC_XOPEN_UNIX,
	_XOPEN_VERSION                = _SC_XOPEN_VERSION,
}

Lock_Function :: enum c.int {
	// Lock a section for exclusive use.
	LOCK  = F_LOCK,
	// Test a section for locks by other processes.
	TEST  = F_TEST,
	// Test and lock a section for exclusive use.
	TLOCK = F_TLOCK,
	// Unlock locked sections.
	ULOCK = F_ULOCK,
}

when ODIN_OS == .NetBSD {
	@(private) LCHOWN  :: "__posix_chown"
	@(private) LFCHOWN :: "__posix_fchown"
	@(private) LLCHOWN :: "__posix_lchown"
} else {
	@(private) LCHOWN  :: "chown"
	@(private) LFCHOWN :: "fchown"
	@(private) LLCHOWN :: "lchown"
}

when ODIN_OS == .Darwin {

	_F_OK :: 0
	X_OK :: (1<<0)
	W_OK :: (1<<1)
	R_OK :: (1<<2)

	F_LOCK  :: 1
	F_TEST  :: 3
	F_TLOCK :: 2
	F_ULOCK :: 0

	_CS_PATH                            :: 1
	_CS_POSIX_V6_ILP32_OFF32_CFLAGS		:: 2
	_CS_POSIX_V6_ILP32_OFF32_LDFLAGS	:: 3
	_CS_POSIX_V6_ILP32_OFF32_LIBS		:: 4
	_CS_POSIX_V6_ILP32_OFFBIG_CFLAGS	:: 5
	_CS_POSIX_V6_ILP32_OFFBIG_LDFLAGS	:: 6
	_CS_POSIX_V6_ILP32_OFFBIG_LIBS		:: 7
	_CS_POSIX_V6_LP64_OFF64_CFLAGS		:: 8
	_CS_POSIX_V6_LP64_OFF64_LDFLAGS		:: 9
	_CS_POSIX_V6_LP64_OFF64_LIBS		:: 10
	_CS_POSIX_V6_LPBIG_OFFBIG_CFLAGS	:: 11
	_CS_POSIX_V6_LPBIG_OFFBIG_LDFLAGS	:: 12
	_CS_POSIX_V6_LPBIG_OFFBIG_LIBS		:: 13
	_CS_POSIX_V6_WIDTH_RESTRICTED_ENVS	:: 14

	_PC_LINK_MAX           :: 1
	_PC_MAX_CANON          :: 2
	_PC_MAX_INPUT          :: 3
	_PC_NAME_MAX           :: 4
	_PC_PATH_MAX           :: 5
	_PC_PIPE_BUF           :: 6
	_PC_CHOWN_RESTRICTED   :: 7
	_PC_NO_TRUNC           :: 8
	_PC_VDISABLE           :: 9
	_PC_2_SYMLINK          :: 15
	_PC_ALLOC_SIZE_MIN     :: 16
	_PC_ASYNC_IO           :: 17
	_PC_FILESIZEBITS       :: 18
	_PC_PRIO_IO            :: 19
	_PC_REC_INCR_XFER_SIZE :: 20
	_PC_REC_MAX_XFER_SIZE  :: 21
	_PC_REC_MIN_XFER_SIZE  :: 22
	_PC_REC_XFER_ALIGN     :: 23
	_PC_SYMLINK_MAX        :: 24
	_PC_SYNC_IO            :: 25

	_SC_ARG_MAX                      :: 1
	_SC_CHILD_MAX                    :: 2
	_SC_CLK_TCK                      :: 3
	_SC_NGROUPS_MAX                  :: 4
	_SC_OPEN_MAX                     :: 5
	_SC_JOB_CONTROL                  :: 6
	_SC_SAVED_IDS                    :: 7
	_SC_VERSION                      :: 8
	_SC_BC_BASE_MAX                  :: 9

	_SC_BC_DIM_MAX                   :: 10
	_SC_BC_SCALE_MAX                 :: 11
	_SC_BC_STRING_MAX                :: 12
	_SC_COLL_WEIGHTS_MAX             :: 13
	_SC_EXPR_NEST_MAX                :: 14
	_SC_LINE_MAX                     :: 15
	_SC_RE_DUP_MAX                   :: 16
	_SC_2_VERSION                    :: 17
	_SC_2_C_BIND                     :: 18
	_SC_2_C_DEV                      :: 19

	_SC_2_CHAR_TERM                  :: 20
	_SC_2_FORT_DEV                   :: 21
	_SC_2_FORT_RUN                   :: 22
	_SC_2_LOCALEDEF                  :: 23
	_SC_2_SW_DEV                     :: 24
	_SC_2_UPE                        :: 25
	_SC_STREAM_MAX                   :: 26
	_SC_TZNAME_MAX                   :: 27
	_SC_ASYNCHRONOUS_IO              :: 28
	_SC_PAGE_SIZE                    :: 29
	_SC_PAGESIZE                     :: _SC_PAGE_SIZE

	_SC_MEMLOCK                      :: 30
	_SC_MEMLOCK_RANGE                :: 31
	_SC_MEMORY_PROTECTION            :: 32
	_SC_MESSAGE_PASSING              :: 33
	_SC_PRIORITIZED_IO               :: 34
	_SC_PRIORITY_SCHEDULING          :: 35
	_SC_REALTIME_SIGNALS             :: 36
	_SC_SEMAPHORES                   :: 37
	_SC_FSYNC                        :: 38
	_SC_SHARED_MEMORY_OBJECTS        :: 39

	_SC_SYNCHRONIZED_IO              :: 40
	_SC_TIMERS                       :: 41
	_SC_AIO_LISTIO_MAX               :: 42
	_SC_AIO_MAX                      :: 43
	_SC_AIO_PRIO_DELTA_MAX           :: 44
	_SC_DELAYTIMER_MAX               :: 45
	_SC_MQ_OPEN_MAX                  :: 46
	_SC_MAPPED_FILES                 :: 47
	_SC_RTSIG_MAX                    :: 48
	_SC_SEM_NSEMS_MAX                :: 49

	_SC_SEM_VALUE_MAX                :: 50
	_SC_SIGQUEUE_MAX                 :: 51
	_SC_TIMER_MAX                    :: 52
	_SC_IOV_MAX                      :: 56
	_SC_2_PBS                        :: 59

	_SC_2_PBS_ACCOUNTING             :: 60
	_SC_2_PBS_CHECKPOINT             :: 61
	_SC_2_PBS_LOCATE                 :: 62
	_SC_2_PBS_MESSAGE                :: 63
	_SC_2_PBS_TRACK                  :: 64
	_SC_ADVISORY_INFO                :: 65
	_SC_BARRIERS                     :: 66
	_SC_CLOCK_SELECTION              :: 67
	_SC_CPUTIME                      :: 68

	_SC_GETGR_R_SIZE_MAX             :: 70
	_SC_GETPW_R_SIZE_MAX             :: 71
	_SC_HOST_NAME_MAX                :: 72
	_SC_LOGIN_NAME_MAX               :: 73
	_SC_MONOTONIC_CLOCK              :: 74
	_SC_MQ_PRIO_MAX                  :: 75
	_SC_READER_WRITER_LOCKS          :: 76
	_SC_REGEXP                       :: 77
	_SC_SHELL                        :: 78
	_SC_SPAWN                        :: 79

	_SC_SPIN_LOCKS                   :: 80
	_SC_SPORADIC_SERVER              :: 81
	_SC_THREAD_ATTR_STACKADDR        :: 82
	_SC_THREAD_ATTR_STACKSIZE        :: 83
	_SC_THREAD_CPUTIME               :: 84
	_SC_THREAD_DESTRUCTOR_ITERATIONS :: 85
	_SC_THREAD_KEYS_MAX              :: 86
	_SC_THREAD_PRIO_INHERIT          :: 87
	_SC_THREAD_PRIO_PROTECT          :: 88
	_SC_THREAD_PRIORITY_SCHEDULING   :: 89

	_SC_THREAD_PROCESS_SHARED        :: 90
	_SC_THREAD_SAFE_FUNCTIONS        :: 91
	_SC_THREAD_SPORADIC_SERVER       :: 92
	_SC_THREAD_STACK_MIN             :: 93
	_SC_THREAD_THREADS_MAX           :: 94
	_SC_TIMEOUTS                     :: 95
	_SC_THREADS                      :: 96
	_SC_TRACE                        :: 97
	_SC_TRACE_EVENT_FILTER           :: 98
	_SC_TRACE_INHERIT                :: 99

	_SC_TRACE_LOG                    :: 100
	_SC_TTY_NAME_MAX                 :: 101
	_SC_TYPED_MEMORY_OBJECTS         :: 102
	_SC_V6_ILP32_OFF32               :: 103
	_SC_V6_ILP32_OFFBIG              :: 104
	_SC_V6_LP64_OFF64                :: 105
	_SC_V6_LPBIG_OFFBIG              :: 106
	_SC_ATEXIT_MAX                   :: 107
	_SC_XOPEN_CRYPT                  :: 108
	_SC_XOPEN_ENH_I18N               :: 109

	_SC_XOPEN_REALTIME               :: 111
	_SC_XOPEN_REALTIME_THREADS       :: 112
	_SC_XOPEN_SHM                    :: 113
	_SC_XOPEN_STREAMS                :: 114
	_SC_XOPEN_UNIX                   :: 115
	_SC_XOPEN_VERSION                :: 116
	_SC_IPV6                         :: 118
	_SC_RAW_SOCKETS                  :: 119

	_SC_SYMLOOP_MAX                  :: 120
	_SC_SS_REPL_MAX                  :: 126
	_SC_TRACE_EVENT_NAME_MAX         :: 127
	_SC_TRACE_NAME_MAX               :: 128
	_SC_TRACE_SYS_MAX                :: 129
	_SC_TRACE_USER_EVENT_MAX         :: 130

	_POSIX_VDISABLE :: '\377'

} else when ODIN_OS == .FreeBSD {

	_F_OK :: 0
	X_OK :: 0x01
	W_OK :: 0x02
	R_OK :: 0x04

	F_LOCK  :: 1
	F_TEST  :: 3
	F_TLOCK :: 2
	F_ULOCK :: 0

	_CS_PATH                            :: 1
	_CS_POSIX_V6_ILP32_OFF32_CFLAGS		:: 2
	_CS_POSIX_V6_ILP32_OFF32_LDFLAGS	:: 3
	_CS_POSIX_V6_ILP32_OFF32_LIBS		:: 4
	_CS_POSIX_V6_ILP32_OFFBIG_CFLAGS	:: 5
	_CS_POSIX_V6_ILP32_OFFBIG_LDFLAGS	:: 6
	_CS_POSIX_V6_ILP32_OFFBIG_LIBS		:: 7
	_CS_POSIX_V6_LP64_OFF64_CFLAGS		:: 8
	_CS_POSIX_V6_LP64_OFF64_LDFLAGS		:: 9
	_CS_POSIX_V6_LP64_OFF64_LIBS		:: 10
	_CS_POSIX_V6_LPBIG_OFFBIG_CFLAGS	:: 11
	_CS_POSIX_V6_LPBIG_OFFBIG_LDFLAGS	:: 12
	_CS_POSIX_V6_LPBIG_OFFBIG_LIBS		:: 13
	_CS_POSIX_V6_WIDTH_RESTRICTED_ENVS	:: 14

	_PC_LINK_MAX           :: 1
	_PC_MAX_CANON          :: 2
	_PC_MAX_INPUT          :: 3
	_PC_NAME_MAX           :: 4
	_PC_PATH_MAX           :: 5
	_PC_PIPE_BUF           :: 6
	_PC_CHOWN_RESTRICTED   :: 7
	_PC_NO_TRUNC           :: 8
	_PC_VDISABLE           :: 9
	_PC_2_SYMLINK          :: 13 // NOTE: not in headers (freebsd)
	_PC_ALLOC_SIZE_MIN     :: 10
	_PC_ASYNC_IO           :: 53
	_PC_FILESIZEBITS       :: 12
	_PC_PRIO_IO            :: 54
	_PC_REC_INCR_XFER_SIZE :: 14
	_PC_REC_MAX_XFER_SIZE  :: 15
	_PC_REC_MIN_XFER_SIZE  :: 16
	_PC_REC_XFER_ALIGN     :: 17
	_PC_SYMLINK_MAX        :: 18
	_PC_SYNC_IO            :: 55

	_SC_ARG_MAX                      :: 1
	_SC_CHILD_MAX                    :: 2
	_SC_CLK_TCK                      :: 3
	_SC_NGROUPS_MAX                  :: 4
	_SC_OPEN_MAX                     :: 5
	_SC_JOB_CONTROL                  :: 6
	_SC_SAVED_IDS                    :: 7
	_SC_VERSION                      :: 8
	_SC_BC_BASE_MAX                  :: 9

	_SC_BC_DIM_MAX                   :: 10
	_SC_BC_SCALE_MAX                 :: 11
	_SC_BC_STRING_MAX                :: 12
	_SC_COLL_WEIGHTS_MAX             :: 13
	_SC_EXPR_NEST_MAX                :: 14
	_SC_LINE_MAX                     :: 15
	_SC_RE_DUP_MAX                   :: 16
	_SC_2_VERSION                    :: 17
	_SC_2_C_BIND                     :: 18
	_SC_2_C_DEV                      :: 19

	_SC_2_CHAR_TERM                  :: 20
	_SC_2_FORT_DEV                   :: 21
	_SC_2_FORT_RUN                   :: 22
	_SC_2_LOCALEDEF                  :: 23
	_SC_2_SW_DEV                     :: 24
	_SC_2_UPE                        :: 25
	_SC_STREAM_MAX                   :: 26
	_SC_TZNAME_MAX                   :: 27
	_SC_ASYNCHRONOUS_IO              :: 28
	_SC_MAPPED_FILES                 :: 29

	_SC_MEMLOCK                      :: 30
	_SC_MEMLOCK_RANGE                :: 31
	_SC_MEMORY_PROTECTION            :: 32
	_SC_MESSAGE_PASSING              :: 33
	_SC_PRIORITIZED_IO               :: 34
	_SC_PRIORITY_SCHEDULING          :: 35
	_SC_REALTIME_SIGNALS             :: 36
	_SC_SEMAPHORES                   :: 37
	_SC_FSYNC                        :: 38
	_SC_SHARED_MEMORY_OBJECTS        :: 39

	_SC_SYNCHRONIZED_IO              :: 40
	_SC_TIMERS                       :: 41
	_SC_AIO_LISTIO_MAX               :: 42
	_SC_AIO_MAX                      :: 43
	_SC_AIO_PRIO_DELTA_MAX           :: 44
	_SC_DELAYTIMER_MAX               :: 45
	_SC_MQ_OPEN_MAX                  :: 46
	_SC_PAGE_SIZE                    :: 47
	_SC_PAGESIZE                     :: _SC_PAGE_SIZE
	_SC_RTSIG_MAX                    :: 48
	_SC_SEM_NSEMS_MAX                :: 49

	_SC_SEM_VALUE_MAX                :: 50
	_SC_SIGQUEUE_MAX                 :: 51
	_SC_TIMER_MAX                    :: 52
	_SC_IOV_MAX                      :: 56
	_SC_2_PBS                        :: 59

	_SC_2_PBS_ACCOUNTING             :: 60
	_SC_2_PBS_CHECKPOINT             :: 61
	_SC_2_PBS_LOCATE                 :: 62
	_SC_2_PBS_MESSAGE                :: 63
	_SC_2_PBS_TRACK                  :: 64
	_SC_ADVISORY_INFO                :: 65
	_SC_BARRIERS                     :: 66
	_SC_CLOCK_SELECTION              :: 67
	_SC_CPUTIME                      :: 68

	_SC_GETGR_R_SIZE_MAX             :: 70
	_SC_GETPW_R_SIZE_MAX             :: 71
	_SC_HOST_NAME_MAX                :: 72
	_SC_LOGIN_NAME_MAX               :: 73
	_SC_MONOTONIC_CLOCK              :: 74
	_SC_MQ_PRIO_MAX                  :: 75
	_SC_READER_WRITER_LOCKS          :: 76
	_SC_REGEXP                       :: 77
	_SC_SHELL                        :: 78
	_SC_SPAWN                        :: 79

	_SC_SPIN_LOCKS                   :: 80
	_SC_SPORADIC_SERVER              :: 81
	_SC_THREAD_ATTR_STACKADDR        :: 82
	_SC_THREAD_ATTR_STACKSIZE        :: 83
	_SC_THREAD_CPUTIME               :: 84
	_SC_THREAD_DESTRUCTOR_ITERATIONS :: 85
	_SC_THREAD_KEYS_MAX              :: 86
	_SC_THREAD_PRIO_INHERIT          :: 87
	_SC_THREAD_PRIO_PROTECT          :: 88
	_SC_THREAD_PRIORITY_SCHEDULING   :: 89

	_SC_THREAD_PROCESS_SHARED        :: 90
	_SC_THREAD_SAFE_FUNCTIONS        :: 91
	_SC_THREAD_SPORADIC_SERVER       :: 92
	_SC_THREAD_STACK_MIN             :: 93
	_SC_THREAD_THREADS_MAX           :: 94
	_SC_TIMEOUTS                     :: 95
	_SC_THREADS                      :: 96
	_SC_TRACE                        :: 97
	_SC_TRACE_EVENT_FILTER           :: 98
	_SC_TRACE_INHERIT                :: 99

	_SC_TRACE_LOG                    :: 100
	_SC_TTY_NAME_MAX                 :: 101
	_SC_TYPED_MEMORY_OBJECTS         :: 102
	_SC_V6_ILP32_OFF32               :: 103
	_SC_V6_ILP32_OFFBIG              :: 104
	_SC_V6_LP64_OFF64                :: 105
	_SC_V6_LPBIG_OFFBIG              :: 106
	_SC_ATEXIT_MAX                   :: 107
	_SC_XOPEN_CRYPT                  :: 108
	_SC_XOPEN_ENH_I18N               :: 109

	_SC_XOPEN_REALTIME               :: 111
	_SC_XOPEN_REALTIME_THREADS       :: 112
	_SC_XOPEN_SHM                    :: 113
	_SC_XOPEN_STREAMS                :: 114
	_SC_XOPEN_UNIX                   :: 115
	_SC_XOPEN_VERSION                :: 116
	_SC_IPV6                         :: 118
	_SC_RAW_SOCKETS                  :: 119

	_SC_SYMLOOP_MAX                  :: 120
	_SC_SS_REPL_MAX                  :: 126 // NOTE: not in headers
	_SC_TRACE_EVENT_NAME_MAX         :: 127 // NOTE: not in headers
	_SC_TRACE_NAME_MAX               :: 128 // NOTE: not in headers
	_SC_TRACE_SYS_MAX                :: 129 // NOTE: not in headers
	_SC_TRACE_USER_EVENT_MAX         :: 130 // NOTE: not in headers

	_POSIX_VDISABLE :: 0xff

} else when ODIN_OS == .NetBSD {

	_F_OK :: 0
	X_OK :: 0x01
	W_OK :: 0x02
	R_OK :: 0x04

	F_LOCK  :: 1
	F_TEST  :: 3
	F_TLOCK :: 2
	F_ULOCK :: 0

	_CS_PATH                            :: 1
	_CS_POSIX_V6_ILP32_OFF32_CFLAGS		:: 2
	_CS_POSIX_V6_ILP32_OFF32_LDFLAGS	:: 3
	_CS_POSIX_V6_ILP32_OFF32_LIBS		:: 4
	_CS_POSIX_V6_ILP32_OFFBIG_CFLAGS	:: 5
	_CS_POSIX_V6_ILP32_OFFBIG_LDFLAGS	:: 6
	_CS_POSIX_V6_ILP32_OFFBIG_LIBS		:: 7
	_CS_POSIX_V6_LP64_OFF64_CFLAGS		:: 8
	_CS_POSIX_V6_LP64_OFF64_LDFLAGS		:: 9
	_CS_POSIX_V6_LP64_OFF64_LIBS		:: 10
	_CS_POSIX_V6_LPBIG_OFFBIG_CFLAGS	:: 11
	_CS_POSIX_V6_LPBIG_OFFBIG_LDFLAGS	:: 12
	_CS_POSIX_V6_LPBIG_OFFBIG_LIBS		:: 13
	_CS_POSIX_V6_WIDTH_RESTRICTED_ENVS	:: 14

	_PC_LINK_MAX           :: 1
	_PC_MAX_CANON          :: 2
	_PC_MAX_INPUT          :: 3
	_PC_NAME_MAX           :: 4
	_PC_PATH_MAX           :: 5
	_PC_PIPE_BUF           :: 6
	_PC_CHOWN_RESTRICTED   :: 7
	_PC_NO_TRUNC           :: 8
	_PC_VDISABLE           :: 9
	_PC_2_SYMLINK          :: 13 // NOTE: not in headers
	_PC_ALLOC_SIZE_MIN     :: 10 // NOTE: not in headers
	_PC_ASYNC_IO           :: 53 // NOTE: not in headers
	_PC_FILESIZEBITS       :: 11
	_PC_PRIO_IO            :: 54 // NOTE: not in headers
	_PC_REC_INCR_XFER_SIZE :: 14 // NOTE: not in headers
	_PC_REC_MAX_XFER_SIZE  :: 15 // NOTE: not in headers
	_PC_REC_MIN_XFER_SIZE  :: 16 // NOTE: not in headers
	_PC_REC_XFER_ALIGN     :: 17 // NOTE: not in headers
	_PC_SYMLINK_MAX        :: 12
	_PC_SYNC_IO            :: 10

	_SC_ARG_MAX                      :: 1
	_SC_CHILD_MAX                    :: 2
	_SC_NGROUPS_MAX                  :: 4
	_SC_OPEN_MAX                     :: 5
	_SC_JOB_CONTROL                  :: 6
	_SC_SAVED_IDS                    :: 7
	_SC_VERSION                      :: 8
	_SC_BC_BASE_MAX                  :: 9

	_SC_BC_DIM_MAX                   :: 10
	_SC_BC_SCALE_MAX                 :: 11
	_SC_BC_STRING_MAX                :: 12
	_SC_COLL_WEIGHTS_MAX             :: 13
	_SC_EXPR_NEST_MAX                :: 14
	_SC_LINE_MAX                     :: 15
	_SC_RE_DUP_MAX                   :: 16
	_SC_2_VERSION                    :: 17
	_SC_2_C_BIND                     :: 18
	_SC_2_C_DEV                      :: 19

	_SC_2_CHAR_TERM                  :: 20
	_SC_2_FORT_DEV                   :: 21
	_SC_2_FORT_RUN                   :: 22
	_SC_2_LOCALEDEF                  :: 23
	_SC_2_SW_DEV                     :: 24
	_SC_2_UPE                        :: 25
	_SC_STREAM_MAX                   :: 26
	_SC_TZNAME_MAX                   :: 27
	_SC_PAGE_SIZE                    :: 28
	_SC_PAGESIZE                     :: _SC_PAGE_SIZE
	_SC_FSYNC                        :: 29

	_SC_XOPEN_SHM                    :: 30
	_SC_SYNCHRONIZED_IO              :: 31
	_SC_IOV_MAX                      :: 32
	_SC_MAPPED_FILES                 :: 33
	_SC_MEMLOCK                      :: 34
	_SC_MEMLOCK_RANGE                :: 35
	_SC_MEMORY_PROTECTION            :: 36
	_SC_LOGIN_NAME_MAX               :: 37
	_SC_MONOTONIC_CLOCK              :: 38
	_SC_CLK_TCK                      :: 39

	_SC_ATEXIT_MAX                   :: 40
	_SC_THREADS                      :: 41
	_SC_SEMAPHORES                   :: 42
	_SC_BARRIERS                     :: 43
	_SC_TIMERS                       :: 44
	_SC_SPIN_LOCKS                   :: 45
	_SC_READER_WRITER_LOCKS          :: 46
	_SC_GETGR_R_SIZE_MAX             :: 47
	_SC_GETPW_R_SIZE_MAX             :: 48
	_SC_CLOCK_SELECTION              :: 49

	_SC_ASYNCHRONOUS_IO              :: 50
	_SC_AIO_LISTIO_MAX               :: 51
	_SC_AIO_MAX                      :: 52
	_SC_MESSAGE_PASSING              :: 53
	_SC_MQ_OPEN_MAX                  :: 54
	_SC_MQ_PRIO_MAX                  :: 55
	_SC_PRIORITY_SCHEDULING          :: 56
	_SC_THREAD_DESTRUCTOR_ITERATIONS :: 57
	_SC_THREAD_KEYS_MAX              :: 58
	_SC_THREAD_STACK_MIN             :: 59

	_SC_THREAD_THREADS_MAX           :: 60
	_SC_THREAD_ATTR_STACKADDR        :: 61
	_SC_THREAD_ATTR_STACKSIZE        :: 62
	_SC_THREAD_PRIORITY_SCHEDULING   :: 63
	_SC_THREAD_PRIO_INHERIT          :: 64
	_SC_THREAD_PRIO_PROTECT          :: 65
	_SC_THREAD_PROCESS_SHARED        :: 66
	_SC_THREAD_SAFE_FUNCTIONS        :: 67
	_SC_TTY_NAME_MAX                 :: 68
	_SC_HOST_NAME_MAX                :: 69

	_SC_PASS_MAX                     :: 70
	_SC_REGEXP                       :: 71
	_SC_SHELL                        :: 72
	_SC_SYMLOOP_MAX                  :: 73
	_SC_V6_ILP32_OFF32               :: 74
	_SC_V6_ILP32_OFFBIG              :: 75
	_SC_V6_LP64_OFF64                :: 76
	_SC_V6_LPBIG_OFFBIG              :: 77

	_SC_2_PBS                        :: 80
	_SC_2_PBS_ACCOUNTING             :: 81
	_SC_2_PBS_CHECKPOINT             :: 82
	_SC_2_PBS_LOCATE                 :: 83
	_SC_2_PBS_MESSAGE                :: 84
	_SC_2_PBS_TRACK                  :: 85
	_SC_SPAWN                        :: 86
	_SC_SHARED_MEMORY_OBJECTS        :: 87
	_SC_TIMER_MAX                    :: 88
	_SC_SEM_NSEMS_MAX                :: 89

	_SC_CPUTIME                      :: 90
	_SC_THREAD_CPUTIME               :: 91
	_SC_DELAYTIMER_MAX               :: 92
	_SC_SIGQUEUE_MAX                 :: 93
	_SC_REALTIME_SIGNALS             :: 94
	_SC_RTSIG_MAX                    :: 95

	_POSIX_VDISABLE :: '\377'

	// NOTE: following are not defined in netbsd headers.

	_SC_SPORADIC_SERVER              :: 81
	_SC_SEM_VALUE_MAX                :: 50

	_SC_TRACE                        :: 97
	_SC_TRACE_EVENT_FILTER           :: 98
	_SC_TRACE_INHERIT                :: 99
	_SC_TRACE_LOG                    :: 100
	_SC_TYPED_MEMORY_OBJECTS         :: 102

	_SC_THREAD_SPORADIC_SERVER       :: 92
	_SC_TIMEOUTS                     :: 95

	_SC_XOPEN_CRYPT                  :: 108
	_SC_XOPEN_ENH_I18N               :: 109
	_SC_XOPEN_REALTIME               :: 111
	_SC_XOPEN_REALTIME_THREADS       :: 112
	_SC_XOPEN_STREAMS                :: 114
	_SC_XOPEN_UNIX                   :: 115
	_SC_XOPEN_VERSION                :: 116
	_SC_IPV6                         :: 118
	_SC_RAW_SOCKETS                  :: 119

	_SC_PRIORITIZED_IO               :: 34
	_SC_AIO_PRIO_DELTA_MAX           :: 44
	_SC_ADVISORY_INFO                :: 65
	_SC_SS_REPL_MAX                  :: 126
	_SC_TRACE_EVENT_NAME_MAX         :: 127
	_SC_TRACE_NAME_MAX               :: 128
	_SC_TRACE_SYS_MAX                :: 129
	_SC_TRACE_USER_EVENT_MAX         :: 130

} else when ODIN_OS == .OpenBSD {

	_F_OK :: 0
	X_OK :: 0x01
	W_OK :: 0x02
	R_OK :: 0x04

	F_LOCK  :: 1
	F_TEST  :: 3
	F_TLOCK :: 2
	F_ULOCK :: 0

	_CS_PATH                            :: 1
	_CS_POSIX_V6_ILP32_OFF32_CFLAGS		:: 2
	_CS_POSIX_V6_ILP32_OFF32_LDFLAGS	:: 3
	_CS_POSIX_V6_ILP32_OFF32_LIBS		:: 4
	_CS_POSIX_V6_ILP32_OFFBIG_CFLAGS	:: 5
	_CS_POSIX_V6_ILP32_OFFBIG_LDFLAGS	:: 6
	_CS_POSIX_V6_ILP32_OFFBIG_LIBS		:: 7
	_CS_POSIX_V6_LP64_OFF64_CFLAGS		:: 8
	_CS_POSIX_V6_LP64_OFF64_LDFLAGS		:: 9
	_CS_POSIX_V6_LP64_OFF64_LIBS		:: 10
	_CS_POSIX_V6_LPBIG_OFFBIG_CFLAGS	:: 11
	_CS_POSIX_V6_LPBIG_OFFBIG_LDFLAGS	:: 12
	_CS_POSIX_V6_LPBIG_OFFBIG_LIBS		:: 13
	_CS_POSIX_V6_WIDTH_RESTRICTED_ENVS	:: 14

	_PC_LINK_MAX           :: 1
	_PC_MAX_CANON          :: 2
	_PC_MAX_INPUT          :: 3
	_PC_NAME_MAX           :: 4
	_PC_PATH_MAX           :: 5
	_PC_PIPE_BUF           :: 6
	_PC_CHOWN_RESTRICTED   :: 7
	_PC_NO_TRUNC           :: 8
	_PC_VDISABLE           :: 9
	_PC_2_SYMLINK          :: 10
	_PC_ALLOC_SIZE_MIN     :: 11
	_PC_ASYNC_IO           :: 12
	_PC_FILESIZEBITS       :: 13
	_PC_PRIO_IO            :: 14
	_PC_REC_INCR_XFER_SIZE :: 15
	_PC_REC_MAX_XFER_SIZE  :: 16
	_PC_REC_MIN_XFER_SIZE  :: 17
	_PC_REC_XFER_ALIGN     :: 18
	_PC_SYMLINK_MAX        :: 19
	_PC_SYNC_IO            :: 20

	_SC_ARG_MAX                      :: 1
	_SC_CHILD_MAX                    :: 2
	_SC_CLK_TCK                      :: 3
	_SC_NGROUPS_MAX                  :: 4
	_SC_OPEN_MAX                     :: 5
	_SC_JOB_CONTROL                  :: 6
	_SC_SAVED_IDS                    :: 7
	_SC_VERSION                      :: 8
	_SC_BC_BASE_MAX                  :: 9

	_SC_BC_DIM_MAX                   :: 10
	_SC_BC_SCALE_MAX                 :: 11
	_SC_BC_STRING_MAX                :: 12
	_SC_COLL_WEIGHTS_MAX             :: 13
	_SC_EXPR_NEST_MAX                :: 14
	_SC_LINE_MAX                     :: 15
	_SC_RE_DUP_MAX                   :: 16
	_SC_2_VERSION                    :: 17
	_SC_2_C_BIND                     :: 18
	_SC_2_C_DEV                      :: 19

	_SC_2_CHAR_TERM                  :: 20
	_SC_2_FORT_DEV                   :: 21
	_SC_2_FORT_RUN                   :: 22
	_SC_2_LOCALEDEF                  :: 23
	_SC_2_SW_DEV                     :: 24
	_SC_2_UPE                        :: 25
	_SC_STREAM_MAX                   :: 26
	_SC_TZNAME_MAX                   :: 27
	_SC_PAGESIZE                     :: 28
	_SC_PAGE_SIZE                    :: _SC_PAGESIZE
	_SC_FSYNC                        :: 29

	_SC_XOPEN_SHM                    :: 30
	_SC_SEM_NSEMS_MAX                :: 31
	_SC_SEM_VALUE_MAX                :: 32
	_SC_HOST_NAME_MAX                :: 33
	_SC_MONOTONIC_CLOCK              :: 34
	_SC_2_PBS                        :: 35
	_SC_2_PBS_ACCOUNTING             :: 36
	_SC_2_PBS_CHECKPOINT             :: 37
	_SC_2_PBS_LOCATE                 :: 38
	_SC_2_PBS_MESSAGE                :: 39

	_SC_2_PBS_TRACK                  :: 40
	_SC_ADVISORY_INFO                :: 41
	_SC_AIO_LISTIO_MAX               :: 42
	_SC_AIO_MAX                      :: 43
	_SC_AIO_PRIO_DELTA_MAX           :: 44
	_SC_ASYNCHRONOUS_IO              :: 45
	_SC_ATEXIT_MAX                   :: 46
	_SC_BARRIERS                     :: 47
	_SC_CLOCK_SELECTION              :: 48
	_SC_CPUTIME                      :: 49

	_SC_DELAYTIMER_MAX               :: 50
	_SC_IOV_MAX                      :: 51
	_SC_IPV6                         :: 52
	_SC_MAPPED_FILES                 :: 53
	_SC_MEMLOCK                      :: 54
	_SC_MEMLOCK_RANGE                :: 55
	_SC_MEMORY_PROTECTION            :: 56
	_SC_MESSAGE_PASSING              :: 57
	_SC_MQ_OPEN_MAX                  :: 58
	_SC_MQ_PRIO_MAX                  :: 59

	_SC_PRIORITIZED_IO               :: 60
	_SC_PRIORITY_SCHEDULING          :: 61
	_SC_RAW_SOCKETS                  :: 62
	_SC_READER_WRITER_LOCKS          :: 63
	_SC_REALTIME_SIGNALS             :: 64
	_SC_REGEXP                       :: 65
	_SC_RTSIG_MAX                    :: 66
	_SC_SEMAPHORES                   :: 67
	_SC_SHARED_MEMORY_OBJECTS        :: 68
	_SC_SHELL                        :: 69

	_SC_SIGQUEUE_MAX                 :: 70
	_SC_SPAWN                        :: 71
	_SC_SPIN_LOCKS                   :: 72
	_SC_SPORADIC_SERVER              :: 73
	_SC_SS_REPL_MAX                  :: 74
	_SC_SYNCHRONIZED_IO              :: 75
	_SC_SYMLOOP_MAX                  :: 76
	_SC_THREAD_ATTR_STACKADDR        :: 77
	_SC_THREAD_ATTR_STACKSIZE        :: 78
	_SC_THREAD_CPUTIME               :: 79

	_SC_THREAD_DESTRUCTOR_ITERATIONS :: 80
	_SC_THREAD_KEYS_MAX              :: 81
	_SC_THREAD_PRIO_INHERIT          :: 82
	_SC_THREAD_PRIO_PROTECT          :: 83
	_SC_THREAD_PRIORITY_SCHEDULING   :: 84
	_SC_THREAD_PROCESS_SHARED        :: 85
	_SC_THREAD_ROBUST_PRIO_INHERIT   :: 86
	_SC_THREAD_ROBUST_PRIO_PROTECT   :: 87
	_SC_THREAD_SPORADIC_SERVER       :: 88
	_SC_THREAD_STACK_MIN             :: 89

	_SC_THREAD_THREADS_MAX           :: 90
	_SC_THREADS                      :: 91
	_SC_TIMEOUTS                     :: 92
	_SC_TIMER_MAX                    :: 93
	_SC_TIMERS                       :: 94
	_SC_TRACE                        :: 95
	_SC_TRACE_EVENT_FILTER           :: 96
	_SC_TRACE_EVENT_NAME_MAX         :: 97
	_SC_TRACE_INHERIT                :: 98
	_SC_TRACE_LOG                    :: 99

	_SC_GETGR_R_SIZE_MAX             :: 100
	_SC_GETPW_R_SIZE_MAX             :: 101
	_SC_LOGIN_NAME_MAX               :: 102
	_SC_THREAD_SAFE_FUNCTIONS        :: 103
	_SC_TRACE_NAME_MAX               :: 104
	_SC_TRACE_SYS_MAX                :: 105
	_SC_TRACE_USER_EVENT_MAX         :: 106
	_SC_TTY_NAME_MAX                 :: 107
	_SC_TYPED_MEMORY_OBJECTS         :: 108
	_SC_V6_ILP32_OFF32               :: 109

	_SC_V6_ILP32_OFFBIG              :: 110
	_SC_V6_LP64_OFF64                :: 111
	_SC_V6_LPBIG_OFFBIG              :: 112
	_SC_V7_ILP32_OFF32               :: 113
	_SC_V7_ILP32_OFFBIG              :: 114
	_SC_V7_LP64_OFF64                :: 115
	_SC_V7_LPBIG_OFFBIG              :: 116
	_SC_XOPEN_CRYPT                  :: 117
	_SC_XOPEN_ENH_I18N               :: 118
	_SC_XOPEN_LEGACY                 :: 119

	_SC_XOPEN_REALTIME               :: 120
	_SC_XOPEN_REALTIME_THREADS       :: 121
	_SC_XOPEN_STREAMS                :: 122
	_SC_XOPEN_UNIX                   :: 123
	_SC_XOPEN_UUCP                   :: 124
	_SC_XOPEN_VERSION                :: 125

	_SC_PHYS_PAGES                   :: 500
	_SC_AVPHYS_PAGES                 :: 501
	_SC_NPROCESSORS_CONF             :: 502
	_SC_NPROCESSORS_ONLN             :: 503

	_POSIX_VDISABLE :: '\377'

} else {
	#panic("posix is unimplemented for the current target")
}

