package encoding_cbor

import "base:intrinsics"

import "core:encoding/json"
import "core:encoding/hex"
import "core:io"
import "core:mem"
import "core:strconv"
import "core:strings"

// If we are decoding a stream of either a map or list, the initial capacity will be this value.
INITIAL_STREAMED_CONTAINER_CAPACITY :: 8

// If we are decoding a stream of either text or bytes, the initial capacity will be this value.
INITIAL_STREAMED_BYTES_CAPACITY :: 16

// The default maximum amount of bytes to allocate on a buffer/container at once to prevent
// malicious input from causing massive allocations.
DEFAULT_MAX_PRE_ALLOC :: mem.Kilobyte

// Known/common headers are defined, undefined headers can still be valid.
// Higher 3 bits is for the major type and lower 5 bits for the additional information.
Header :: enum u8 {
	U8  = (u8(Major.Unsigned) << 5) | u8(Add.One_Byte),
	U16 = (u8(Major.Unsigned) << 5) | u8(Add.Two_Bytes),
	U32 = (u8(Major.Unsigned) << 5) | u8(Add.Four_Bytes),
	U64 = (u8(Major.Unsigned) << 5) | u8(Add.Eight_Bytes),

	Neg_U8  = (u8(Major.Negative) << 5) | u8(Add.One_Byte),
	Neg_U16 = (u8(Major.Negative) << 5) | u8(Add.Two_Bytes),
	Neg_U32 = (u8(Major.Negative) << 5) | u8(Add.Four_Bytes),
	Neg_U64 = (u8(Major.Negative) << 5) | u8(Add.Eight_Bytes),

	False = (u8(Major.Other) << 5) | u8(Add.False),
	True  = (u8(Major.Other) << 5) | u8(Add.True),

	Nil       = (u8(Major.Other) << 5) | u8(Add.Nil),
	Undefined = (u8(Major.Other) << 5) | u8(Add.Undefined),

	Simple = (u8(Major.Other) << 5) | u8(Add.One_Byte),

	F16 = (u8(Major.Other) << 5) | u8(Add.Two_Bytes),
	F32 = (u8(Major.Other) << 5) | u8(Add.Four_Bytes),
	F64 = (u8(Major.Other) << 5) | u8(Add.Eight_Bytes),

	Break = (u8(Major.Other) << 5) | u8(Add.Break),
}

// The higher 3 bits of the header which denotes what type of value it is.
Major :: enum u8 {
	Unsigned,
	Negative,
	Bytes,
	Text,
	Array,
	Map,
	Tag,
	Other,
}

// The lower 3 bits of the header which denotes additional information for the type of value.
Add :: enum u8 {
	False     = 20,
	True      = 21,
	Nil       = 22,
	Undefined = 23,

	One_Byte    = 24,
	Two_Bytes   = 25,
	Four_Bytes  = 26,
	Eight_Bytes = 27,

	Length_Unknown = 31,
	Break          = Length_Unknown,
}

Value :: union {
	u8,
	u16,
	u32,
	u64,

	Negative_U8,
	Negative_U16,
	Negative_U32,
	Negative_U64,
	
	// Pointers so the size of the Value union stays small.
	^Bytes,
	^Text,
	^Array,
	^Map,
	^Tag,

	Simple,
	f16,
	f32,
	f64,
	bool,
	Undefined,
	Nil,
}

Bytes :: []byte
Text :: string

Array :: []Value

Map :: []Map_Entry
Map_Entry :: struct {
	key:   Value, // Can be any unsigned, negative, float, Simple, bool, Text.
	value: Value,
}

Tag :: struct {
	number: Tag_Number,
	value:  Value, // Value based on the number.
}

Tag_Number :: u64

Nil       :: distinct rawptr
Undefined :: distinct rawptr

// A distinct atom-like number, range from `0..=19` and `32..=max(u8)`.
Simple :: distinct u8
Atom   :: Simple

Unmarshal_Error :: union #shared_nil {
	io.Error,
	mem.Allocator_Error,
	Decode_Data_Error,
	Unmarshal_Data_Error,
	Maybe(Unsupported_Type_Error),
}

Marshal_Error :: union #shared_nil {
	io.Error,
	mem.Allocator_Error,
	Encode_Data_Error,
	Marshal_Data_Error,
	Maybe(Unsupported_Type_Error),
}

Decode_Error :: union #shared_nil {
	io.Error,
	mem.Allocator_Error,
	Decode_Data_Error,
}

Encode_Error :: union #shared_nil {
	io.Error,
	mem.Allocator_Error,
	Encode_Data_Error,
}

Decode_Data_Error :: enum {
	None,
	Bad_Major,                // An invalid major type was encountered.
	Bad_Argument,             // A general unexpected value (most likely invalid additional info in header).
	Bad_Tag_Value,            // When the type of value for the given tag is not valid.
	Nested_Indefinite_Length, // When an streamed/indefinite length container nests another, this is not allowed.
	Nested_Tag,               // When a tag's value is another tag, this is not allowed.
	Length_Too_Big,           // When the length of a container (map, array, bytes, string) is more than `max(int)`.
	Disallowed_Streaming,     // When the `.Disallow_Streaming` flag is set and a streaming header is encountered.
	Break,                    // When the `break` header was found without any stream to break off.
}

Encode_Data_Error :: enum {
	None,
	Invalid_Simple, // When a simple is being encoded that is out of the range `0..=19` and `32..=max(u8)`.
	Int_Too_Big,    // When an int is being encoded that is larger than `max(u64)` or smaller than `min(u64)`.
	Bad_Tag_Value,  // When the type of value is not supported by the tag implementation.
}

Unmarshal_Data_Error :: enum {
	None,
	Invalid_Parameter,     // When the given `any` can not be unmarshalled into.
	Non_Pointer_Parameter, // When the given `any` is not a pointer.
}

Marshal_Data_Error :: enum {
	None,
	Invalid_CBOR_Tag, // When the struct tag `cbor_tag:""` is not a registered name or number.
}

// Error that is returned when a type couldn't be marshalled into or out of, as much information
// as possible/available is added.
Unsupported_Type_Error :: struct {
	id:  typeid,
	hdr: Header,
	add: Add,
}

_unsupported :: proc(v: any, hdr: Header, add: Add = nil) -> Maybe(Unsupported_Type_Error) {
	return Unsupported_Type_Error{
		id = v.id,
		hdr = hdr,
		add = add,
	}
}

// Actual value is `-1 - x` (be careful of overflows).

Negative_U8  :: distinct u8
Negative_U16 :: distinct u16
Negative_U32 :: distinct u32
Negative_U64 :: distinct u64

// Turns the CBOR negative unsigned int type into a signed integer type.
negative_to_int :: proc {
	negative_u8_to_int,
	negative_u16_to_int,
	negative_u32_to_int,
	negative_u64_to_int,
}

negative_u8_to_int :: #force_inline proc(u: Negative_U8) -> i16 {
	return -1 - i16(u)
}

negative_u16_to_int :: #force_inline proc(u: Negative_U16) -> i32 {
	return -1 - i32(u)
}

negative_u32_to_int :: #force_inline proc(u: Negative_U32) -> i64 {
	return -1 - i64(u)
}

negative_u64_to_int :: #force_inline proc(u: Negative_U64) -> i128 {
	return -1 - i128(u)
}

// Utility for converting between the different errors when they are subsets of the other.
err_conv :: proc {
	encode_to_marshal_err,
	encode_to_marshal_err_p2,
	decode_to_unmarshal_err,
	decode_to_unmarshal_err_p,
	decode_to_unmarshal_err_p2,
}

encode_to_marshal_err :: #force_inline proc(err: Encode_Error) -> Marshal_Error {
	switch e in err {
	case nil:                 return nil
	case io.Error:            return e
	case mem.Allocator_Error: return e
	case Encode_Data_Error:   return e
	case:                     return nil
	}
}

encode_to_marshal_err_p2 :: #force_inline proc(v: $T, v2: $T2, err: Encode_Error) -> (T, T2, Marshal_Error) {
	return v, v2, err_conv(err)
}

decode_to_unmarshal_err :: #force_inline proc(err: Decode_Error) -> Unmarshal_Error {
	switch e in err {
	case nil:                 return nil
	case io.Error:            return e
	case mem.Allocator_Error: return e
	case Decode_Data_Error:   return e
	case:                     return nil
	}
}

decode_to_unmarshal_err_p :: #force_inline proc(v: $T, err: Decode_Error) -> (T, Unmarshal_Error) {
	return v, err_conv(err)
}

decode_to_unmarshal_err_p2 :: #force_inline proc(v: $T, v2: $T2, err: Decode_Error) -> (T, T2, Unmarshal_Error) {
	return v, v2, err_conv(err)
}

// Recursively frees all memory allocated when decoding the passed value.
destroy :: proc(val: Value, allocator := context.allocator) {
	context.allocator = allocator
	#partial switch v in val {
	case ^Map:
		if v == nil { return }
		for entry in v {
			destroy(entry.key)
			destroy(entry.value)
		}
		delete(v^)
		free(v)
	case ^Array:
		if v == nil { return }
		for entry in v {
			destroy(entry)
		}
		delete(v^)
		free(v)
	case ^Text:
		if v == nil { return }
		delete(v^)
		free(v)
	case ^Bytes:
		if v == nil { return }
		delete(v^)
		free(v)
	case ^Tag:
		if v == nil { return }
		destroy(v.value)
		free(v)
	}
}

/*
to_diagnostic_format either writes or returns a human-readable representation of the value,
optionally formatted, defined as the diagnostic format in [[RFC 8949 Section 8;https://www.rfc-editor.org/rfc/rfc8949.html#name-diagnostic-notation]].

Incidentally, if the CBOR does not contain any of the additional types defined on top of JSON
this will also be valid JSON.
*/
to_diagnostic_format :: proc {
	to_diagnostic_format_string,
	to_diagnostic_format_writer,
}

// Turns the given CBOR value into a human-readable string.
// See docs on the proc group `diagnose` for more info.
to_diagnostic_format_string :: proc(val: Value, padding := 0, allocator := context.allocator, loc := #caller_location) -> (string, mem.Allocator_Error) #optional_allocator_error {
	b := strings.builder_make(allocator, loc)
	w := strings.to_stream(&b)
	err := to_diagnostic_format_writer(w, val, padding)
	if err == .EOF {
		// The string builder stream only returns .EOF, and only if it can't write (out of memory).
		return "", .Out_Of_Memory
	}
	assert(err == nil)

	return strings.to_string(b), nil
}

// Writes the given CBOR value into the writer as human-readable text.
// See docs on the proc group `diagnose` for more info.
to_diagnostic_format_writer :: proc(w: io.Writer, val: Value, padding := 0) -> io.Error {
	@(require_results)
	indent :: proc(padding: int) -> int {
		padding := padding
		if padding != -1 {
			padding += 1
		}
		return padding
	}

	@(require_results)
	dedent :: proc(padding: int) -> int {
		padding := padding
		if padding != -1 {
			padding -= 1
		}
		return padding
	}

	comma :: proc(w: io.Writer, padding: int) -> io.Error {
		_ = io.write_string(w, ", " if padding == -1 else ",") or_return
		return nil
	}

	newline :: proc(w: io.Writer, padding: int) -> io.Error {
		if padding != -1 {
			io.write_string(w, "\n") or_return
			for _ in 0..<padding {
				io.write_string(w, "\t") or_return
			}
		}
		return nil
	}

	padding := padding
	switch v in val {
	case u8:  io.write_uint(w, uint(v)) or_return
	case u16: io.write_uint(w, uint(v)) or_return
	case u32: io.write_uint(w, uint(v)) or_return
	case u64: io.write_u64(w, v) or_return
	case Negative_U8:  io.write_int(w, int(negative_to_int(v))) or_return
	case Negative_U16: io.write_int(w, int(negative_to_int(v))) or_return
	case Negative_U32: io.write_int(w, int(negative_to_int(v))) or_return
	case Negative_U64: io.write_i128(w, i128(negative_to_int(v))) or_return

	// NOTE: not using io.write_float because it removes the sign, 
	// which we want for the diagnostic format.
	case f16:
		buf: [64]byte
		str := strconv.append_float(buf[:], f64(v), 'f', 2*size_of(f16), 8*size_of(f16))
		if str[0] == '+' && str != "+Inf" { str = str[1:] }
		io.write_string(w, str) or_return
	case f32:
		buf: [128]byte
		str := strconv.append_float(buf[:], f64(v), 'f', 2*size_of(f32), 8*size_of(f32))
		if str[0] == '+' && str != "+Inf" { str = str[1:] }
		io.write_string(w, str) or_return
	case f64:
		buf: [256]byte
		str := strconv.append_float(buf[:], f64(v), 'f', 2*size_of(f64), 8*size_of(f64))
		if str[0] == '+' && str != "+Inf" { str = str[1:] }
		io.write_string(w, str) or_return

	case bool: io.write_string(w, "true" if v else "false") or_return
	case Nil: io.write_string(w, "null") or_return
	case Undefined: io.write_string(w, "undefined") or_return
	case ^Bytes:
		io.write_string(w, "h'") or_return
		hex.encode_into_writer(w, v^) or_return
		io.write_string(w, "'") or_return
	case ^Text:
		io.write_string(w, `"`) or_return
		io.write_string(w, v^) or_return
		io.write_string(w, `"`) or_return
	case ^Array:
		if v == nil || len(v) == 0 {
			io.write_string(w, "[]") or_return
			return nil
		}

		io.write_string(w, "[") or_return

		padding = indent(padding)
		newline(w, padding) or_return

		for entry, i in v {
			to_diagnostic_format(w, entry, padding) or_return
			if i != len(v)-1 {
				comma(w, padding) or_return
				newline(w, padding) or_return
			}
		}

		padding = dedent(padding)
		newline(w, padding) or_return

		io.write_string(w, "]") or_return
	case ^Map:
		if v == nil || len(v) == 0 {
			io.write_string(w, "{}") or_return
			return nil
		}

		io.write_string(w, "{") or_return

		padding = indent(padding)
		newline(w, padding) or_return

		for entry, i in v {
			to_diagnostic_format(w, entry.key, padding) or_return
			io.write_string(w, ": ") or_return
			to_diagnostic_format(w, entry.value, padding) or_return
			if i != len(v)-1 {
				comma(w, padding) or_return
				newline(w, padding) or_return
			}
		}

		padding = dedent(padding)
		newline(w, padding) or_return

		io.write_string(w, "}") or_return
	case ^Tag:
		io.write_u64(w, v.number) or_return
		io.write_string(w, "(") or_return
		to_diagnostic_format(w, v.value, padding) or_return
		io.write_string(w, ")") or_return
	case Simple:
		io.write_string(w, "simple(") or_return
		io.write_uint(w, uint(v)) or_return
		io.write_string(w, ")") or_return
	}
	return nil
}

/*
Converts from JSON to CBOR.

Everything is copied to the given allocator, the passed in JSON value can be deleted after.
*/
from_json :: proc(val: json.Value, allocator := context.allocator) -> (Value, mem.Allocator_Error) #optional_allocator_error {
	internal :: proc(val: json.Value) -> (ret: Value, err: mem.Allocator_Error) {
		switch v in val {
		case json.Null: return Nil{}, nil
		case json.Integer:
			i, major := _int_to_uint(v)
			#partial switch major {
			case .Unsigned: return i, nil
			case .Negative: return Negative_U64(i), nil
			case:           unreachable()
			}
		case json.Float:   return v, nil
		case json.Boolean: return v, nil
		case json.String:
			container := new(Text) or_return

			// We need the string to have a nil byte at the end so we clone to cstring.
			container^ = string(strings.clone_to_cstring(v) or_return)
			return container, nil
		case json.Array:
			arr  := new(Array) or_return
			arr^  = make([]Value, len(v)) or_return
			for _, i in arr {
				arr[i] = internal(v[i]) or_return
			}
			return arr, nil
		case json.Object:
			m  := new(Map) or_return
			dm := make([dynamic]Map_Entry, 0, len(v)) or_return
			for mkey, mval in v {
				append(&dm, Map_Entry{from_json(mkey) or_return, from_json(mval) or_return})
			}
			m^ = dm[:]
			return m, nil
		}
		return nil, nil
	}

	context.allocator = allocator
	return internal(val)
}

/*
Converts from CBOR to JSON.

NOTE: overflow on integers or floats is not handled.

Everything is copied to the given allocator, the passed in CBOR value can be `destroy`'ed after.

If a CBOR map with non-string keys is encountered it is turned into an array of tuples.
*/
to_json :: proc(val: Value, allocator := context.allocator) -> (json.Value, mem.Allocator_Error) #optional_allocator_error {
	internal :: proc(val: Value) -> (ret: json.Value, err: mem.Allocator_Error) {
		switch v in val {
		case Simple: return json.Integer(v), nil

		case u8:  return json.Integer(v), nil
		case u16: return json.Integer(v), nil
		case u32: return json.Integer(v), nil
		case u64: return json.Integer(v), nil

		case Negative_U8:  return json.Integer(negative_to_int(v)), nil
		case Negative_U16: return json.Integer(negative_to_int(v)), nil
		case Negative_U32: return json.Integer(negative_to_int(v)), nil
		case Negative_U64: return json.Integer(negative_to_int(v)), nil

		case f16: return json.Float(v), nil
		case f32: return json.Float(v), nil
		case f64: return json.Float(v), nil

		case bool: return json.Boolean(v), nil

		case Undefined: return json.Null{}, nil
		case Nil:       return json.Null{}, nil

		case ^Bytes: return json.String(strings.clone(string(v^)) or_return), nil
		case ^Text:  return json.String(strings.clone(v^) or_return),         nil

		case ^Map:
			keys_all_strings :: proc(m: ^Map) -> bool {
				for entry in m {
					#partial switch kv in entry.key {
					case ^Bytes:
					case ^Text:
					case: return false
					}
				}
				return true
			}

			if keys_all_strings(v) {
				obj := make(json.Object, len(v)) or_return
				for entry in v {
					k: string
					#partial switch kv in entry.key {
					case ^Bytes: k = string(kv^)
					case ^Text:  k = kv^
					case:        unreachable()
					}

					v := internal(entry.value) or_return
					obj[k] = v
				}
				return obj, nil
			} else {
				// Resort to an array of tuples if keys aren't all strings.
				arr := make(json.Array, 0, len(v)) or_return
				for entry in v {
					entry_arr := make(json.Array, 0, 2) or_return
					append(&entry_arr, internal(entry.key) or_return) or_return
					append(&entry_arr, internal(entry.value) or_return) or_return
					append(&arr, entry_arr) or_return
				}
				return arr, nil
			}

		case ^Array:
			arr := make(json.Array, 0, len(v)) or_return
			for entry in v {
				append(&arr, internal(entry) or_return) or_return
			}
			return arr, nil

		case ^Tag:
			obj := make(json.Object, 2) or_return
			obj[strings.clone("number") or_return] = internal(v.number) or_return
			obj[strings.clone("value") or_return]  = internal(v.value) or_return
			return obj, nil

		case: return json.Null{}, nil
		}
	}

	context.allocator = allocator
	return internal(val)
}

_int_to_uint :: proc {
	_i8_to_uint,
	_i16_to_uint,
	_i32_to_uint,
	_i64_to_uint,
	_i128_to_uint,
}

_u128_to_u64 :: #force_inline proc(v: u128) -> (u64, Encode_Data_Error) {
	if v > u128(max(u64)) {
		return 0, .Int_Too_Big
	}

	return u64(v), nil
}

_i8_to_uint :: #force_inline proc(v: i8) -> (u: u8, m: Major) {
	if v < 0 {
		return u8(abs(v)-1), .Negative
	}

	return u8(v), .Unsigned
}

_i16_to_uint :: #force_inline proc(v: i16) -> (u: u16, m: Major) {
	if v < 0 {
		return u16(abs(v)-1), .Negative
	}

	return u16(v), .Unsigned
}

_i32_to_uint :: #force_inline proc(v: i32) -> (u: u32, m: Major) {
	if v < 0 {
		return u32(abs(v)-1), .Negative
	}

	return u32(v), .Unsigned
}

_i64_to_uint :: #force_inline proc(v: i64) -> (u: u64, m: Major) {
	if v < 0 {
		return u64(abs(v)-1), .Negative
	}

	return u64(v), .Unsigned
}

_i128_to_uint :: proc(v: i128) -> (u: u64, m: Major, err: Encode_Data_Error) {
	if v < 0 {
		m = .Negative
		u, err = _u128_to_u64(u128(abs(v) - 1))
		return
	}

	m = .Unsigned
	u, err = _u128_to_u64(u128(v))
	return
}
