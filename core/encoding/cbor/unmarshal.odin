package encoding_cbor

import "base:intrinsics"
import "base:runtime"

import "core:io"
import "core:mem"
import "core:reflect"
import "core:strings"
import "core:unicode/utf8"

/*
Unmarshals the given CBOR into the given pointer using reflection.
Types that require allocation are allocated using the given allocator.

Some temporary allocations are done on the given `temp_allocator`, but, if you want to,
this can be set to a "normal" allocator, because the necessary `delete` and `free` calls are still made.
This is helpful when the CBOR size is so big that you don't want to collect all the temporary allocations until the end.

Disable streaming/indeterminate lengths with the `.Disallow_Streaming` flag.

Shrink excess bytes in buffers and containers with the `.Shrink_Excess` flag.

Mark the input as trusted input with the `.Trusted_Input` flag, this turns off the safety feature
of not pre-allocating more than `max_pre_alloc` bytes before reading into the bytes. You should only
do this when you own both sides of the encoding and are sure there can't be malicious bytes used as
an input.
*/
unmarshal :: proc {
	unmarshal_from_reader,
	unmarshal_from_string,
}

unmarshal_from_reader :: proc(r: io.Reader, ptr: ^$T, flags := Decoder_Flags{}, allocator := context.allocator, temp_allocator := context.temp_allocator, loc := #caller_location) -> (err: Unmarshal_Error) {
	err = unmarshal_from_decoder(Decoder{ DEFAULT_MAX_PRE_ALLOC, flags, r }, ptr, allocator, temp_allocator, loc)

	// Normal EOF does not exist here, we try to read the exact amount that is said to be provided.
	if err == .EOF { err = .Unexpected_EOF }
	return
}

// Unmarshals from a string, see docs on the proc group `Unmarshal` for more info.
unmarshal_from_string :: proc(s: string, ptr: ^$T, flags := Decoder_Flags{}, allocator := context.allocator, temp_allocator := context.temp_allocator, loc := #caller_location) -> (err: Unmarshal_Error) {
	sr: strings.Reader
	r := strings.to_reader(&sr, s)

	err = unmarshal_from_reader(r, ptr, flags, allocator, temp_allocator, loc)

	// Normal EOF does not exist here, we try to read the exact amount that is said to be provided.
	if err == .EOF { err = .Unexpected_EOF }
	return
}

unmarshal_from_decoder :: proc(d: Decoder, ptr: ^$T, allocator := context.allocator, temp_allocator := context.temp_allocator, loc := #caller_location) -> (err: Unmarshal_Error) {
	d := d

	err = _unmarshal_any_ptr(d, ptr, nil, allocator, temp_allocator, loc)

	// Normal EOF does not exist here, we try to read the exact amount that is said to be provided.
	if err == .EOF { err = .Unexpected_EOF }
	return

}

_unmarshal_any_ptr :: proc(d: Decoder, v: any, hdr: Maybe(Header) = nil, allocator := context.allocator, temp_allocator := context.temp_allocator, loc := #caller_location) -> Unmarshal_Error {
	context.allocator = allocator
	context.temp_allocator = temp_allocator
	v := v

	if v == nil || v.id == nil {
		return .Invalid_Parameter
	}

	v = reflect.any_base(v)
	ti := type_info_of(v.id)
	if !reflect.is_pointer(ti) || ti.id == rawptr {
		return .Non_Pointer_Parameter
	}
	
	data := any{(^rawptr)(v.data)^, ti.variant.(reflect.Type_Info_Pointer).elem.id}	
	return _unmarshal_value(d, data, hdr.? or_else (_decode_header(d.reader) or_return), allocator, temp_allocator, loc)
}

_unmarshal_value :: proc(d: Decoder, v: any, hdr: Header, allocator := context.allocator, temp_allocator := context.temp_allocator, loc := #caller_location) -> (err: Unmarshal_Error) {
	v := v
	ti := reflect.type_info_base(type_info_of(v.id))
	r := d.reader

	// If it's a union with only one variant, then treat it as that variant
	if u, ok := ti.variant.(reflect.Type_Info_Union); ok && len(u.variants) == 1 {
		#partial switch hdr {
		case .Nil, .Undefined, nil: // no-op.
		case:
			variant := u.variants[0]
			v.id = variant.id
			ti = reflect.type_info_base(variant)
			if !reflect.is_pointer_internally(variant) {
				tag := any{rawptr(uintptr(v.data) + u.tag_offset), u.tag_type.id}
				assigned := _assign_int(tag, 1)
				assert(assigned)
			}
		}
	}

	// Allow generic unmarshal by doing it into a `Value`.
	switch &dst in v {
	case Value:
		dst = err_conv(_decode_from_decoder(d, hdr, allocator, loc)) or_return
		return
	}

	switch hdr {
	case .U8:
		decoded := _decode_u8(r) or_return
		if !_assign_int(v, decoded) { return _unsupported(v, hdr) }
		return

	case .U16:
		decoded := _decode_u16(r) or_return
		if !_assign_int(v, decoded) { return _unsupported(v, hdr) }
		return

	case .U32:
		decoded := _decode_u32(r) or_return
		if !_assign_int(v, decoded) { return _unsupported(v, hdr) }
		return

	case .U64:
		decoded := _decode_u64(r) or_return
		if !_assign_int(v, decoded) { return _unsupported(v, hdr) }
		return

	case .Neg_U8:
		decoded := Negative_U8(_decode_u8(r) or_return)
		
		switch &dst in v {
		case Negative_U8:
			dst = decoded
			return
		case Negative_U16:
			dst = Negative_U16(decoded)
			return
		case Negative_U32:
			dst = Negative_U32(decoded)
			return
		case Negative_U64:
			dst = Negative_U64(decoded)
			return
		}

		if reflect.is_unsigned(ti) { return _unsupported(v, hdr) }

		if !_assign_int(v, negative_to_int(decoded)) { return _unsupported(v, hdr) }
		return

	case .Neg_U16:
		decoded := Negative_U16(_decode_u16(r) or_return)
		
		switch &dst in v {
		case Negative_U16:
			dst = decoded
			return
		case Negative_U32:
			dst = Negative_U32(decoded)
			return
		case Negative_U64:
			dst = Negative_U64(decoded)
			return
		}

		if reflect.is_unsigned(ti) { return _unsupported(v, hdr) }

		if !_assign_int(v, negative_to_int(decoded)) { return _unsupported(v, hdr) }
		return

	case .Neg_U32:
		decoded := Negative_U32(_decode_u32(r) or_return)
		
		switch &dst in v {
		case Negative_U32:
			dst = decoded
			return
		case Negative_U64:
			dst = Negative_U64(decoded)
			return
		}

		if reflect.is_unsigned(ti) { return _unsupported(v, hdr) }

		if !_assign_int(v, negative_to_int(decoded)) { return _unsupported(v, hdr) }
		return

	case .Neg_U64:
		decoded := Negative_U64(_decode_u64(r) or_return)
		
		switch &dst in v {
		case Negative_U64:
			dst = decoded
			return
		}

		if reflect.is_unsigned(ti) { return _unsupported(v, hdr) }

		if !_assign_int(v, negative_to_int(decoded)) { return _unsupported(v, hdr) }
		return

	case .Simple:
		decoded := _decode_simple(r) or_return

		// NOTE: Because this is a special type and not to be treated as a general integer,
		// We only put the value of it in fields that are explicitly of type `Simple`.
		switch &dst in v {
		case Simple:
			dst = decoded
			return
		case:
			return _unsupported(v, hdr)
		}

	case .F16:
		decoded := _decode_f16(r) or_return
		if !_assign_float(v, decoded) { return _unsupported(v, hdr) }
		return

	case .F32:
		decoded := _decode_f32(r) or_return
		if !_assign_float(v, decoded) { return _unsupported(v, hdr) }
		return

	case .F64:
		decoded := _decode_f64(r) or_return
		if !_assign_float(v, decoded) { return _unsupported(v, hdr) }
		return

	case .True:
		if !_assign_bool(v, true) { return _unsupported(v, hdr) }
		return

	case .False:
		if !_assign_bool(v, false) { return _unsupported(v, hdr) }
		return
	
	case .Nil, .Undefined:
		mem.zero(v.data, ti.size)
		return

	case .Break:
		return .Break
	}
	
	maj, add := _header_split(hdr)
	switch maj {
	case .Unsigned:
		decoded := _decode_tiny_u8(add) or_return
		if !_assign_int(v, decoded) { return _unsupported(v, hdr, add) }
		return

	case .Negative:
		decoded := Negative_U8(_decode_tiny_u8(add) or_return)

		switch &dst in v {
		case Negative_U8:
			dst = decoded
			return
		}

		if reflect.is_unsigned(ti) { return _unsupported(v, hdr, add) }

		if !_assign_int(v, negative_to_int(decoded)) { return _unsupported(v, hdr, add) }
		return

	case .Other:
		decoded := _decode_tiny_simple(add) or_return

		 // NOTE: Because this is a special type and not to be treated as a general integer,
		 // We only put the value of it in fields that are explicitly of type `Simple`.
		switch &dst in v {
		case Simple:
			dst = decoded
			return
		case:
			return _unsupported(v, hdr, add)
		}

	case .Tag:
		switch &dst in v {
		case ^Tag:
			tval := err_conv(_decode_tag_ptr(d, add)) or_return
			if t, is_tag := tval.(^Tag); is_tag {
				dst = t
				return
			}

			destroy(tval)
			return .Bad_Tag_Value
		case Tag:
			t := err_conv(_decode_tag(d, add)) or_return
			if t, is_tag := t.?; is_tag {
				dst = t
				return
			}

			return .Bad_Tag_Value
		}

		nr := err_conv(_decode_uint_as_u64(r, add)) or_return

		// Custom tag implementations.
		if impl, ok := _tag_implementations_nr[nr]; ok {
			return impl->unmarshal(d, nr, v)
		} else if nr == TAG_OBJECT_TYPE {
			return _unmarshal_union(d, v, ti, hdr, loc=loc)
		} else {
			// Discard the tag info and unmarshal as its value.
			return _unmarshal_value(d, v, _decode_header(r) or_return)
		}

		return _unsupported(v, hdr, add)

	case .Bytes: return _unmarshal_bytes(d, v, ti, hdr, add, allocator=allocator, loc=loc)
	case .Text:  return _unmarshal_string(d, v, ti, hdr, add, allocator=allocator, loc=loc)
	case .Array: return _unmarshal_array(d, v, ti, hdr, add, allocator=allocator, loc=loc)
	case .Map:   return _unmarshal_map(d, v, ti, hdr, add, allocator=allocator, loc=loc)

	case:        return .Bad_Major
	}
}

_unmarshal_bytes :: proc(d: Decoder, v: any, ti: ^reflect.Type_Info, hdr: Header, add: Add, allocator := context.allocator, loc := #caller_location) -> (err: Unmarshal_Error) {
	#partial switch t in ti.variant {
	case reflect.Type_Info_String:
		bytes := err_conv(_decode_bytes(d, add, allocator=allocator, loc=loc)) or_return

		if t.is_cstring {
			raw  := (^cstring)(v.data)
			assert_safe_for_cstring(string(bytes))
			raw^  = cstring(raw_data(bytes))
		} else {
			// String has same memory layout as a slice, so we can directly use it as a slice.
			raw  := (^mem.Raw_String)(v.data)
			raw^  = transmute(mem.Raw_String)bytes
		}

		return

	case reflect.Type_Info_Slice:
		elem_base := reflect.type_info_base(t.elem)

		if elem_base.id != byte { return _unsupported(v, hdr) }

		bytes := err_conv(_decode_bytes(d, add, allocator=allocator, loc=loc)) or_return
		raw   := (^mem.Raw_Slice)(v.data)
		raw^   = transmute(mem.Raw_Slice)bytes
		return
		
	case reflect.Type_Info_Dynamic_Array:
		elem_base := reflect.type_info_base(t.elem)

		if elem_base.id != byte { return _unsupported(v, hdr) }
		
		bytes         := err_conv(_decode_bytes(d, add, allocator=allocator, loc=loc)) or_return
		raw           := (^mem.Raw_Dynamic_Array)(v.data)
		raw.data       = raw_data(bytes)
		raw.len        = len(bytes)
		raw.cap        = len(bytes)
		raw.allocator  = allocator
		return

	case reflect.Type_Info_Array:
		elem_base := reflect.type_info_base(t.elem)

		if elem_base.id != byte { return _unsupported(v, hdr) }

		bytes := err_conv(_decode_bytes(d, add, allocator=context.temp_allocator)) or_return
		defer delete(bytes, context.temp_allocator)

		if len(bytes) > t.count { return _unsupported(v, hdr) }
		
		// Copy into array type, delete original.
		slice := ([^]byte)(v.data)[:len(bytes)]
		n := copy(slice, bytes)
		assert(n == len(bytes))
		return
	}

	return _unsupported(v, hdr)
}

_unmarshal_string :: proc(d: Decoder, v: any, ti: ^reflect.Type_Info, hdr: Header, add: Add, allocator := context.allocator, temp_allocator := context.temp_allocator, loc := #caller_location) -> (err: Unmarshal_Error) {
	#partial switch t in ti.variant {
	case reflect.Type_Info_String:
		text := err_conv(_decode_text(d, add, allocator, loc)) or_return

		if t.is_cstring {
			raw := (^cstring)(v.data)

			assert_safe_for_cstring(text)
			raw^ = cstring(raw_data(text))
		} else {
			raw := (^string)(v.data)
			raw^ = text
		}
		return

	// Enum by its variant name.
	case reflect.Type_Info_Enum:
		text := err_conv(_decode_text(d, add, allocator=temp_allocator, loc=loc)) or_return
		defer delete(text, temp_allocator, loc)

		for name, i in t.names {
			if name == text {
				if !_assign_int(any{v.data, ti.id}, t.values[i]) { return _unsupported(v, hdr) }
				return
			}
		}
	
	case reflect.Type_Info_Rune:
		text := err_conv(_decode_text(d, add, allocator=temp_allocator, loc=loc)) or_return
		defer delete(text, temp_allocator, loc)

		r := (^rune)(v.data)
		dr, n := utf8.decode_rune(text)
		if dr == utf8.RUNE_ERROR || n < len(text) {
			return _unsupported(v, hdr)
		}

		r^ = dr
		return
	}

	return _unsupported(v, hdr)
}

_unmarshal_array :: proc(d: Decoder, v: any, ti: ^reflect.Type_Info, hdr: Header, add: Add, allocator := context.allocator, loc := #caller_location) -> (err: Unmarshal_Error) {
	assign_array :: proc(
		d: Decoder,
		da: ^mem.Raw_Dynamic_Array,
		elemt: ^reflect.Type_Info,
		length: int,
		growable := true,
		allocator := context.allocator,
		loc := #caller_location,
	) -> (out_of_space: bool, err: Unmarshal_Error) {
		for idx: uintptr = 0; length == -1 || idx < uintptr(length); idx += 1 {
			elem_ptr := rawptr(uintptr(da.data) + idx*uintptr(elemt.size))
			elem     := any{elem_ptr, elemt.id}

			hdr := _decode_header(d.reader) or_return
			
			// Double size if out of capacity.
			if da.cap <= da.len {
				// Not growable, error out.
				if !growable { return true, .Out_Of_Memory }

				cap := 2 * da.cap
				ok := runtime.__dynamic_array_reserve(da, elemt.size, elemt.align, cap, loc)
 				
				// NOTE: Might be lying here, but it is at least an allocator error.
				if !ok { return false, .Out_Of_Memory }
			}
			
			err = _unmarshal_value(d, elem, hdr, allocator=allocator, loc=loc)
			if length == -1 && err == .Break { break }
			if err != nil { return }

			da.len += 1
		}
		
		return false, nil
	}

	// Allow generically storing the values array.
	switch &dst in v {
	case ^Array:
		dst = err_conv(_decode_array_ptr(d, add, allocator=allocator, loc=loc)) or_return
		return
	case Array:
		dst = err_conv(_decode_array(d, add, allocator=allocator, loc=loc)) or_return
		return
	}

	#partial switch t in ti.variant {
	case reflect.Type_Info_Slice:
		length, scap := err_conv(_decode_len_container(d, add)) or_return

		data := mem.alloc_bytes_non_zeroed(t.elem.size * scap, t.elem.align, allocator=allocator, loc=loc) or_return
		defer if err != nil { mem.free_bytes(data, allocator=allocator, loc=loc) }

		da := mem.Raw_Dynamic_Array{raw_data(data), 0, length, context.allocator }

		assign_array(d, &da, t.elem, length) or_return

		if .Shrink_Excess in d.flags {
			// Ignoring an error here, but this is not critical to succeed.
			_ = runtime.__dynamic_array_shrink(&da, t.elem.size, t.elem.align, da.len, loc=loc)
		}

		raw      := (^mem.Raw_Slice)(v.data)
		raw.data  = da.data
		raw.len   = da.len
		return

	case reflect.Type_Info_Dynamic_Array:
		length, scap := err_conv(_decode_len_container(d, add)) or_return

		data := mem.alloc_bytes_non_zeroed(t.elem.size * scap, t.elem.align, loc=loc) or_return
		defer if err != nil { mem.free_bytes(data, allocator=allocator, loc=loc) }

		raw           := (^mem.Raw_Dynamic_Array)(v.data)
		raw.data       = raw_data(data) 
		raw.len        = 0
		raw.cap        = length
		raw.allocator  = context.allocator

		_ = assign_array(d, raw, t.elem, length) or_return

		if .Shrink_Excess in d.flags {
			// Ignoring an error here, but this is not critical to succeed.
			_ = runtime.__dynamic_array_shrink(raw, t.elem.size, t.elem.align, raw.len, loc=loc)
		}
		return

	case reflect.Type_Info_Array:
		length, _ := err_conv(_decode_len_container(d, add)) or_return
		if length > t.count {
			return _unsupported(v, hdr)
		}

		da := mem.Raw_Dynamic_Array{rawptr(v.data), 0, length, allocator }

		out_of_space := assign_array(d, &da, t.elem, length, growable=false) or_return
		if out_of_space { return _unsupported(v, hdr) }
		return

	case reflect.Type_Info_Enumerated_Array:
		length, _ := err_conv(_decode_len_container(d, add)) or_return
		if length > t.count {
			return _unsupported(v, hdr)
		}

		da := mem.Raw_Dynamic_Array{rawptr(v.data), 0, length, allocator }

		out_of_space := assign_array(d, &da, t.elem, length, growable=false) or_return
		if out_of_space { return _unsupported(v, hdr) }
		return

	case reflect.Type_Info_Complex:
		length, _ := err_conv(_decode_len_container(d, add)) or_return
		if length > 2 {
			return _unsupported(v, hdr)
		}

		da := mem.Raw_Dynamic_Array{rawptr(v.data), 0, 2, allocator }

		info: ^runtime.Type_Info
		switch ti.id {
		case complex32:  info = type_info_of(f16)
		case complex64:  info = type_info_of(f32)
		case complex128: info = type_info_of(f64)
		case:            unreachable()
		}

		out_of_space := assign_array(d, &da, info, 2, growable=false) or_return
		if out_of_space { return _unsupported(v, hdr) }
		return
	
	case reflect.Type_Info_Quaternion:
		length, _ := err_conv(_decode_len_container(d, add)) or_return
		if length > 4 {
			return _unsupported(v, hdr)
		}

		da := mem.Raw_Dynamic_Array{rawptr(v.data), 0, 4, allocator }

		info: ^runtime.Type_Info
		switch ti.id {
		case quaternion64:  info = type_info_of(f16)
		case quaternion128: info = type_info_of(f32)
		case quaternion256: info = type_info_of(f64)
		case:               unreachable()
		}

		out_of_space := assign_array(d, &da, info, 4, growable=false) or_return
		if out_of_space { return _unsupported(v, hdr) }
		return

	case: return _unsupported(v, hdr)
	}
}

_unmarshal_map :: proc(d: Decoder, v: any, ti: ^reflect.Type_Info, hdr: Header, add: Add, allocator := context.allocator, loc := #caller_location) -> (err: Unmarshal_Error) {
	r := d.reader
	decode_key :: proc(d: Decoder, v: any, allocator := context.allocator, loc := #caller_location) -> (k: string, err: Unmarshal_Error) {
		entry_hdr := _decode_header(d.reader) or_return
		entry_maj, entry_add := _header_split(entry_hdr)
		#partial switch entry_maj {
		case .Text:
			k = err_conv(_decode_text(d, entry_add, allocator=allocator, loc=loc)) or_return
			return
		case .Bytes:
			bytes := err_conv(_decode_bytes(d, entry_add, allocator=allocator, loc=loc)) or_return
			k = string(bytes)
			return
		case:
			err = _unsupported(v, entry_hdr)
			return
		}
	}

	// Allow generically storing the map array.
	switch &dst in v {
	case ^Map:
		dst = err_conv(_decode_map_ptr(d, add, allocator=allocator, loc=loc)) or_return
		return
	case Map:
		dst = err_conv(_decode_map(d, add, allocator=allocator, loc=loc)) or_return
		return
	}

	#partial switch t in ti.variant {
	case reflect.Type_Info_Struct:
		if .raw_union in t.flags {
			return _unsupported(v, hdr)
		}

		length, _ := err_conv(_decode_len_container(d, add)) or_return
		unknown := length == -1
		fields := reflect.struct_fields_zipped(ti.id)

		for idx := 0; idx < len(fields) && (unknown || idx < length); idx += 1 {
			// Decode key, keys can only be strings.
			key: string
			if keyv, kerr := decode_key(d, v, context.temp_allocator); unknown && kerr == .Break {
				break
			} else if kerr != nil {
				err = kerr
				return
			} else {
				key = keyv
			}
			defer delete(key, context.temp_allocator)

			// Find matching field.
			use_field_idx := -1
			{
				for field, field_idx in fields {
					tag_value := string(reflect.struct_tag_get(field.tag, "cbor"))
					if tag_value == "-" {
						continue
					}

					if key == tag_value {
						use_field_idx = field_idx
						break
					}

					if key == field.name {
						// No break because we want to still check remaining struct tags.
						use_field_idx = field_idx
					}
				}
				
				// Skips unused map entries.
				if use_field_idx < 0 {
					continue
				}
			}

			field := fields[use_field_idx]
			// name  := field.name
			ptr   := rawptr(uintptr(v.data) + field.offset)
			fany  := any{ptr, field.type.id}
			_unmarshal_value(d, fany, _decode_header(r) or_return) or_return
		}
		return

	case reflect.Type_Info_Map:
		if !reflect.is_string(t.key) {
			return _unsupported(v, hdr)
		}

		raw_map := (^mem.Raw_Map)(v.data)
		if raw_map.allocator.procedure == nil {
			raw_map.allocator = context.allocator
		}

		defer if err != nil {
			_ = runtime.map_free_dynamic(raw_map^, t.map_info)
		}

		length, scap := err_conv(_decode_len_container(d, add)) or_return
		unknown := length == -1
		if !unknown {
			// Reserve space before setting so we can return allocation errors and be efficient on big maps.
			new_len := uintptr(min(scap, runtime.map_len(raw_map^)+length))
			runtime.map_reserve_dynamic(raw_map, t.map_info, new_len) or_return
		}
		
		// Temporary memory to unmarshal keys into before inserting them into the map.
		elem_backing := mem.alloc_bytes_non_zeroed(t.value.size, t.value.align, context.temp_allocator) or_return
		defer delete(elem_backing, context.temp_allocator)

		map_backing_value := any{raw_data(elem_backing), t.value.id}

		for idx := 0; unknown || idx < length; idx += 1 {
			// Decode key, keys can only be strings.
			key: string
			if keyv, kerr := decode_key(d, v); unknown && kerr == .Break {
				break
			} else if kerr != nil {
				err = kerr
				return
			} else {
				key = keyv
			}

			if unknown || idx > scap {
				// Reserve space for new element so we can return allocator errors.
				new_len := uintptr(runtime.map_len(raw_map^)+1)
				runtime.map_reserve_dynamic(raw_map, t.map_info, new_len) or_return
			}

			mem.zero_slice(elem_backing)
			_unmarshal_value(d, map_backing_value, _decode_header(r) or_return) or_return

			key_ptr := rawptr(&key)
			key_cstr: cstring
			if reflect.is_cstring(t.key) {
				assert_safe_for_cstring(key)
				key_cstr = cstring(raw_data(key))
				key_ptr = &key_cstr
			}

			set_ptr := runtime.__dynamic_map_set_without_hash(raw_map, t.map_info, key_ptr, map_backing_value.data)
			// We already reserved space for it, so this shouldn't fail.
			assert(set_ptr != nil)
		}
	
		if .Shrink_Excess in d.flags {
			_, _ = runtime.map_shrink_dynamic(raw_map, t.map_info)
		}
		return

		case:
			return _unsupported(v, hdr)
	}
}

// Unmarshal into a union, based on the `TAG_OBJECT_TYPE` tag of the spec, it denotes a tag which
// contains an array of exactly two elements, the first is a textual representation of the following
// CBOR value's type.
_unmarshal_union :: proc(d: Decoder, v: any, ti: ^reflect.Type_Info, hdr: Header, loc := #caller_location) -> (err: Unmarshal_Error) {
	r := d.reader
	#partial switch t in ti.variant {
	case reflect.Type_Info_Union:
		idhdr: Header
		target_name: string
		{
			vhdr := _decode_header(r) or_return
			vmaj, vadd := _header_split(vhdr)
			if vmaj != .Array {
				return .Bad_Tag_Value
			}

			n_items, _ := err_conv(_decode_len_container(d, vadd)) or_return
			if n_items != 2 {
				return .Bad_Tag_Value
			}
			
			idhdr = _decode_header(r) or_return
			idmaj, idadd := _header_split(idhdr)
			if idmaj != .Text {
				return .Bad_Tag_Value
			}

			target_name = err_conv(_decode_text(d, idadd, context.temp_allocator)) or_return
		}
		defer delete(target_name, context.temp_allocator)

		for variant, i in t.variants {
			tag := i64(i)
			if !t.no_nil {
				tag += 1
			}

			#partial switch vti in variant.variant {
			case reflect.Type_Info_Named:
				if vti.name == target_name {
					reflect.set_union_variant_raw_tag(v, tag)
					return _unmarshal_value(d, any{v.data, variant.id}, _decode_header(r) or_return, loc=loc)
				}

			case:
				builder := strings.builder_make(context.temp_allocator)
				defer strings.builder_destroy(&builder)

				reflect.write_type(&builder, variant)
				variant_name := strings.to_string(builder)
				
				if variant_name == target_name {
					reflect.set_union_variant_raw_tag(v, tag)
					return _unmarshal_value(d, any{v.data, variant.id}, _decode_header(r) or_return, loc=loc)
				}
			}
		}

		// No variant matched.
		return _unsupported(v, idhdr)

	case:
		// Not a union.
		return _unsupported(v, hdr)
	}
}

_assign_int :: proc(val: any, i: $T) -> bool {
	v := reflect.any_core(val)

	// NOTE: should under/over flow be checked here? `encoding/json` doesn't, but maybe that is a
	// less strict encoding?.

	switch &dst in v {
	case i8:      dst = i8     (i)
	case i16:     dst = i16    (i)
	case i16le:   dst = i16le  (i)
	case i16be:   dst = i16be  (i)
	case i32:     dst = i32    (i)
	case i32le:   dst = i32le  (i)
	case i32be:   dst = i32be  (i)
	case i64:     dst = i64    (i)
	case i64le:   dst = i64le  (i)
	case i64be:   dst = i64be  (i)
	case i128:    dst = i128   (i)
	case i128le:  dst = i128le (i)
	case i128be:  dst = i128be (i)
	case u8:      dst = u8     (i)
	case u16:     dst = u16    (i)
	case u16le:   dst = u16le  (i)
	case u16be:   dst = u16be  (i)
	case u32:     dst = u32    (i)
	case u32le:   dst = u32le  (i)
	case u32be:   dst = u32be  (i)
	case u64:     dst = u64    (i)
	case u64le:   dst = u64le  (i)
	case u64be:   dst = u64be  (i)
	case u128:    dst = u128   (i)
	case u128le:  dst = u128le (i)
	case u128be:  dst = u128be (i)
	case int:     dst = int    (i)
	case uint:    dst = uint   (i)
	case uintptr: dst = uintptr(i)
	case:
		ti := type_info_of(v.id)
		if _, ok := ti.variant.(runtime.Type_Info_Bit_Set); ok {
			do_byte_swap := !reflect.bit_set_is_big_endian(v)
			switch ti.size * 8 {
			case 0: // no-op.
			case 8:
				x := (^u8)(v.data)
				x^ = u8(i)
			case 16:
				x := (^u16)(v.data)
				x^ = do_byte_swap ? intrinsics.byte_swap(u16(i)) : u16(i)
			case 32:
				x := (^u32)(v.data)
				x^ = do_byte_swap ? intrinsics.byte_swap(u32(i)) : u32(i)
			case 64:
				x := (^u64)(v.data)
				x^ = do_byte_swap ? intrinsics.byte_swap(u64(i)) : u64(i)
			case:
				panic("unknown bit_size size")
			}
			return true
		}
		return false
	}
	return true
}

_assign_float :: proc(val: any, f: $T) -> bool {
	v := reflect.any_core(val)

	// NOTE: should under/over flow be checked here? `encoding/json` doesn't, but maybe that is a
	// less strict encoding?.

	switch &dst in v {
	case f16:     dst = f16  (f)
	case f16le:   dst = f16le(f)
	case f16be:   dst = f16be(f)
	case f32:     dst = f32  (f)
	case f32le:   dst = f32le(f)
	case f32be:   dst = f32be(f)
	case f64:     dst = f64  (f)
	case f64le:   dst = f64le(f)
	case f64be:   dst = f64be(f)
	
	case complex32:  dst = complex(f16(f), 0)
	case complex64:  dst = complex(f32(f), 0)
	case complex128: dst = complex(f64(f), 0)
	
	case quaternion64:  dst = quaternion(w=f16(f), x=0, y=0, z=0)
	case quaternion128: dst = quaternion(w=f32(f), x=0, y=0, z=0)
	case quaternion256: dst = quaternion(w=f64(f), x=0, y=0, z=0)
	
	case: return false
	}
	return true
}

_assign_bool :: proc(val: any, b: bool) -> bool {
	v := reflect.any_core(val)
	switch &dst in v {
	case bool: dst = bool(b)
	case b8:   dst = b8  (b)
	case b16:  dst = b16 (b)
	case b32:  dst = b32 (b)
	case b64:  dst = b64 (b)
	case: return false
	}
	return true
}

// Sanity check that the decoder added a nil byte to the end.
@(private, disabled=ODIN_DISABLE_ASSERT)
assert_safe_for_cstring :: proc(s: string, loc := #caller_location) {
	assert(([^]byte)(raw_data(s))[len(s)] == 0, loc = loc)
}
