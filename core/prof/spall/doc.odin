/*
import "core:prof/spall"

spall_ctx: spall.Context
spall_buffer: spall.Buffer

foo :: proc() {
	spall.SCOPED_EVENT(&spall_ctx, &spall_buffer, #procedure)
}

main :: proc() {
    spall_ctx = spall.context_create("trace_test.spall")
    defer spall.context_destroy(&spall_ctx)

    buffer_backing := make([]u8, spall.BUFFER_DEFAULT_SIZE)
    spall_buffer = spall.buffer_create(buffer_backing)
    defer spall.buffer_destroy(&spall_ctx, &spall_buffer)

    spall.SCOPED_EVENT(&spall_ctx, &spall_buffer, #procedure)

    for i := 0; i < 9001; i += 1 {
		foo()
    }
}
*/
package spall
