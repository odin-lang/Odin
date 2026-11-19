package encoding_json

import "base:runtime"
import "core:strings"
import "core:io"
import "core:slice"
import "core:strconv"

Unparse_Error :: union #shared_nil {
	io.Error,
	runtime.Allocator_Error,
	Marshal_Data_Error,
}

/*
	Formats value `v` back into an equivalent JSON string, and returns the result as a `string`.

	Allocates the result using the provided `allocator` (caller must free the result).
*/
@(require_results)
unparse :: proc(v: Value, opt: Marshal_Options = {}, allocator := context.allocator, loc := #caller_location) -> (data: string, err: Unparse_Error) {
	b := strings.builder_make(allocator, loc)
	defer if err != nil {
		strings.builder_destroy(&b)
	}

	// temp guard in case we are sorting map keys, which will use temp allocations
	runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(ignore = allocator == context.temp_allocator)

	unparse_to_builder(&b, v, opt) or_return
	data = string(b.buf[:])
	return
}

/*
	Formats value `v` back into an equivalent JSON string, and writes it into `b`.
*/
@(require_results)
unparse_to_builder :: proc(b: ^strings.Builder, v: Value, opt: Marshal_Options = {}) -> Unparse_Error {
	err := unparse_to_writer(strings.to_writer(b), v, opt)
	if err == io.Error.EOF {
		return .Out_Of_Memory
	}
	return err
}

/*
	Formats value `v` back into an equivalent JSON string, and writes it into `w`.
*/
@(require_results)
unparse_to_writer :: proc(w: io.Writer, value: Value, opt: Marshal_Options = {}) -> Unparse_Error {
	opt := opt
	return _unparse_to_writer(w, value, &opt)
}

@(private)
_unparse_to_writer :: proc(w: io.Writer, value: Value, opt: ^Marshal_Options) -> Unparse_Error {
	switch v in value {
	case nil, Null:
		io.write_string(w, "null") or_return
	case Integer:
		buf: [40]byte
		s: string
		if opt.write_uint_as_hex && v >= 0 && (opt.spec == .JSON5 || opt.spec == .MJSON) {
			s = strconv.write_bits_128(buf[:], u128(v), 16, false, 64, "0123456789abcdef", {.Prefix})
		} else {
			s = strconv.write_bits_128(buf[:], u128(v), 10, true, 64, "0123456789", nil)
		}
		io.write_string(w, s) or_return
	case Float:
		buf: [64]byte
		io.write_string(w, format_float(buf[:], v, 64, opt.spec, opt.non_finite_as_null) or_return) or_return
	case Boolean:
		io.write_string(w, "true" if v else "false") or_return
	case String:
		write_quoted_json_string(w, v) or_return
	case Array:
		opt_write_start(w, opt, '[') or_return
		for e, i in v {
			opt_write_iteration(w, opt, i == 0) or_return
			_unparse_to_writer (w, e,   opt)    or_return
		}
		opt_write_end(w, opt, ']') or_return
	case Object:
		if !opt.sort_maps_by_key {
			opt_write_start(w, opt, '{') or_return
			for first_iteration := true; key, val in v {
				opt_write_iteration(w, opt, first_iteration) or_return
				unparse_write_key  (w, opt, key)             or_return
				_unparse_to_writer (w, val, opt)             or_return
				first_iteration = false
			}
			opt_write_end(w, opt, '}') or_return
		} else {
			Map_Entry :: struct {
				key: string,
				value: Value,
			}

			entries := make([dynamic]Map_Entry, 0, len(v), context.temp_allocator) or_return
			defer delete(entries)
			for key, val in v {
				_, _ = append(&entries, Map_Entry{key, val})
			}

			slice.sort_by(entries[:], proc(i, j: Map_Entry) -> bool { return i.key < j.key })

			opt_write_start(w, opt, '{') or_return
			for e, i in entries {
				opt_write_iteration(w, opt, i == 0)  or_return
				unparse_write_key  (w, opt, e.key)   or_return
				_unparse_to_writer (w, e.value, opt) or_return
			}
			opt_write_end(w, opt, '}') or_return
		}
		return nil
	}
	return nil
}

@(private)
unparse_write_key :: proc(w: io.Writer, opt: ^Marshal_Options, key: string) -> Unparse_Error {
	switch err in opt_write_key(w, opt, key) {
	case Marshal_Data_Error:      return err
	case io.Error:                return err
	case runtime.Allocator_Error: return err
	}
	return nil
}
