package bytes

/*
	Copyright 2021 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-2 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.

	`bytes.Buffer` type conversion helpers.
*/

import "core:intrinsics"
import "core:mem"

need_endian_conversion :: proc($FT: typeid, $TT: typeid) -> (res: bool) {

	// true if platform endian
	f: bool;
	t: bool;

	when ODIN_ENDIAN == "little" {
		f = intrinsics.type_is_endian_platform(FT) || intrinsics.type_is_endian_little(FT);
		t = intrinsics.type_is_endian_platform(TT) || intrinsics.type_is_endian_little(TT);

		return f != t;
	} else {
		f = intrinsics.type_is_endian_platform(FT) || intrinsics.type_is_endian_big(FT);
		t = intrinsics.type_is_endian_platform(TT) || intrinsics.type_is_endian_big(TT);

		return f != t;
	}

	return;
}

/*
	Input:
		count:         number of elements
		$TT:           destination type
		$FT:           source type
		from_buffer:   buffer to convert
		force_convert: cast each element separately

	Output:
		res:           Converted/created buffer of []TT.
		backing:       ^bytes.Buffer{} backing the converted data.
		alloc:         Buffer was freshly allocated because we couldn't convert in-place. Points to `from_buffer` if `false`.
		err:           True if we passed too few elements or allocation failed, etc.

	If `from_buffer` is empty, the input type $FT is ignored and `create_buffer_of_type` is called to create a fresh buffer.

	This helper will try to do as little work as possible, so if you're converting between two equally sized types,
	and they have compatible endianness, the contents will simply be reinterpreted using `slice_data_cast`.

	If you want each element to be converted in this case, set `force_convert` to `true`.

	For example, converting `[]u8{0, 60}` from `[]f16` to `[]u16` will return `[15360]` when simply reinterpreted,
	and `[1]` if force converted.

	Should you for example want to promote `[]f16` to `[]f32` (or truncate `[]f32` to `[]f16`), the size of these elements
	being different will result in a conversion anyway, so this flag is unnecessary in cases like these.

	Example:
		fmt.println("Convert []f16le (x2) to []f32 (x2).");
		b := []u8{0, 60, 0, 60}; // == []f16{1.0, 1.0}

		res, backing, had_to_allocate, err := bytes.buffer_convert_to_type(2, f32, f16le, b);
		fmt.printf("res      : %v\n", res);              // [1.000, 1.000]
		fmt.printf("backing  : %v\n", backing);          // &Buffer{buf = [0, 0, 128, 63, 0, 0, 128, 63], off = 0, last_read = Invalid}
		fmt.printf("allocated: %v\n", had_to_allocate);  // true
		fmt.printf("err      : %v\n", err);              // false

		if had_to_allocate { defer bytes.buffer_destroy(backing); }

		fmt.println("\nConvert []f16le (x2) to []u16 (x2).");

		res2: []u16;
		res2, backing, had_to_allocate, err = bytes.buffer_convert_to_type(2, u16, f16le, b);
		fmt.printf("res      : %v\n", res2);             // [15360, 15360]
		fmt.printf("backing  : %v\n", backing);          // Buffer.buf points to `b` because it could be converted in-place.
		fmt.printf("allocated: %v\n", had_to_allocate);  // false
		fmt.printf("err      : %v\n", err);              // false

		if had_to_allocate { defer bytes.buffer_destroy(backing); }

		fmt.println("\nConvert []f16le (x2) to []u16 (x2), force_convert=true.");

		res2, backing, had_to_allocate, err = bytes.buffer_convert_to_type(2, u16, f16le, b, true);
		fmt.printf("res      : %v\n", res2);             // [1, 1]
		fmt.printf("backing  : %v\n", backing);          // Buffer.buf points to `b` because it could be converted in-place.
		fmt.printf("allocated: %v\n", had_to_allocate);  // false
		fmt.printf("err      : %v\n", err);              // false

		if had_to_allocate { defer bytes.buffer_destroy(backing); }
*/
buffer_convert_to_type :: proc(count: int, $TT: typeid, $FT: typeid, from_buffer: []u8, force_convert := false) -> (
	res: []TT, backing: ^Buffer, alloc: bool, err: bool) {

	backing = new(Buffer);

	if len(from_buffer) > 0 {
		/*
			Check if we've been given enough input elements.
		*/
		from := mem.slice_data_cast([]FT, from_buffer);
		if len(from) != count {
			err = true;
			return;
		}

		/*
			We can early out if the types are exactly identical.
			This needs to be `when`, or res = from will fail if the types are different.
		*/
		when FT == TT {
			res = from;
			buffer_init(backing, from_buffer);
			return;
		}

		/*
			We can do a data cast if in-size == out-size and no endian conversion is needed.
		*/
		convert := need_endian_conversion(FT, TT);
		convert |= (size_of(TT) * count != len(from_buffer));
		convert |= force_convert;

		if !convert {
			// It's just a data cast
			res = mem.slice_data_cast([]TT, from_buffer);
			buffer_init(backing, from_buffer);

			if len(res) != count {
				err = true;
			}
			return;
		} else {
			if size_of(TT) * count == len(from_buffer) {
				/*
					Same size, can do an in-place Endianness conversion.
					If `force_convert`, this also handles the per-element cast instead of slice_data_cast.
				*/
				res  = mem.slice_data_cast([]TT, from_buffer);
				buffer_init(backing, from_buffer);
				for v, i in from {
					res[i] = TT(v);
				}
			} else {
				/*
					Result is a different size, we need to allocate an output buffer.
				*/
				size := size_of(TT) * count;
				buffer_init_allocator(backing, size, size, context.allocator);
				alloc = true;
				res   = mem.slice_data_cast([]TT, backing.buf[:]);
				if len(res) != count {
					err = true;
					return;
				}

				for v, i in from {
					res[i] = TT(v);
				}
			}
		}
	} else {
		/*
			The input buffer is empty, so we'll have to create a new one for []TT of length count.
		*/
		res, backing, err = buffer_create_of_type(count, TT);
		alloc = true;
	}

	return;
}

buffer_create_of_type :: proc(count: int, $TT: typeid) -> (res: []TT, backing: ^Buffer, err: bool) {
	backing = new(Buffer);
	size := size_of(TT) * count;
	buffer_init_allocator(backing, size, size, context.allocator);
	res   = mem.slice_data_cast([]TT, backing.buf[:]);
	if len(res) != count {
		err = true;
	}
	return;
}