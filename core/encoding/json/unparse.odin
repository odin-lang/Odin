package encoding_json

import "base:runtime"
import "core:strings"
import "core:io"
import "core:slice"

unparse :: proc(v: Value, opt: Marshal_Options = {}, allocator := context.allocator, loc := #caller_location) -> (data: []u8, err: io.Error) {
	b := strings.builder_make(allocator, loc)
	defer if err != nil {
		strings.builder_destroy(&b)
	}
	
	// temp guard in case we are sorting map keys, which will use temp allocations
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator)

	opt := opt
	unparse_to_builder(&b, v, &opt) or_return
	
	if len(b.buf) != 0 {
		data = b.buf[:]
	}

	return data, nil
}

unparse_to_builder :: proc(b: ^strings.Builder, v: Value, opt: ^Marshal_Options) -> io.Error {
	return unparse_to_writer(strings.to_writer(b), v, opt)
}

unparse_to_writer :: proc(w: io.Writer, v: Value, opt: ^Marshal_Options) -> io.Error {
	if v == nil {
		return unparse_null_to_writer(w, opt)
	}

	switch uv in v {
		case Null: return unparse_null_to_writer(w, opt)
		case Integer: return unparse_integer_to_writer(w, uv, opt)
		case Float: return unparse_float_to_writer(w, uv, opt)
		case Boolean: return unparse_boolean_to_writer(w, uv, opt)
		case String: return unparse_string_to_writer(w, uv, opt)
		case Array: return unparse_array_to_writer(w, uv, opt)
		case Object: return unparse_object_to_writer(w, uv, opt)
	}
	return nil
}

unparse_null_to_writer :: proc(w: io.Writer, opt: ^Marshal_Options) -> io.Error {
	io.write_string(w, "null") or_return
	return nil
}

unparse_integer_to_writer :: proc(w: io.Writer, v: Integer, opt: ^Marshal_Options) -> io.Error {
	base := 16 if opt.write_uint_as_hex && (opt.spec == .JSON5 || opt.spec == .MJSON) else 10
	io.write_i64(w, v, base) or_return
	return nil
}

unparse_float_to_writer :: proc(w: io.Writer, v: Float, opt: ^Marshal_Options) -> io.Error {
	io.write_f64(w, v) or_return
	return nil
}

unparse_boolean_to_writer :: proc(w: io.Writer, v: Boolean, opt: ^Marshal_Options) -> io.Error {
	io.write_string(w, v ? "true" : "false") or_return
	return nil
}

unparse_string_to_writer :: proc(w: io.Writer, v: String, opt: ^Marshal_Options) -> io.Error {
	io.write_quoted_string(w, v, '"', nil, true) or_return
	return nil
}

unparse_array_to_writer :: proc(w: io.Writer, v: Array, opt: ^Marshal_Options) -> io.Error {
	opt_write_start(w, opt, '[') or_return
	for i in 0..<len(v) {
		opt_write_iteration(w, opt, i == 0) or_return
		unparse_to_writer(w, v[i], opt) or_return
	}
	opt_write_end(w, opt, ']') or_return
	return nil
}

unparse_object_to_writer :: proc(w: io.Writer, m: Object, opt: ^Marshal_Options) -> io.Error {
	if !opt.sort_maps_by_key {
		opt_write_start(w, opt, '{') or_return

		first_iteration := true
		for k,v in m {
			opt_write_iteration(w, opt, first_iteration) or_return
			opt_write_key(w, opt, k) or_return
			unparse_to_writer(w, v, opt) or_return
			first_iteration = false
		}

		opt_write_end(w, opt, '}') or_return
	}
	else {
		Entry :: struct {
			key: string,
			value: Value
		}

		entries := make([dynamic]Entry, 0, len(m), context.temp_allocator)
		for k, v in m {
			append(&entries, Entry{k, v})
		}

		slice.sort_by(entries[:], proc(i, j: Entry) -> bool { return i.key < j.key })
		
		opt_write_start(w, opt, '{') or_return
		for e, i in entries {
			opt_write_iteration(w, opt, i == 0) or_return
			opt_write_key(w, opt, e.key) or_return
			unparse_to_writer(w, e.value, opt) or_return
		}
		opt_write_end(w, opt, '}') or_return
	}
	return nil
}
