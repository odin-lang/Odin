package sys_freebsd

/* Get window size */
TIOCGWINSZ :: 0x40087468

/*
	Standard input file descriptor
*/
STDIN_FILENO :: Fd(0)

/*
	Standard output file descriptor
*/
STDOUT_FILENO :: Fd(1)

/*
	Standard error file descriptor
*/
STDERR_FILENO :: Fd(2)
