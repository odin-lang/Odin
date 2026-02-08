#+build !freestanding
#+build !js
package text_table

import    "core:io"
import os "core:os/os2"
import    "core:strings"

stdio_writer :: proc() -> io.Writer {
	return os.to_stream(os.stdout)
}

strings_builder_writer :: proc(b: ^strings.Builder) -> io.Writer {
	return strings.to_writer(b)
}
