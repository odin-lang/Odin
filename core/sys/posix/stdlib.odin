#+build linux, darwin, netbsd, openbsd, freebsd, haiku
package posix

import "base:intrinsics"

import "core:c"

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

foreign lib {
	/*
	Takes a pointer to a radix-64 representation, in which the first digit is the least significant,
	and return the corresponding long value. 

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/a64l.html ]]
	*/
	a64l :: proc(s: cstring) -> c.long ---

	/*
	The l64a() function shall take a long argument and return a pointer to the corresponding
	radix-64 representation.

	Returns: a string that may be invalidated by subsequent calls

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/a64l.html ]]
	*/
	l64a :: proc(value: c.long) -> cstring ---

	/*
	This family of functions shall generate pseudo-random numbers using a linear congruential algorithm and 48-bit integer arithmetic.

	Returns: non-negative, double-precision, floating-point values, uniformly distributed over the interval [0.0,1.0)

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/drand48.html ]]
	*/
	drand48 :: proc() -> c.double ---

	/*
	This family of functions shall generate pseudo-random numbers using a linear congruential algorithm and 48-bit integer arithmetic.

	Returns: non-negative, double-precision, floating-point values, uniformly distributed over the interval [0.0,1.0)

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/drand48.html ]]
	*/
	erand48 :: proc(xsubi: ^[3]c.ushort) -> c.double ---

	/*
	This family of functions shall generate pseudo-random numbers using a linear congruential algorithm and 48-bit integer arithmetic.

	Returns: return signed long integers uniformly distributed over the interval [-231,231)

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/drand48.html ]]
	*/
	mrand48 :: proc() -> c.long ---

	/*
	This family of functions shall generate pseudo-random numbers using a linear congruential algorithm and 48-bit integer arithmetic.

	Returns: return signed long integers uniformly distributed over the interval [-231,231)

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/drand48.html ]]
	*/
	jrand48 :: proc(xsubi: ^[3]c.ushort) -> c.long ---

	/*
	This family of functions shall generate pseudo-random numbers using a linear congruential algorithm and 48-bit integer arithmetic.

	Returns: non-negative, long integers, uniformly distributed over the interval [0,231)

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/drand48.html ]]
	*/
	lrand48 :: proc() -> c.long ---

	/*
	This family of functions shall generate pseudo-random numbers using a linear congruential algorithm and 48-bit integer arithmetic.

	Returns: non-negative, long integers, uniformly distributed over the interval [0,231)

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/drand48.html ]]
	*/
	nrand48 :: proc(xsubi: ^[3]c.ushort) -> c.long ---

	/*
	This family of functions shall generate pseudo-random numbers using a linear congruential algorithm and 48-bit integer arithmetic.

	The srand48(), seed48(), and lcong48() functions are initialization entry points, one of which should be invoked before either drand48(), lrand48(), or mrand48() is called.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/drand48.html ]]
	*/
	srand48 :: proc(seedval: c.long) ---

	/*
	This family of functions shall generate pseudo-random numbers using a linear congruential algorithm and 48-bit integer arithmetic.

	The srand48(), seed48(), and lcong48() functions are initialization entry points, one of which should be invoked before either drand48(), lrand48(), or mrand48() is called.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/drand48.html ]]
	*/
	lcong48 :: proc(param: ^[7]c.ushort) ---

	/*
	This family of functions shall generate pseudo-random numbers using a linear congruential algorithm and 48-bit integer arithmetic.

	The srand48(), seed48(), and lcong48() functions are initialization entry points, one of which should be invoked before either drand48(), lrand48(), or mrand48() is called.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/drand48.html ]]
	*/
	seed48 :: proc(seed16v: ^[3]c.ushort) -> ^[3]c.ushort ---

	/*
	Parses suboption arguments in a flag argument.

	Returns: the index of the matched token string, or -1 if no token strings were matched

	Example:
		args := runtime.args__

		Opt :: enum {
			RO,
			RW,
			NAME,
			NIL,
		}
		token := [Opt]cstring{
			.RO   = "ro",
			.RW   = "rw",
			.NAME = "name",
			.NIL  = nil,
		}

		Options :: struct {
			readonly, readwrite: bool,
			name: cstring,

		}
		opts: Options

		errfnd: bool
		for {
			opt := posix.getopt(i32(len(args)), raw_data(args), "o:")
			if opt == -1 {
				break
			}

			switch opt {
			case 'o':
				subopt := posix.optarg
				value: cstring
				for subopt != "" && !errfnd {
					o := posix.getsubopt(&subopt, &token[.RO], &value)
					switch Opt(o) {
					case .RO:   opts.readonly  = true
					case .RW:   opts.readwrite = true
					case .NAME:
						if value == nil {
							fmt.eprintfln("missing value for suboption %s", token[.NAME])
							errfnd = true
							continue
						}

						opts.name = value
					case .NIL:
						fallthrough
					case:
						fmt.eprintfln("no match found for token: %s", value)
						errfnd = true
					}
				}
				if opts.readwrite && opts.readonly {
					fmt.eprintfln("Only one of %s and %s can be specified", token[.RO], token[.RW])
					errfnd = true
				}
			case:
				errfnd = true
			}
		}

		if errfnd || len(args) == 1 {
			fmt.eprintfln("\nUsage: %s -o <suboptstring>", args[0])
			fmt.eprintfln("suboptions are 'ro', 'rw', and 'name=<value>'")
			posix.exit(1)
		}

		fmt.println(opts)

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/getsubopt.html ]]
	*/
	getsubopt :: proc(optionp: ^cstring, keylistp: [^]cstring, valuep: ^cstring) -> c.int ---

	/*
	Changes the mode and ownership of the slave pseudo-terminal device associated with its master pseudo-terminal counterpart.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/grantpt.html ]]
	*/
	grantpt :: proc(fildes: FD) -> result ---

	/*
	Allows a state array, pointed to by the state argument, to be initialized for future use.

	Returns: the previous state array or nil on failure

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/initstate.html ]]
	*/
	@(link_name=LINITSTATE)
	initstate :: proc(seed: c.uint, state: [^]byte, size: c.size_t) -> [^]byte ---

	/*
	Sets the state array of the random number generator.

	Returns: the previous state array or nil on failure

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/initstate.html ]]
	*/
	setstate :: proc(state: [^]byte) -> [^]byte ---

	/*
	Use a non-linear additive feedback random-number generator employing a default state array
	size of 31 long integers to return successive pseudo-random numbers in the range from 0 to 231-1.
	The period of this random-number generator is approximately 16 x (231-1).
	The size of the state array determines the period of the random-number generator.
	Increasing the state array size shall increase the period.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/initstate.html ]]
	*/
	random :: proc() -> c.long ---

	/*
	Initializes the current state array using the value of seed.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/initstate.html ]]
	*/
	@(link_name=LSRANDOM)
	srandom :: proc(seed: c.uint) ---

	/*
	Creates a directory with a unique name derived from template.
	The application shall ensure that the string provided in template is a pathname ending
	with at least six trailing 'X' characters.

	Returns: nil (setting errno) on failure, template on success

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/mkdtemp.html ]]
	*/
	mkdtemp :: proc(template: [^]byte) -> cstring ---

	/*
	Creates a regular file with a unique name derived from template and return a file descriptor
	for the file open for reading and writing.
	The application shall ensure that the string provided in template is a pathname ending with
	at least six trailing 'X' characters. 
	
	Returns: -1 (setting errno) on failure, an open file descriptor on success

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/mkdtemp.html ]]
	*/
	mkstemp :: proc(template: cstring) -> FD ---

	/*
	Allocates size bytes aligned on a boundary specified by alignment, and shall return a pointer
	to the allocated memory in memptr.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/posix_memalign.html ]]
	*/
	posix_memalign :: proc(memptr: ^[^]byte, alignment: c.size_t, size: c.size_t) -> Errno ---

	/*
	Establishes a connection between a master device for a pseudo-terminal and a file descriptor.

	Returns: -1 (setting errno) on failure, an open file descriptor otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/posix_openpt.html ]]
	*/
	posix_openpt :: proc(oflag: O_Flags) -> FD ---

	/*
	Returns the name of the slave pseudo-terminal device associated with a master pseudo-terminal device.

	Returns: nil (setting errno) on failure, the name on success, which may be invalidated on subsequent calls

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/ptsname.html ]]
	*/
	ptsname :: proc(fildes: FD) -> cstring ---

	/*
	Unlocks the slave pseudo-terminal device associated with the master to which fildes refers.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/unlockpt.html ]]
	*/
	unlockpt :: proc(fildes: FD) -> result ---

	/*
	Updates or add a variable in the environment of the calling process.

	Example:
		if posix.setenv("HOME", "/usr/home") != .OK {
			fmt.panicf("putenv failure: %v", posix.strerror(posix.errno()))
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setenv.html ]]
	*/
	setenv :: proc(envname: cstring, envval: cstring, overwrite: b32) -> result ---

	/*
	Removes an environment variable from the environment of the calling process.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/unsetenv.html ]]
	*/
	@(link_name=LUNSETENV)
	unsetenv :: proc(name: cstring) -> result ---

	/*
	Computes a sequence of pseudo-random integers in the range [0, {RAND_MAX}].
	(The value of the {RAND_MAX} macro shall be at least 32767.)

	If rand_r() is called with the same initial value for the object pointed to by seed and that object is not modified between successive returns and calls to rand_r(), the same sequence shall be generated.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/rand_r.html ]]
	*/
	rand_r :: proc(seed: ^c.uint) -> c.int ---

	/*
	Derive, from the pathname file_name, an absolute pathname that resolves to the same directory entry,
	whose resolution does not involve '.', '..', or symbolic links.

	If resolved_name is not `nil` it should be larger than `PATH_MAX` and the result will use it as a backing buffer.
	If resolved_name is `nil` the returned string is allocated by `malloc`.

	Returns: `nil` (setting errno) on failure, the "real path" otherwise

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/realpath.html ]]
	*/
	realpath :: proc(file_name: cstring, resolved_name: [^]byte = nil) -> cstring ---

	/*
	Provides access to an implementation-defined encoding algorithm.
	The argument of setkey() is an array of length 64 bytes containing only the bytes with numerical
	value of 0 and 1.

	If this string is divided into groups of 8, the low-order bit in each group is ignored; this gives a 56-bit key which is used by the algorithm.
	This is the key that shall be used with the algorithm to encode a string block passed to encrypt().

	The setkey() function shall not change the setting of errno if successful.
	An application wishing to check for error situations should set errno to 0 before calling setkey().
	If errno is non-zero on return, an error has occurred.

	Example:
		key: [64]byte
		// set key bytes...

		posix.set_errno(.NONE)
		posix.setkey(raw_data(key))
		if errno := posix.errno(); errno != .NONE {
			fmt.panicf("setkey failure: %s", posix.strerror(errno))
		}

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/setkey.html ]]
	*/
	setkey :: proc(key: [^]byte) ---
}

when ODIN_OS == .NetBSD {
	@(private) LINITSTATE :: "__initstate60"
	@(private) LSRANDOM   :: "__srandom60"
	@(private) LUNSETENV  :: "__unsetenv13"
} else {
	@(private) LINITSTATE :: "initstate"
	@(private) LSRANDOM   :: "srandom"
	@(private) LUNSETENV  :: "unsetenv"
}
