package text_table

import "core:io"
import "core:os"
import "core:strings"

stdio_writer :: proc() -> io.Writer {
	return io.to_writer(os.stream_from_handle(os.stdout))
}

strings_builder_writer :: proc(b: ^strings.Builder) -> io.Writer {
	return strings.to_writer(b)
}
