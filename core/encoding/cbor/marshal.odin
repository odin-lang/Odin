package encoding_cbor

import "base:intrinsics"
import "base:runtime"

import "core:bytes"
import "core:io"
import "core:mem"
import "core:reflect"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:unicode/utf8"

/*
Marshal a value into binary CBOR.

Flags can be used to control the output (mainly determinism, which coincidently affects size).

The default flags `ENCODE_SMALL` (`.Deterministic_Int_Size`, `.Deterministic_Float_Size`) will try
to put ints and floats into their smallest possible byte size without losing equality.

Adding the `.Self_Described_CBOR` flag will wrap the value in a tag that lets generic decoders know
the contents are CBOR from just reading the first byte.

Adding the `.Deterministic_Map_Sorting` flag will sort the encoded maps by the byte content of the
encoded key. This flag has a cost on performance and memory efficiency because all keys in a map
have to be precomputed, sorted and only then written to the output.

Empty flags will do nothing extra to the value.

The allocations for the `.Deterministic_Map_Sorting` flag are done using the given `temp_allocator`.
but are followed by the necessary `delete` and `free` calls if the allocator supports them.
This is helpful when the CBOR size is so big that you don't want to collect all the temporary
allocations until the end.
*/
marshal_into :: proc {
	marshal_into_bytes,
	marshal_into_builder,
	marshal_into_writer,
	marshal_into_encoder,
}

marshal :: marshal_into

// Marshals the given value into a CBOR byte stream (allocated using the given allocator).
// See docs on the `marshal_into` proc group for more info.
marshal_into_bytes :: proc(v: any, flags := ENCODE_SMALL, allocator := context.allocator, temp_allocator := context.temp_allocator, loc := #caller_location) -> (bytes: []byte, err: Marshal_Error) {
	b, alloc_err := strings.builder_make(allocator, loc=loc)
 	// The builder as a stream also returns .EOF if it ran out of memory so this is consistent.
	if alloc_err != nil {
		return nil, .EOF
	}

	defer if err != nil { strings.builder_destroy(&b) }

	if err = marshal_into_builder(&b, v, flags, temp_allocator); err != nil {
		return
	}

	return b.buf[:], nil
}

// Marshals the given value into a CBOR byte stream written to the given builder.
// See docs on the `marshal_into` proc group for more info.
marshal_into_builder :: proc(b: ^strings.Builder, v: any, flags := ENCODE_SMALL, temp_allocator := context.temp_allocator) -> Marshal_Error {
	return marshal_into_writer(strings.to_writer(b), v, flags, temp_allocator)
}

// Marshals the given value into a CBOR byte stream written to the given writer.
// See docs on the `marshal_into` proc group for more info.
marshal_into_writer :: proc(w: io.Writer, v: any, flags := ENCODE_SMALL, temp_allocator := context.temp_allocator) -> Marshal_Error {
	encoder := Encoder{flags, w, temp_allocator}
	return marshal_into_encoder(encoder, v)
}

// Marshals the given value into a CBOR byte stream written to the given encoder.
// See docs on the `marshal_into` proc group for more info.
marshal_into_encoder :: proc(e: Encoder, v: any) -> (err: Marshal_Error) {
	e := e

	if e.temp_allocator.procedure == nil {
		e.temp_allocator = context.temp_allocator
	}

	if .Self_Described_CBOR in e.flags {
		err_conv(_encode_u64(e, TAG_SELF_DESCRIBED_CBOR, .Tag)) or_return
		e.flags -= { .Self_Described_CBOR }
	}

	if v == nil {
		return _encode_nil(e.writer)
	}
	
	// Check if type has a tag implementation to use.
	if impl, ok := _tag_implementations_type[v.id]; ok {
		return impl->marshal(e, v)
	}

	ti := runtime.type_info_core(type_info_of(v.id))
	return _marshal_into_encoder(e, v, ti)
}

_marshal_into_encoder :: proc(e: Encoder, v: any, ti: ^runtime.Type_Info) -> (err: Marshal_Error) {
	a := any{v.data, ti.id}
	#partial switch info in ti.variant {
	case runtime.Type_Info_Named, runtime.Type_Info_Enum, runtime.Type_Info_Bit_Field:
		unreachable()

	case runtime.Type_Info_Pointer:
		switch vv in v {
		case Undefined: return _encode_undefined(e.writer)
		case Nil:       return _encode_nil(e.writer)
		}

	case runtime.Type_Info_Integer:
		switch vv in v {
		case Simple:       return err_conv(_encode_simple(e.writer, vv))
		case Negative_U8:  return _encode_u8(e.writer, u8(vv), .Negative)
		case Negative_U16: return err_conv(_encode_u16(e, u16(vv), .Negative))
		case Negative_U32: return err_conv(_encode_u32(e, u32(vv), .Negative))
		case Negative_U64: return err_conv(_encode_u64(e, u64(vv), .Negative))
		}

		switch i in a {
		case i8:      return _encode_uint(e.writer, _int_to_uint(i))
		case i16:     return err_conv(_encode_uint(e, _int_to_uint(i)))
		case i32:     return err_conv(_encode_uint(e, _int_to_uint(i)))
		case i64:     return err_conv(_encode_uint(e, _int_to_uint(i)))
		case i128:    return err_conv(_encode_uint(e, _int_to_uint(i128(i)) or_return))
		case int:     return err_conv(_encode_uint(e, _int_to_uint(i64(i))))

		case u8:      return _encode_uint(e.writer, i)
		case u16:     return err_conv(_encode_uint(e, i))
		case u32:     return err_conv(_encode_uint(e, i))
		case u64:     return err_conv(_encode_uint(e, i))
		case u128:    return err_conv(_encode_uint(e, _u128_to_u64(u128(i)) or_return))
		case uint:    return err_conv(_encode_uint(e, u64(i)))
		case uintptr: return err_conv(_encode_uint(e, u64(i)))

		case i16le:  return err_conv(_encode_uint(e, _int_to_uint(i16(i))))
		case i32le:  return err_conv(_encode_uint(e, _int_to_uint(i32(i))))
		case i64le:  return err_conv(_encode_uint(e, _int_to_uint(i64(i))))
		case i128le: return err_conv(_encode_uint(e, _int_to_uint(i128(i)) or_return))

		case u16le:  return err_conv(_encode_uint(e, u16(i)))
		case u32le:  return err_conv(_encode_uint(e, u32(i)))
		case u64le:  return err_conv(_encode_uint(e, u64(i)))
		case u128le: return err_conv(_encode_uint(e, _u128_to_u64(u128(i)) or_return))

		case i16be:  return err_conv(_encode_uint(e, _int_to_uint(i16(i))))
		case i32be:  return err_conv(_encode_uint(e, _int_to_uint(i32(i))))
		case i64be:  return err_conv(_encode_uint(e, _int_to_uint(i64(i))))
		case i128be: return err_conv(_encode_uint(e, _int_to_uint(i128(i)) or_return))

		case u16be:  return err_conv(_encode_uint(e, u16(i)))
		case u32be:  return err_conv(_encode_uint(e, u32(i)))
		case u64be:  return err_conv(_encode_uint(e, u64(i)))
		case u128be: return err_conv(_encode_uint(e, _u128_to_u64(u128(i)) or_return))
		}

	case runtime.Type_Info_Rune:
		buf, w := utf8.encode_rune(a.(rune))
		return err_conv(_encode_text(e, string(buf[:w])))

	case runtime.Type_Info_Float:
		switch f in a {
		case f16: return _encode_f16(e.writer, f)
		case f32: return _encode_f32(e, f)
		case f64: return _encode_f64(e, f)

		case f16le: return _encode_f16(e.writer, f16(f))
		case f32le: return _encode_f32(e, f32(f))
		case f64le: return _encode_f64(e, f64(f))

		case f16be: return _encode_f16(e.writer, f16(f))
		case f32be: return _encode_f32(e, f32(f))
		case f64be: return _encode_f64(e, f64(f))
		}

	case runtime.Type_Info_Complex:
		switch z in a {
		case complex32:
			arr: [2]Value = {real(z), imag(z)}
			return err_conv(_encode_array(e, arr[:]))
		case complex64:
			arr: [2]Value = {real(z), imag(z)}
			return err_conv(_encode_array(e, arr[:]))
		case complex128:
			arr: [2]Value = {real(z), imag(z)}
			return err_conv(_encode_array(e, arr[:]))
		}

	case runtime.Type_Info_Quaternion:
		switch q in a {
		case quaternion64:
			arr: [4]Value = {imag(q), jmag(q), kmag(q), real(q)}
			return err_conv(_encode_array(e, arr[:]))
		case quaternion128:
			arr: [4]Value = {imag(q), jmag(q), kmag(q), real(q)}
			return err_conv(_encode_array(e, arr[:]))
		case quaternion256:
			arr: [4]Value = {imag(q), jmag(q), kmag(q), real(q)}
			return err_conv(_encode_array(e, arr[:]))
		}

	case runtime.Type_Info_String:
		switch s in a {
		case string:  return err_conv(_encode_text(e, s))
		case cstring: return err_conv(_encode_text(e, string(s)))
		}

	case runtime.Type_Info_Boolean:
		switch b in a {
		case bool: return _encode_bool(e.writer, b)
		case b8:   return _encode_bool(e.writer, bool(b))
		case b16:  return _encode_bool(e.writer, bool(b))
		case b32:  return _encode_bool(e.writer, bool(b))
		case b64:  return _encode_bool(e.writer, bool(b))
		}

	case runtime.Type_Info_Array:
		if info.elem.id == byte {
			raw := ([^]byte)(v.data)
			return err_conv(_encode_bytes(e, raw[:info.count]))
		}

		err_conv(_encode_u64(e, u64(info.count), .Array)) or_return

		if impl, ok := _tag_implementations_type[info.elem.id]; ok {
			for i in 0..<info.count {
				data := uintptr(v.data) + uintptr(i*info.elem_size)
				impl->marshal(e, any{rawptr(data), info.elem.id}) or_return
			}
			return
		}

		elem_ti := runtime.type_info_core(type_info_of(info.elem.id))
		for i in 0..<info.count {
			data := uintptr(v.data) + uintptr(i*info.elem_size)
			_marshal_into_encoder(e, any{rawptr(data), info.elem.id}, elem_ti) or_return
		}
		return

	case runtime.Type_Info_Enumerated_Array:
		// index := runtime.type_info_base(info.index).variant.(runtime.Type_Info_Enum)
		err_conv(_encode_u64(e, u64(info.count), .Array)) or_return

		if impl, ok := _tag_implementations_type[info.elem.id]; ok {
			for i in 0..<info.count {
				data := uintptr(v.data) + uintptr(i*info.elem_size)
				impl->marshal(e, any{rawptr(data), info.elem.id}) or_return
			}
			return
		}

		elem_ti := runtime.type_info_core(type_info_of(info.elem.id))
		for i in 0..<info.count {
			data := uintptr(v.data) + uintptr(i*info.elem_size)
			_marshal_into_encoder(e, any{rawptr(data), info.elem.id}, elem_ti) or_return
		}
		return
		
	case runtime.Type_Info_Dynamic_Array:
		if info.elem.id == byte {
			raw := (^[dynamic]byte)(v.data)
			return err_conv(_encode_bytes(e, raw[:]))
		}

		array := (^mem.Raw_Dynamic_Array)(v.data)
		err_conv(_encode_u64(e, u64(array.len), .Array)) or_return

		if impl, ok := _tag_implementations_type[info.elem.id]; ok {
			for i in 0..<array.len {
				data := uintptr(array.data) + uintptr(i*info.elem_size)
				impl->marshal(e, any{rawptr(data), info.elem.id}) or_return
			}
			return
		}

		elem_ti := runtime.type_info_core(type_info_of(info.elem.id))
		for i in 0..<array.len {
			data := uintptr(array.data) + uintptr(i*info.elem_size)
			_marshal_into_encoder(e, any{rawptr(data), info.elem.id}, elem_ti) or_return
		}
		return

	case runtime.Type_Info_Slice:
		if info.elem.id == byte {
			raw := (^[]byte)(v.data)
			return err_conv(_encode_bytes(e, raw^))
		}

		array := (^mem.Raw_Slice)(v.data)
		err_conv(_encode_u64(e, u64(array.len), .Array)) or_return

		if impl, ok := _tag_implementations_type[info.elem.id]; ok {
			for i in 0..<array.len {
				data := uintptr(array.data) + uintptr(i*info.elem_size)
				impl->marshal(e, any{rawptr(data), info.elem.id}) or_return
			}
			return
		}

		elem_ti := runtime.type_info_core(type_info_of(info.elem.id))
		for i in 0..<array.len {
			data := uintptr(array.data) + uintptr(i*info.elem_size)
			_marshal_into_encoder(e, any{rawptr(data), info.elem.id}, elem_ti) or_return
		}
		return

	case runtime.Type_Info_Map:
		m := (^mem.Raw_Map)(v.data)
		err_conv(_encode_u64(e, u64(runtime.map_len(m^)), .Map)) or_return
		if m != nil {
			if info.map_info == nil {
				return _unsupported(v.id, nil)
			}

			map_cap := uintptr(runtime.map_cap(m^))
			ks, vs, hs, _, _ := runtime.map_kvh_data_dynamic(m^, info.map_info)

			if .Deterministic_Map_Sorting not_in e.flags {
				for bucket_index in 0..<map_cap {
					runtime.map_hash_is_valid(hs[bucket_index]) or_continue

					key   := rawptr(runtime.map_cell_index_dynamic(ks, info.map_info.ks, bucket_index))
					value := rawptr(runtime.map_cell_index_dynamic(vs, info.map_info.vs, bucket_index))

					marshal_into(e, any{ key, info.key.id }) or_return
					marshal_into(e, any{ value, info.value.id }) or_return
				}

				return
			}

			// Deterministic_Map_Sorting needs us to sort the entries by the byte contents of the
			// encoded key.
			//
			// This means we have to store and sort them before writing incurring extra (temporary) allocations.
			//
			// If the map key is a `string` or `cstring` we only allocate space for a dynamic array of entries
			// we sort.
			//
			// If the map key is of another type we also allocate space for encoding the key into.

			// To sort a string/cstring we need to first sort by their encoded header/length.
			// This fits in 9 bytes at most.
			pre_key :: #force_inline proc(e: Encoder, str: string) -> (res: [10]byte) {
				e := e
				builder := strings.builder_from_slice(res[:])
				e.writer = strings.to_stream(&builder)

				assert(_encode_u64(e, u64(len(str)), .Text) == nil)
				res[9] = u8(len(builder.buf))
				assert(res[9] < 10)
				return
			}

			Encoded_Entry_Fast :: struct($T: typeid) {
				pre_key: [10]byte,
				key:     T,
				val_idx: uintptr,
			}

			Encoded_Entry :: struct {
				key:     ^[dynamic]byte,
				val_idx: uintptr,
			}

			switch info.key.id {
			case string:
				entries := make([dynamic]Encoded_Entry_Fast(^[]byte), 0, map_cap, e.temp_allocator) or_return
				defer delete(entries)

				for bucket_index in 0..<map_cap {
					runtime.map_hash_is_valid(hs[bucket_index]) or_continue

					key := (^[]byte)(runtime.map_cell_index_dynamic(ks, info.map_info.ks, bucket_index))
					append(&entries, Encoded_Entry_Fast(^[]byte){
						pre_key = pre_key(e, string(key^)),
						key     = key,
						val_idx = bucket_index,
					})
				}

				slice.sort_by_cmp(entries[:], proc(a, b: Encoded_Entry_Fast(^[]byte)) -> slice.Ordering {
					a, b := a, b
					pre_cmp := slice.Ordering(bytes.compare(a.pre_key[:a.pre_key[9]], b.pre_key[:b.pre_key[9]]))
					if pre_cmp != .Equal {
						return pre_cmp
					}

					return slice.Ordering(bytes.compare(a.key^, b.key^))
				})
				
				for &entry in entries {
					io.write_full(e.writer, entry.pre_key[:entry.pre_key[9]]) or_return
					io.write_full(e.writer, entry.key^) or_return

					value := rawptr(runtime.map_cell_index_dynamic(vs, info.map_info.vs, entry.val_idx))
					marshal_into(e, any{ value, info.value.id }) or_return
				}
				return

			case cstring:
				entries := make([dynamic]Encoded_Entry_Fast(^cstring), 0, map_cap, e.temp_allocator) or_return
				defer delete(entries)

				for bucket_index in 0..<map_cap {
					runtime.map_hash_is_valid(hs[bucket_index]) or_continue

					key := (^cstring)(runtime.map_cell_index_dynamic(ks, info.map_info.ks, bucket_index))
					append(&entries, Encoded_Entry_Fast(^cstring){
						pre_key = pre_key(e, string(key^)),
						key     = key,
						val_idx = bucket_index,
					})
				}

				slice.sort_by_cmp(entries[:], proc(a, b: Encoded_Entry_Fast(^cstring)) -> slice.Ordering {
					a, b := a, b
					pre_cmp := slice.Ordering(bytes.compare(a.pre_key[:a.pre_key[9]], b.pre_key[:b.pre_key[9]]))
					if pre_cmp != .Equal {
						return pre_cmp
					}

					ab := transmute([]byte)string(a.key^)
					bb := transmute([]byte)string(b.key^)
					return slice.Ordering(bytes.compare(ab, bb))
				})

				for &entry in entries {
					io.write_full(e.writer, entry.pre_key[:entry.pre_key[9]]) or_return
					io.write_full(e.writer, transmute([]byte)string(entry.key^)) or_return

					value := rawptr(runtime.map_cell_index_dynamic(vs, info.map_info.vs, entry.val_idx))
					marshal_into(e, any{ value, info.value.id }) or_return
				}
				return

			case:
				entries := make([dynamic]Encoded_Entry, 0, map_cap, e.temp_allocator) or_return
				defer delete(entries)

				for bucket_index in 0..<map_cap {
					runtime.map_hash_is_valid(hs[bucket_index]) or_continue

					key := rawptr(runtime.map_cell_index_dynamic(ks, info.map_info.ks, bucket_index))
					key_builder := strings.builder_make(0, 8, e.temp_allocator) or_return
					marshal_into(Encoder{e.flags, strings.to_stream(&key_builder), e.temp_allocator}, any{ key, info.key.id }) or_return
					append(&entries, Encoded_Entry{ &key_builder.buf, bucket_index }) or_return
				}

				slice.sort_by_cmp(entries[:], proc(a, b: Encoded_Entry) -> slice.Ordering {
					return slice.Ordering(bytes.compare(a.key[:], b.key[:]))
				})

				for entry in entries {
					io.write_full(e.writer, entry.key[:]) or_return
					delete(entry.key^)

					value := rawptr(runtime.map_cell_index_dynamic(vs, info.map_info.vs, entry.val_idx))
					marshal_into(e, any{ value, info.value.id }) or_return
				}
				return
			}
		}

	case runtime.Type_Info_Struct:
		switch vv in v {
		case Tag: return err_conv(_encode_tag(e, vv))
		}

		field_name :: #force_inline proc(info: runtime.Type_Info_Struct, i: int) -> string {
			if cbor_name := string(reflect.struct_tag_get(reflect.Struct_Tag(info.tags[i]), "cbor")); cbor_name != "" {
				return cbor_name
			} else {
				return info.names[i]
			}
		}

		marshal_entry :: #force_inline proc(e: Encoder, info: runtime.Type_Info_Struct, v: any, name: string, i: int) -> Marshal_Error {
			err_conv(_encode_text(e, name)) or_return

			id := info.types[i].id
			data := rawptr(uintptr(v.data) + info.offsets[i])
			field_any := any{data, id}
			
			if tag := string(reflect.struct_tag_get(reflect.Struct_Tag(info.tags[i]), "cbor_tag")); tag != "" {
				if impl, ok := _tag_implementations_id[tag]; ok {
					return impl->marshal(e, field_any)
				}

				nr, ok := strconv.parse_u64_of_base(tag, 10)
				if !ok { return .Invalid_CBOR_Tag }
				
				if impl, nok := _tag_implementations_nr[nr]; nok {
					return impl->marshal(e, field_any)
				}
				
				err_conv(_encode_u64(e, nr, .Tag)) or_return
			}

			return marshal_into(e, field_any)
		}
		
		n: u64; {
			for _, i in info.names {
				if field_name(info, i) != "-" {
					n += 1
				}
			}
			err_conv(_encode_u64(e, n, .Map)) or_return
		}

		if .Deterministic_Map_Sorting in e.flags {
			Name :: struct {
				name:  string,
				field: int,
			}
			entries := make([dynamic]Name, 0, n, e.temp_allocator) or_return
			defer delete(entries)

			for _, i in info.names {
				fname := field_name(info, i)
				if fname == "-" {
					continue
				}

				append(&entries, Name{fname, i}) or_return
			}

			// Sort lexicographic on the bytes of the key.
			slice.sort_by_cmp(entries[:], proc(a, b: Name) -> slice.Ordering {
				return slice.Ordering(bytes.compare(transmute([]byte)a.name, transmute([]byte)b.name))
			})

			for entry in entries {
				marshal_entry(e, info, v, entry.name, entry.field) or_return
			}
		} else {
			for _, i in info.names {
				fname := field_name(info, i)
				if fname == "-" {
					continue
				}

				marshal_entry(e, info, v, fname, i) or_return
			}
		}
		return

	case runtime.Type_Info_Union:
		switch vv in v {
		case Value: return err_conv(encode(e, vv))
		}

		id := reflect.union_variant_typeid(v)
		if v.data == nil || id == nil {
			return _encode_nil(e.writer)
		}

		if len(info.variants) == 1 {
			return marshal_into(e, any{v.data, id})
		}

		// Encode a non-nil multi-variant union as the `TAG_OBJECT_TYPE`.
		// Which is a tag of an array, where the first element is the textual id/type of the object
		// that follows it.

		err_conv(_encode_u16(e, TAG_OBJECT_TYPE, .Tag)) or_return
		_encode_u8(e.writer, 2, .Array) or_return

		vti := reflect.union_variant_type_info(v)
		#partial switch vt in vti.variant {
		case reflect.Type_Info_Named:
			err_conv(_encode_text(e, vt.name)) or_return
		case:
			builder := strings.builder_make(e.temp_allocator) or_return
			defer strings.builder_destroy(&builder)
			reflect.write_type(&builder, vti)
			err_conv(_encode_text(e, strings.to_string(builder))) or_return
		}

		return marshal_into(e, any{v.data, vti.id})

	case runtime.Type_Info_Bit_Set:
		// Store bit_set as big endian just like the protocol.
		do_byte_swap := !reflect.bit_set_is_big_endian(v)
		switch ti.size * 8 {
		case  0:
			return _encode_u8(e.writer, 0)
		case  8:
			x := (^u8)(v.data)^
			return _encode_u8(e.writer, x)
		case 16:
			x := (^u16)(v.data)^
			if do_byte_swap { x = intrinsics.byte_swap(x) }
			return err_conv(_encode_u16(e, x))
		case 32:
			x := (^u32)(v.data)^
			if do_byte_swap { x = intrinsics.byte_swap(x) }
			return err_conv(_encode_u32(e, x))
		case 64:
			x := (^u64)(v.data)^
			if do_byte_swap { x = intrinsics.byte_swap(x) }
			return err_conv(_encode_u64(e, x))
		case:
			panic("unknown bit_size size")
		}
	}

	return _unsupported(v.id, nil)
}
