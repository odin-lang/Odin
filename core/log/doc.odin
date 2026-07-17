/*
Implementation of logging facilities.

Odin has builtin support for logging using procedure `context`. After a logger is created it can then be assigned to
`context.logger` and used implicitly in future log calls.

While it is ok for simple apps to use the `core:fmt` package, libraries and complex apps should prefer the `core:log`
package. By using the implicit logger library and application authors allow the caller to decide how to process log
messages.

When starting out you can easily just init the logger with a single line.
Example:

	package main

	import "core:log"

	main :: proc() {
		context.logger = log.create_console_logger()
		log.info("Hello World!")
	}

However when the application gets more involved you might want to try a more complex setup.
Example:

	package main

	import "core:log"
	import "core:os"

	main :: proc() {
		handle, err := os.open("logs.txt", os.O_RDWR | os.O_APPEND | os.O_CREATE, 0o666)
		assert(err == nil, "Cannot open log file")

		file_logger := log.create_file_logger(handle)
		// This closes the file handle
		defer log.destroy_file_logger(file_logger)

		console_logger := log.create_console_logger()
		defer log.destroy_console_logger(console_logger)

		multi_logger := log.create_multi_logger(console_logger, file_logger)
		defer log.destroy_multi_logger(multi_logger)

		context.logger = multi_logger

		log.info("Application started!")
	}

It is also possible to create an allocator that logs all allocations.
Example:

	package main

	import "core:log"

	main :: proc() {
		context.logger = log.create_console_logger()

		alloc: log.Log_Allocator
		log.log_allocator_init(&alloc, .Debug)
		context.allocator = log.log_allocator(&alloc)

		a := new(i32)
		free(a)
	}
*/
package log