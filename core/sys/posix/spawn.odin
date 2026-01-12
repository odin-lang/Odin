#+build linux, darwin, openbsd, freebsd, netbsd, haiku
package posix

when ODIN_OS == .Darwin {
	foreign import lib "system:System.framework"
} else {
	foreign import lib "system:c"
}

foreign lib {
	/*
	Creates a child process from a provided filepath
	spawnp searches directories on the path for the file

	Returns: 0 on success, with the child pid returned in the pid argument, or error values on failure.

	[[ More; https://pubs.opengroup.org/onlinepubs/9699919799/functions/posix_spawn.html ]]
	*/
	posix_spawn :: proc(pid: ^pid_t, path: cstring, file_actions: rawptr, attrp: rawptr, argv: [^]cstring, envp: [^]cstring) -> Errno ---
	posix_spawnp :: proc(pid: ^pid_t, file: cstring, file_actions: rawptr, attrp: rawptr, argv: [^]cstring, envp: [^]cstring) -> Errno ---
}
