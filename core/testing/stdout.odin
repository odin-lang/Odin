#+private
package testing

import "base:runtime"
import "core:fmt"
import "core:io"
import "core:strings"
import "core:os"
import "core:sync/chan"

Stdout_Message :: struct {
	text: string,
	allocator: runtime.Allocator,
}

Stdout_Channel :: chan.Chan(Stdout_Message)
Stdout_Channel_Sender :: chan.Chan(Stdout_Message, .Send)

Test_Stdout_Ctx :: struct {
	file: os.File,
	real_stdout: ^os.File,
	channel: Stdout_Channel_Sender,
	allocator: runtime.Allocator,
}

init_test_stdout_ctx :: proc(
	ctx: ^Test_Stdout_Ctx,
	real_stdout: ^os.File,
	channel: Stdout_Channel_Sender,
	allocator: runtime.Allocator,
) {
	assert(real_stdout != nil)
	ctx^ = {
		real_stdout = real_stdout,
		channel = channel,
		allocator = allocator,
		file = real_stdout^,
	}
	ctx.file.stream = {
		procedure = test_stdout_stream_proc,
		data = ctx,
	}
}

test_stdout_stream_proc :: proc(
	stream_data: rawptr,
	mode: os.File_Stream_Mode,
	p: []byte,
	offset: i64,
	whence: io.Seek_From,
	allocator: runtime.Allocator,
) -> (n: i64, err: os.Error) {
	f := (^os.File)(stream_data)
	ctx := (^Test_Stdout_Ctx)(f.stream.data)

	#partial switch mode {
	case .Write:
		if len(p) == 0 {
			return 0, nil
		}

		cloned, clone_err := strings.clone(string(p), ctx.allocator)
		assert(clone_err == nil, "Error cloning stdout write buffer in test runner.")

		chan.send(ctx.channel, Stdout_Message {
			text = cloned,
			allocator = ctx.allocator,
		})
		return i64(len(p)), nil

	case .Flush:
		return 0, nil
	}

	return ctx.real_stdout.stream.procedure(ctx.real_stdout, mode, p, offset, whence, allocator)
}

drain_stdout_channel :: proc(
	channel: Stdout_Channel,
	messages: ^[dynamic]Stdout_Message,
) -> runtime.Allocator_Error {
	for {
		message, ok := chan.try_recv(channel)
		if !ok {
			return nil
		}
		_, err := append(messages, message)
		if err != nil {
			return err
		}
	}
}

emit_stdout_messages :: proc(w: io.Writer, messages: ^[dynamic]Stdout_Message) -> (ends_with_newline: bool) {
	ends_with_newline = true
	for message in messages {
		fmt.wprint(w, message.text)
		if len(message.text) > 0 {
			ends_with_newline = message.text[len(message.text)-1] == '\n'
		}
		delete(message.text, message.allocator)
	}
	clear(messages)
	return
}

free_stdout_messages :: proc(messages: ^[dynamic]Stdout_Message) {
	for message in messages {
		delete(message.text, message.allocator)
	}
	clear(messages)
}
