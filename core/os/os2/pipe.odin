package os2

/*
Create an anonymous pipe.

This procedure creates an anonymous pipe, returning two ends of the pipe, `r`
and `w`. The file `r` is the readable end of the pipe. The file `w` is a
writeable end of the pipe.

Pipes are used as an inter-process communication mechanism, to communicate
between a parent and a child process. The child uses one end of the pipe to
write data, and the parent uses the other end to read from the pipe
(or vice-versa). When a parent passes one of the ends of the pipe to the child
process, that end of the pipe needs to be closed by the parent, before any data
is attempted to be read.

Although pipes look like files and is compatible with most file APIs in package
os2, the way it's meant to be read is different. Due to asynchronous nature of
the communication channel, the data may not be present at the time of a read
request. The other scenario is when a pipe has no data because the other end
of the pipe was closed by the child process.
*/
@(require_results)
pipe :: proc() -> (r, w: ^File, err: Error) {
	return _pipe()
}

/*
Check if the pipe has any data.

This procedure checks whether a read-end of the pipe has data that can be
read, and returns `true`, if the pipe has readable data, and `false` if the
pipe is empty. This procedure does not block the execution of the current
thread.

**Note**: If the other end of the pipe was closed by the child process, the
`.Broken_Pipe`
can be returned by this procedure. Handle these errors accordingly.
*/
@(require_results)
pipe_has_data :: proc(r: ^File) -> (ok: bool, err: Error) {
	return _pipe_has_data(r)
}
