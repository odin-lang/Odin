package cbor

import "core:bytes"
import "core:encoding/endian"
import "core:intrinsics"
import "core:io"
import "core:slice"
import "core:strings"

Encoder_Flag :: enum {
	// CBOR defines a tag header that also acts as a file/binary header,
	// this way decoders can check the first header of the binary and see if it is CBOR.
	Self_Described_CBOR,

	// Integers are stored in the smallest integer type it fits.
	// This involves checking each int against the max of all its smaller types.
	Deterministic_Int_Size,

	// Floats are stored in the smallest size float type without losing precision.
	// This involves casting each float down to its smaller types and checking if it changed.
	Deterministic_Float_Size,

	// Sort maps by their keys in bytewise lexicographic order of their deterministic encoding.
	// NOTE: In order to do this, all keys of a map have to be pre-computed, sorted, and
	// then written, this involves temporary allocations for the keys and a copy of the map itself.
	Deterministic_Map_Sorting, 
	
	// Internal flag to do initialization.
	_In_Progress,
}

Encoder_Flags :: bit_set[Encoder_Flag]

// Flags for fully deterministic output (if you are not using streaming/indeterminate length).
ENCODE_FULLY_DETERMINISTIC :: Encoder_Flags{.Deterministic_Int_Size, .Deterministic_Float_Size, .Deterministic_Map_Sorting}
// Flags for the smallest encoding output.
ENCODE_SMALL               :: Encoder_Flags{.Deterministic_Int_Size, .Deterministic_Float_Size}
// Flags for the fastest encoding output.
ENCODE_FAST                :: Encoder_Flags{}

Encoder :: struct {
	flags:  Encoder_Flags,
	writer: io.Writer,
}

/*
Decodes both deterministic and non-deterministic CBOR into a `Value` variant.

`Text` and `Bytes` can safely be cast to cstrings because of an added 0 byte.

Allocations are done using the given allocator,
*no* allocations are done on the `context.temp_allocator`.

A value can be (fully and recursively) deallocated using the `destroy` proc in this package.
*/
decode :: proc {
	decode_string,
	decode_reader,
}

// Decodes the given string as CBOR.
// See docs on the proc group `decode` for more information.
decode_string :: proc(s: string, allocator := context.allocator) -> (v: Value, err: Decode_Error) {
	context.allocator = allocator

	r: strings.Reader
	strings.reader_init(&r, s)
	return decode(strings.reader_to_stream(&r), allocator=allocator)
}

// Reads a CBOR value from the given reader.
// See docs on the proc group `decode` for more information.
decode_reader :: proc(r: io.Reader, hdr: Header = Header(0), allocator := context.allocator) -> (v: Value, err: Decode_Error) {
	context.allocator = allocator
	
	hdr := hdr
	if hdr == Header(0) { hdr = _decode_header(r) or_return }
	switch hdr {
	case .U8:  return _decode_u8 (r)
	case .U16: return _decode_u16(r)
	case .U32: return _decode_u32(r)
	case .U64: return _decode_u64(r)

	case .Neg_U8:  return Negative_U8 (_decode_u8 (r) or_return), nil
	case .Neg_U16: return Negative_U16(_decode_u16(r) or_return), nil
	case .Neg_U32: return Negative_U32(_decode_u32(r) or_return), nil
	case .Neg_U64: return Negative_U64(_decode_u64(r) or_return), nil

	case .Simple: return _decode_simple(r)

	case .F16: return _decode_f16(r)
	case .F32: return _decode_f32(r)
	case .F64: return _decode_f64(r)

	case .True:  return true, nil
	case .False: return false, nil
	
	case .Nil:       return Nil{}, nil
	case .Undefined: return Undefined{}, nil

	case .Break: return nil, .Break
	}

	maj, add := _header_split(hdr)
	switch maj {
	case .Unsigned: return _decode_tiny_u8(add)
	case .Negative: return Negative_U8(_decode_tiny_u8(add) or_return), nil
	case .Bytes:    return _decode_bytes_ptr(r, add)
	case .Text:     return _decode_text_ptr(r, add)
	case .Array:    return _decode_array_ptr(r, add)
	case .Map:      return _decode_map_ptr(r, add)
	case .Tag:      return _decode_tag_ptr(r, add)
	case .Other:    return _decode_tiny_simple(add)
	case:           return nil, .Bad_Major
	}
}

/*
Encodes the CBOR value into a binary CBOR.

Flags can be used to control the output (mainly determinism, which coincidently affects size).

The default flags `ENCODE_SMALL` (`.Deterministic_Int_Size`, `.Deterministic_Float_Size`) will try
to put ints and floats into their smallest possible byte size without losing equality.

Adding the `.Self_Described_CBOR` flag will wrap the value in a tag that lets generic decoders know
the contents are CBOR from just reading the first byte.

Adding the `.Deterministic_Map_Sorting` flag will sort the encoded maps by the byte content of the
encoded key. This flag has a cost on performance and memory efficiency because all keys in a map
have to be precomputed, sorted and only then written to the output.

Empty flags will do nothing extra to the value.

The allocations for the `.Deterministic_Map_Sorting` flag are done using the `context.temp_allocator`
but are followed by the necessary `delete` and `free` calls if the allocator supports them.
This is helpful when the CBOR size is so big that you don't want to collect all the temporary
allocations until the end.
*/
encode_into :: proc {
	encode_into_bytes,
	encode_into_builder,
	encode_into_writer,
	encode_into_encoder,
}
encode :: encode_into

// Encodes the CBOR value into binary CBOR allocated on the given allocator.
// See the docs on the proc group `encode_into` for more info.
encode_into_bytes :: proc(v: Value, flags := ENCODE_SMALL, allocator := context.allocator) -> (data: []byte, err: Encode_Error) {
	b := strings.builder_make(allocator) or_return
	encode_into_builder(&b, v, flags) or_return
	return b.buf[:], nil
}

// Encodes the CBOR value into binary CBOR written to the given builder.
// See the docs on the proc group `encode_into` for more info.
encode_into_builder :: proc(b: ^strings.Builder, v: Value, flags := ENCODE_SMALL) -> Encode_Error {
	return encode_into_writer(strings.to_stream(b), v, flags)
}

// Encodes the CBOR value into binary CBOR written to the given writer.
// See the docs on the proc group `encode_into` for more info.
encode_into_writer :: proc(w: io.Writer, v: Value, flags := ENCODE_SMALL) -> Encode_Error {
	return encode_into_encoder(Encoder{flags, w}, v)
}

// Encodes the CBOR value into binary CBOR written to the given encoder.
// See the docs on the proc group `encode_into` for more info.
encode_into_encoder :: proc(e: Encoder, v: Value) -> Encode_Error {
	e := e
	
	outer: bool
	defer if outer {
		e.flags &~= {._In_Progress}
	}

	if ._In_Progress not_in e.flags {
		outer = true
		e.flags |= {._In_Progress}

		if .Self_Described_CBOR in e.flags {
			_encode_u64(e, TAG_SELF_DESCRIBED_CBOR, .Tag) or_return
		}
	}

	switch v_spec in v {
	case u8:           return _encode_u8(e.writer, v_spec, .Unsigned)
	case u16:          return _encode_u16(e, v_spec, .Unsigned)
	case u32:          return _encode_u32(e, v_spec, .Unsigned)
	case u64:          return _encode_u64(e, v_spec, .Unsigned)
	case Negative_U8:  return _encode_u8(e.writer, u8(v_spec), .Negative)
	case Negative_U16: return _encode_u16(e, u16(v_spec), .Negative)
	case Negative_U32: return _encode_u32(e, u32(v_spec), .Negative)
	case Negative_U64: return _encode_u64(e, u64(v_spec), .Negative)
	case ^Bytes:       return _encode_bytes(e, v_spec^)
	case ^Text:        return _encode_text(e, v_spec^)
	case ^Array:       return _encode_array(e, v_spec^)
	case ^Map:         return _encode_map(e, v_spec^)
	case ^Tag:         return _encode_tag(e, v_spec^)
	case Simple:       return _encode_simple(e.writer, v_spec)
	case f16:          return _encode_f16(e.writer, v_spec)
	case f32:          return _encode_f32(e, v_spec)
	case f64:          return _encode_f64(e, v_spec)
	case bool:         return _encode_bool(e.writer, v_spec)
	case Nil:          return _encode_nil(e.writer)
	case Undefined:    return _encode_undefined(e.writer)
	case:              return nil
	}
}

_decode_header :: proc(r: io.Reader) -> (hdr: Header, err: io.Error) {
	buf: [1]byte
	io.read_full(r, buf[:]) or_return
	return Header(buf[0]), nil
}

_header_split :: proc(hdr: Header) -> (Major, Add) {
	return Major(u8(hdr) >> 5), Add(u8(hdr) & 0x1f)
}

_decode_u8 :: proc(r: io.Reader) -> (v: u8, err: io.Error) {
	byte: [1]byte
	io.read_full(r, byte[:]) or_return
	return byte[0], nil
}

_encode_uint :: proc {
	_encode_u8,
	_encode_u16,
	_encode_u32,
	_encode_u64,
}

_encode_u8 :: proc(w: io.Writer, v: u8, major: Major = .Unsigned) -> (err: io.Error) {
	header := u8(major) << 5
	if v < u8(Add.One_Byte) {
		header |= v
		_, err = io.write_full(w, {header})
		return
	}

	header |= u8(Add.One_Byte)
	_, err = io.write_full(w, {header, v})
	return
}

_decode_tiny_u8 :: proc(additional: Add) -> (u8, Decode_Data_Error) {
	if intrinsics.expect(additional < .One_Byte, true) {
		return u8(additional), nil
	}

	return 0, .Bad_Argument
}

_decode_u16 :: proc(r: io.Reader) -> (v: u16, err: io.Error) {
	bytes: [2]byte
	io.read_full(r, bytes[:]) or_return
	return endian.unchecked_get_u16be(bytes[:]), nil
}

_encode_u16 :: proc(e: Encoder, v: u16, major: Major = .Unsigned) -> Encode_Error {
	if .Deterministic_Int_Size in e.flags {
		return _encode_deterministic_uint(e.writer, v, major)
	}
	return _encode_u16_exact(e.writer, v, major)
}

_encode_u16_exact :: proc(w: io.Writer, v: u16, major: Major = .Unsigned) -> (err: io.Error) {
	bytes: [3]byte
	bytes[0] = (u8(major) << 5) | u8(Add.Two_Bytes)
	endian.unchecked_put_u16be(bytes[1:], v)
	_, err = io.write_full(w, bytes[:])
	return
}

_decode_u32 :: proc(r: io.Reader) -> (v: u32, err: io.Error) {
	bytes: [4]byte
	io.read_full(r, bytes[:]) or_return
	return endian.unchecked_get_u32be(bytes[:]), nil
}

_encode_u32 :: proc(e: Encoder, v: u32, major: Major = .Unsigned) -> Encode_Error {
	if .Deterministic_Int_Size in e.flags {
		return _encode_deterministic_uint(e.writer, v, major)
	}
	return _encode_u32_exact(e.writer, v, major)
}

_encode_u32_exact :: proc(w: io.Writer, v: u32, major: Major = .Unsigned) -> (err: io.Error) {
	bytes: [5]byte
	bytes[0] = (u8(major) << 5) | u8(Add.Four_Bytes)
	endian.unchecked_put_u32be(bytes[1:], v)
	_, err = io.write_full(w, bytes[:])
	return
}

_decode_u64 :: proc(r: io.Reader) -> (v: u64, err: io.Error) {
	bytes: [8]byte
	io.read_full(r, bytes[:]) or_return
	return endian.unchecked_get_u64be(bytes[:]), nil
}

_encode_u64 :: proc(e: Encoder, v: u64, major: Major = .Unsigned) -> Encode_Error {
	if .Deterministic_Int_Size in e.flags {
		return _encode_deterministic_uint(e.writer, v, major)
	}
	return _encode_u64_exact(e.writer, v, major)
}

_encode_u64_exact :: proc(w: io.Writer, v: u64, major: Major = .Unsigned) -> (err: io.Error) {
	bytes: [9]byte
	bytes[0] = (u8(major) << 5) | u8(Add.Eight_Bytes)
	endian.unchecked_put_u64be(bytes[1:], v)
	_, err = io.write_full(w, bytes[:])
	return
}

_decode_bytes_ptr :: proc(r: io.Reader, add: Add, type: Major = .Bytes) -> (v: ^Bytes, err: Decode_Error) {
	v = new(Bytes) or_return
	defer if err != nil { free(v) }

	v^ = _decode_bytes(r, add, type) or_return
	return
}

_decode_bytes :: proc(r: io.Reader, add: Add, type: Major = .Bytes) -> (v: Bytes, err: Decode_Error) {
	_n_items, length_is_unknown := _decode_container_length(r, add) or_return

	n_items := _n_items.? or_else INITIAL_STREAMED_BYTES_CAPACITY

	if length_is_unknown {
		buf: strings.Builder
		buf.buf = make([dynamic]byte, 0, n_items) or_return
		defer if err != nil { strings.builder_destroy(&buf) }

		buf_stream := strings.to_stream(&buf)

		for {
			header   := _decode_header(r) or_return
			maj, add := _header_split(header)

			#partial switch maj {
			case type:
				_n_items, length_is_unknown := _decode_container_length(r, add) or_return
				if length_is_unknown {
					return nil, .Nested_Indefinite_Length
				}
				n_items := i64(_n_items.?)

				copied := io.copy_n(buf_stream, r, n_items) or_return
				assert(copied == n_items)
					
			case .Other:
				if add != .Break { return nil, .Bad_Argument }
				
				v = buf.buf[:]
 				
				// Write zero byte so this can be converted to cstring.
				io.write_full(buf_stream, {0}) or_return
				shrink(&buf.buf) // Ignoring error, this is not critical to succeed.
				return

			case:
				return nil, .Bad_Major
			}
		}
	} else {
		v = make([]byte, n_items + 1) or_return // Space for the bytes and a zero byte.
		defer if err != nil { delete(v) }

		io.read_full(r, v[:n_items]) or_return

		v = v[:n_items] // Take off zero byte.
		return
	}
}

_encode_bytes :: proc(e: Encoder, val: Bytes, major: Major = .Bytes) -> (err: Encode_Error) {
	assert(len(val) >= 0)
	_encode_u64(e, u64(len(val)), major) or_return
    _, err = io.write_full(e.writer, val[:])
	return
}

_decode_text_ptr :: proc(r: io.Reader, add: Add) -> (v: ^Text, err: Decode_Error) {
	v = new(Text) or_return
	defer if err != nil { free(v) }

	v^ = _decode_text(r, add) or_return
	return
}

_decode_text :: proc(r: io.Reader, add: Add) -> (v: Text, err: Decode_Error) {
	return (Text)(_decode_bytes(r, add, .Text) or_return), nil
}

_encode_text :: proc(e: Encoder, val: Text) -> Encode_Error {
    return _encode_bytes(e, transmute([]byte)val, .Text)
}

_decode_array_ptr :: proc(r: io.Reader, add: Add) -> (v: ^Array, err: Decode_Error) {
	v = new(Array) or_return
	defer if err != nil { free(v) }

	v^ = _decode_array(r, add) or_return
	return
}

_decode_array :: proc(r: io.Reader, add: Add) -> (v: Array, err: Decode_Error) {
	_n_items, length_is_unknown := _decode_container_length(r, add) or_return
	n_items := _n_items.? or_else INITIAL_STREAMED_CONTAINER_CAPACITY

	array := make([dynamic]Value, 0, n_items) or_return
	defer if err != nil {
		for entry in array { destroy(entry) }
		delete(array)
	}
	
	for i := 0; length_is_unknown || i < n_items; i += 1 {
		val, verr := decode(r)
		if length_is_unknown && verr == .Break {
			break
		} else if verr != nil {
			err = verr
			return
		}

		append(&array, val) or_return
	}
	
	shrink(&array)
	v = array[:]
	return
}

_encode_array :: proc(e: Encoder, arr: Array) -> Encode_Error {
	assert(len(arr) >= 0)
	_encode_u64(e, u64(len(arr)), .Array)
    for val in arr {
        encode(e, val) or_return
    }
    return nil
}

_decode_map_ptr :: proc(r: io.Reader, add: Add) -> (v: ^Map, err: Decode_Error) {
	v = new(Map) or_return
	defer if err != nil { free(v) }

	v^ = _decode_map(r, add) or_return
	return
}

_decode_map :: proc(r: io.Reader, add: Add) -> (v: Map, err: Decode_Error) {
	_n_items, length_is_unknown := _decode_container_length(r, add) or_return
	n_items := _n_items.? or_else INITIAL_STREAMED_CONTAINER_CAPACITY
	
	items := make([dynamic]Map_Entry, 0, n_items) or_return
	defer if err != nil { 
		for entry in items {
			destroy(entry.key)
			destroy(entry.value)
		}
		delete(items)
	}

	for i := 0; length_is_unknown || i < n_items; i += 1 {
		key, kerr := decode(r)
		if length_is_unknown && kerr == .Break {
			break
		} else if kerr != nil {
			return nil, kerr
		} 

		value := decode(r) or_return

		append(&items, Map_Entry{
			key   = key,
			value = value,
		}) or_return
	}
	
	shrink(&items)
	v = items[:]
	return
}

_encode_map :: proc(e: Encoder, m: Map) -> (err: Encode_Error) {
	assert(len(m) >= 0)
	_encode_u64(e, u64(len(m)), .Map) or_return
	
	if .Deterministic_Map_Sorting not_in e.flags {
		for entry in m {
			encode(e, entry.key)   or_return
			encode(e, entry.value) or_return
		}
		return
	}

	// Deterministic_Map_Sorting needs us to sort the entries by the byte contents of the
	// encoded key.
	//
	// This means we have to store and sort them before writing incurring extra (temporary) allocations.

	Map_Entry_With_Key :: struct {
		encoded_key: []byte,
		entry:       Map_Entry,
	}

	entries := make([]Map_Entry_With_Key, len(m), context.temp_allocator) or_return
	defer delete(entries, context.temp_allocator)

	for &entry, i in entries {
		entry.entry = m[i]

		buf := strings.builder_make(0, 8, context.temp_allocator) or_return
		
		ke := e
		ke.writer = strings.to_stream(&buf)

		encode(ke, entry.entry.key) or_return
		entry.encoded_key = buf.buf[:]
	}
	
	// Sort lexicographic on the bytes of the key.
	slice.sort_by_cmp(entries, proc(a, b: Map_Entry_With_Key) -> slice.Ordering {
		return slice.Ordering(bytes.compare(a.encoded_key, b.encoded_key))
	})

	for entry in entries {
		io.write_full(e.writer, entry.encoded_key) or_return
		delete(entry.encoded_key, context.temp_allocator)

		encode(e, entry.entry.value) or_return
	}

    return nil
}

_decode_tag_ptr :: proc(r: io.Reader, add: Add) -> (v: Value, err: Decode_Error) {
	tag := _decode_tag(r, add) or_return
	if t, ok := tag.?; ok {
		defer if err != nil { destroy(t.value) }
		tp := new(Tag) or_return
		tp^ = t
		return tp, nil
	}

	// no error, no tag, this was the self described CBOR tag, skip it.
	return decode(r)
}

_decode_tag :: proc(r: io.Reader, add: Add) -> (v: Maybe(Tag), err: Decode_Error) {
	num := _decode_tag_nr(r, add) or_return

	// CBOR can be wrapped in a tag that decoders can use to see/check if the binary data is CBOR.
	// We can ignore it here.
	if num == TAG_SELF_DESCRIBED_CBOR {
		return
	}

	t := Tag{
		number = num,
		value = decode(r) or_return,
	}

	if nested, ok := t.value.(^Tag); ok {
		destroy(nested)
		return nil, .Nested_Tag
	}

	return t, nil
}

_decode_tag_nr :: proc(r: io.Reader, add: Add) -> (nr: Tag_Number, err: Decode_Error) {
	#partial switch add {
	case .One_Byte:    return u64(_decode_u8(r) or_return), nil
	case .Two_Bytes:   return u64(_decode_u16(r) or_return), nil
	case .Four_Bytes:  return u64(_decode_u32(r) or_return), nil
	case .Eight_Bytes: return u64(_decode_u64(r) or_return), nil
	case:              return u64(_decode_tiny_u8(add) or_return), nil
	}
}

_encode_tag :: proc(e: Encoder, val: Tag) -> Encode_Error {
	_encode_u64(e, val.number, .Tag) or_return
    return encode(e, val.value)
}

_decode_simple :: proc(r: io.Reader) -> (v: Simple, err: io.Error) {
	buf: [1]byte
	io.read_full(r, buf[:]) or_return
	return Simple(buf[0]), nil
}

_encode_simple :: proc(w: io.Writer, v: Simple) -> (err: Encode_Error) {
	header := u8(Major.Other) << 5

	if v < Simple(Add.False) {
		header |= u8(v)
		_, err = io.write_full(w, {header})
		return
	} else if v <= Simple(Add.Break) {
		return .Invalid_Simple
	}
	
	header |= u8(Add.One_Byte)
	_, err = io.write_full(w, {header, u8(v)})
	return
}

_decode_tiny_simple :: proc(add: Add) -> (Simple, Decode_Data_Error) {
	if add < Add.False {
		return Simple(add), nil
	}
	
	return 0, .Bad_Argument
}

_decode_f16 :: proc(r: io.Reader) -> (v: f16, err: io.Error) {
	bytes: [2]byte
	io.read_full(r, bytes[:]) or_return
	n := endian.unchecked_get_u16be(bytes[:])
	return transmute(f16)n, nil
}

_encode_f16 :: proc(w: io.Writer, v: f16) -> (err: io.Error) {
	bytes: [3]byte
	bytes[0] = u8(Header.F16)
	endian.unchecked_put_u16be(bytes[1:], transmute(u16)v)
	_, err = io.write_full(w, bytes[:])
	return
}

_decode_f32 :: proc(r: io.Reader) -> (v: f32, err: io.Error) {
	bytes: [4]byte
	io.read_full(r, bytes[:]) or_return
	n := endian.unchecked_get_u32be(bytes[:])
	return transmute(f32)n, nil
}

_encode_f32 :: proc(e: Encoder, v: f32) -> io.Error {
	if .Deterministic_Float_Size in e.flags {
		return _encode_deterministic_float(e.writer, v)
	}
	return _encode_f32_exact(e.writer, v)
}

_encode_f32_exact :: proc(w: io.Writer, v: f32) -> (err: io.Error) {
	bytes: [5]byte
	bytes[0] = u8(Header.F32)
	endian.unchecked_put_u32be(bytes[1:], transmute(u32)v)
	_, err = io.write_full(w, bytes[:])
	return
}

_decode_f64 :: proc(r: io.Reader) -> (v: f64, err: io.Error) {
	bytes: [8]byte
	io.read_full(r, bytes[:]) or_return
	n := endian.unchecked_get_u64be(bytes[:])
	return transmute(f64)n, nil
}

_encode_f64 :: proc(e: Encoder, v: f64) -> io.Error {
	if .Deterministic_Float_Size in e.flags {
		return _encode_deterministic_float(e.writer, v)
	}
	return _encode_f64_exact(e.writer, v)
}

_encode_f64_exact :: proc(w: io.Writer, v: f64) -> (err: io.Error) {
	bytes: [9]byte
	bytes[0] = u8(Header.F64)
	endian.unchecked_put_u64be(bytes[1:], transmute(u64)v)
	_, err = io.write_full(w, bytes[:])
	return
}

_encode_bool :: proc(w: io.Writer, v: bool) -> (err: io.Error) {
	switch v {
	case true:  _, err = io.write_full(w, {u8(Header.True )}); return
	case false: _, err = io.write_full(w, {u8(Header.False)}); return
	case:       unreachable()
	}
}

_encode_undefined :: proc(w: io.Writer) -> io.Error {
	_, err := io.write_full(w, {u8(Header.Undefined)})
	return err
}

_encode_nil :: proc(w: io.Writer) -> io.Error {
	_, err := io.write_full(w, {u8(Header.Nil)})
	return err
}

// Streaming

encode_stream_begin :: proc(w: io.Writer, major: Major) -> (err: io.Error) {
    assert(major >= Major(.Bytes) && major <= Major(.Map), "illegal stream type")

    header := (u8(major) << 5) | u8(Add.Length_Unknown)
    _, err = io.write_full(w, {header})
	return
}

encode_stream_end :: proc(w: io.Writer) -> io.Error {
    header := (u8(Major.Other) << 5) | u8(Add.Break)
    _, err := io.write_full(w, {header})
	return err
}

encode_stream_bytes      :: _encode_bytes
encode_stream_text       :: _encode_text
encode_stream_array_item :: encode

encode_stream_map_entry :: proc(e: Encoder, key: Value, val: Value) -> Encode_Error {
    encode(e, key) or_return
    return encode(e, val)
}

//

_decode_container_length :: proc(r: io.Reader, add: Add) -> (length: Maybe(int), is_unknown: bool, err: Decode_Error) {
	if add == Add.Length_Unknown { return nil, true, nil }
	#partial switch add {
	case .One_Byte:  length = int(_decode_u8(r) or_return)
	case .Two_Bytes: length = int(_decode_u16(r) or_return)
	case .Four_Bytes:
		big_length := _decode_u32(r) or_return
		if u64(big_length) > u64(max(int)) {
			err = .Length_Too_Big
			return
		}
		length = int(big_length)
	case .Eight_Bytes:
		big_length := _decode_u64(r) or_return
		if big_length > u64(max(int)) {
			err = .Length_Too_Big
			return
		}
		length = int(big_length)
	case:
		length = int(_decode_tiny_u8(add) or_return)
	}
	return
}

// Deterministic encoding is (among other things) encoding all values into their smallest
// possible representation.
// See section 4 of RFC 8949.

_encode_deterministic_uint :: proc {
	_encode_u8,
	_encode_deterministic_u16,
	_encode_deterministic_u32,
	_encode_deterministic_u64,
	_encode_deterministic_u128,
}

_encode_deterministic_u16 :: proc(w: io.Writer, v: u16, major: Major = .Unsigned) -> Encode_Error {
	switch {
	case v <= u16(max(u8)): return _encode_u8(w, u8(v), major)
	case:                   return _encode_u16_exact(w, v, major)
	}
}

_encode_deterministic_u32 :: proc(w: io.Writer, v: u32, major: Major = .Unsigned) -> Encode_Error {
	switch {
	case v <= u32(max(u8)):  return _encode_u8(w, u8(v), major)
	case v <= u32(max(u16)): return _encode_u16_exact(w, u16(v), major)
	case:                    return _encode_u32_exact(w, u32(v), major)
	}
}

_encode_deterministic_u64 :: proc(w: io.Writer, v: u64, major: Major = .Unsigned) -> Encode_Error {
	switch {
	case v <= u64(max(u8)):  return _encode_u8(w, u8(v), major)
	case v <= u64(max(u16)): return _encode_u16_exact(w, u16(v), major)
	case v <= u64(max(u32)): return _encode_u32_exact(w, u32(v), major)
	case:                    return _encode_u64_exact(w, u64(v), major)
	}
}

_encode_deterministic_u128 :: proc(w: io.Writer, v: u128, major: Major = .Unsigned) -> Encode_Error {
	switch {
	case v <= u128(max(u8)):  return _encode_u8(w, u8(v), major)
	case v <= u128(max(u16)): return _encode_u16_exact(w, u16(v), major)
	case v <= u128(max(u32)): return _encode_u32_exact(w, u32(v), major)
	case v <= u128(max(u64)): return _encode_u64_exact(w, u64(v), major)
	case:                     return .Int_Too_Big
	}
}

_encode_deterministic_negative :: #force_inline proc(w: io.Writer, v: $T) -> Encode_Error
	where T == Negative_U8 || T == Negative_U16 || T == Negative_U32 || T == Negative_U64 {
	return _encode_deterministic_uint(w, v, .Negative)
}

// A Deterministic float is a float in the smallest type that stays the same after down casting.
_encode_deterministic_float :: proc {
	_encode_f16,
	_encode_deterministic_f32,
	_encode_deterministic_f64,
}

_encode_deterministic_f32 :: proc(w: io.Writer, v: f32) -> io.Error {
	if (f32(f16(v)) == v) {
		return _encode_f16(w, f16(v))
	}

	return _encode_f32_exact(w, v)
}

_encode_deterministic_f64 :: proc(w: io.Writer, v: f64) -> io.Error {
	if (f64(f16(v)) == v) {
		return _encode_f16(w, f16(v))
	}

	if (f64(f32(v)) == v) {
		return _encode_f32_exact(w, f32(v))
	}

	return _encode_f64_exact(w, v)
}
