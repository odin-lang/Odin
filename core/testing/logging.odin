#+private
package testing

/*
	(c) Copyright 2024 Feoramund <rune@swevencraft.org>.
	Made available under Odin's license.

	List of contributors:
		Ginger Bill: Initial implementation.
		Feoramund:   Total rewrite.
*/

import "base:runtime"
import "core:fmt"
import "core:log"
import "core:strings"
import "core:sync/chan"
import "core:time"

when USING_SHORT_LOGS {
	Default_Test_Logger_Opts :: runtime.Logger_Options {
		.Level,
		.Terminal_Color,
		.Short_File_Path,
		.Line,
	}
} else {
	Default_Test_Logger_Opts :: runtime.Logger_Options {
		.Level,
		.Terminal_Color,
		.Short_File_Path,
		.Line,
		.Procedure,
		.Date, .Time,
	}
}

Log_Message :: struct {
	level: runtime.Logger_Level,
	text: string,
	time: time.Time,
	// `text` may be allocated differently, depending on where a log message
	// originates from.
	allocator: runtime.Allocator,
}

test_logger_proc :: proc(logger_data: rawptr, level: runtime.Logger_Level, text: string, options: runtime.Logger_Options, location := #caller_location) {
	t := cast(^T)logger_data

	if level >= .Error {
		t.error_count += 1
	}

	cloned_text, clone_error := strings.clone(text, t._log_allocator)
	assert(clone_error == nil, "Error while cloning string in test thread logger proc.")

	now := time.now()

	chan.send(t.channel, Event_Log_Message {
		level = level,
		text = cloned_text,
		time = now,
		formatted_text = format_log_text(level, text, options, location, now, t._log_allocator),
	})
}

runner_logger_proc :: proc(logger_data: rawptr, level: runtime.Logger_Level, text: string, options: runtime.Logger_Options, location := #caller_location) {
	log_messages := cast(^[dynamic]Log_Message)logger_data

	now := time.now()

	append(log_messages, Log_Message {
		level = level,
		text = format_log_text(level, text, options, location, now),
		time = now,
		allocator = context.allocator,
	})
}

format_log_text :: proc(level: runtime.Logger_Level, text: string, options: runtime.Logger_Options, location: runtime.Source_Code_Location, at_time: time.Time, allocator := context.allocator) -> string{
	backing: [1024]byte
	buf := strings.builder_from_bytes(backing[:])

	log.do_level_header(options, &buf, level)
	log.do_time_header(options, &buf, at_time)
	when GO_TO_ERROR {
		do_go_to_error_friendly_location(options, &buf, location)
	} else {
		log.do_location_header(options, &buf, location)
	}
	return fmt.aprintf("%s%s", strings.to_string(buf), text, allocator = allocator)
}

do_go_to_error_friendly_location :: proc(opts: log.Options, buf: ^strings.Builder, location := #caller_location) {
	if log.Location_Header_Opts & opts == nil {
		return
	}
	fmt.sbprint(buf, "\n")

	file := location.file_path
	fmt.sbprint(buf, file)

	fmt.sbprint(buf, "(")
	fmt.sbprint(buf, location.line)
	fmt.sbprint(buf, ":")
	fmt.sbprint(buf, location.column)
	fmt.sbprint(buf, ")")

	if .Procedure in opts {
		fmt.sbprintf(buf, ":%s()", location.procedure)
	}
	fmt.sbprint(buf, " ")
}