package cbor

import "core:encoding/base64"
import "core:io"
import "core:math"
import "core:math/big"
import "core:mem"
import "core:reflect"
import "core:runtime"
import "core:strings"
import "core:time"

// Tags defined in RFC 7049 that we provide implementations for.

// UTC time in seconds, unmarshalled into a `core:time` `time.Time` or integer.
TAG_EPOCH_TIME_NR :: 1
TAG_EPOCH_TIME_ID :: "epoch"

// Using `core:math/big`, big integers are properly encoded and decoded during marshal and unmarshal.
TAG_UNSIGNED_BIG_NR     :: 2
// Using `core:math/big`, big integers are properly encoded and decoded during marshal and unmarshal.
TAG_NEGATIVE_BIG_NR     :: 3

// TAG_DECIMAL_FRACTION :: 4  // NOTE: We could probably implement this with `math/fixed`.

// Sometimes it is beneficial to carry an embedded CBOR data item that is not meant to be decoded
// immediately at the time the enclosing data item is being decoded. Tag number 24 (CBOR data item)
// can be used to tag the embedded byte string as a single data item encoded in CBOR format.
TAG_CBOR_NR :: 24
TAG_CBOR_ID :: "cbor"

// The contents of this tag are base64 encoded during marshal and decoded during unmarshal.
TAG_BASE64_NR :: 34
TAG_BASE64_ID :: "base64"

// A tag that is used to detect the contents of a binary buffer (like a file) are CBOR.
// This tag would wrap everything else, decoders can then check for this header and see if the
// given content is definitely CBOR.
TAG_SELF_DESCRIBED_CBOR :: 55799

// A tag implementation that handles marshals and unmarshals for the tag it is registered on.
Tag_Implementation :: struct {
	data:      rawptr,
	unmarshal: Tag_Unmarshal_Proc,
	marshal:   Tag_Marshal_Proc,
}

// Procedure responsible for umarshalling the tag out of the reader into the given `any`.
Tag_Unmarshal_Proc :: #type proc(self: ^Tag_Implementation, r: io.Reader, tag_nr: Tag_Number, v: any) -> Unmarshal_Error

// Procedure responsible for marshalling the tag in the given `any` into the given encoder.
Tag_Marshal_Proc   :: #type proc(self: ^Tag_Implementation, e: Encoder, v: any) -> Marshal_Error

// When encountering a tag in the CBOR being unmarshalled, the implementation is used to unmarshal it.
// When encountering a struct tag like `cbor_tag:"Tag_Number"`, the implementation is used to marshal it. 
_tag_implementations_nr: map[Tag_Number]Tag_Implementation

// Same as the number implementations but friendlier to use as a struct tag.
// Instead of `cbor_tag:"34"` you can use `cbor_tag:"base64"`.
_tag_implementations_id: map[string]Tag_Implementation

// Tag implementations that are always used by a type, if that type is encountered in marshal it
// will rely on the implementation to marshal it.
//
// This is good for types that don't make sense or can't marshal in its default form.
_tag_implementations_type: map[typeid]Tag_Implementation

// Register a custom tag implementation to be used when marshalling that type and unmarshalling that tag number.
tag_register_type :: proc(impl: Tag_Implementation, nr: Tag_Number, type: typeid) {
	_tag_implementations_nr[nr] = impl
	_tag_implementations_type[type] = impl
}

// Register a custom tag implementation to be used when marshalling that tag number or marshalling
// a field with the struct tag `cbor_tag:"nr"`.
tag_register_number :: proc(impl: Tag_Implementation, nr: Tag_Number, id: string) {
	_tag_implementations_nr[nr] = impl
	_tag_implementations_id[id] = impl
}

// Controls initialization of default tag implementations.
// JS and WASI default to a panic allocator so we don't want to do it on those.
INITIALIZE_DEFAULT_TAGS :: #config(CBOR_INITIALIZE_DEFAULT_TAGS, ODIN_OS != .JS && ODIN_OS != .WASI)

@(private, init, disabled=!INITIALIZE_DEFAULT_TAGS)
tags_initialize_defaults :: proc() {
	tags_register_defaults()
}

// Registers tags that have implementations provided by this package.
// This is done by default and can be controlled with the `CBOR_INITIALIZE_DEFAULT_TAGS` define.
tags_register_defaults :: proc() {
	// NOTE: Not registering this the other way around, user can opt-in using the `cbor_tag:"1"` struct
	// tag instead, it would lose precision and marshalling the `time.Time` struct normally is valid.
	tag_register_number({nil, tag_time_unmarshal, tag_time_marshal}, TAG_EPOCH_TIME_NR, TAG_EPOCH_TIME_ID)
	
	// Use the struct tag `cbor_tag:"34"` to have your field encoded in a base64.
	tag_register_number({nil, tag_base64_unmarshal, tag_base64_marshal}, TAG_BASE64_NR, TAG_BASE64_ID)

	// Use the struct tag `cbor_tag:"24"` to keep a non-decoded field of raw CBOR.
	tag_register_number({nil, tag_cbor_unmarshal, tag_cbor_marshal}, TAG_CBOR_NR, TAG_CBOR_ID)

	// These following tags are registered at the type level and don't require an opt-in struct tag.
	// Encoding these types on its own make no sense or no data is lost to encode it.

	tag_register_type({nil, tag_big_unmarshal, tag_big_marshal}, TAG_UNSIGNED_BIG_NR, big.Int)
	tag_register_type({nil, tag_big_unmarshal, tag_big_marshal}, TAG_NEGATIVE_BIG_NR, big.Int)
}

// Tag number 1 contains a numerical value counting the number of seconds from 1970-01-01T00:00Z
// in UTC time to the represented point in civil time.
//
// See RFC 8949 section 3.4.2.
@(private)
tag_time_unmarshal :: proc(_: ^Tag_Implementation, r: io.Reader, _: Tag_Number, v: any) -> (err: Unmarshal_Error) {
	hdr := _decode_header(r) or_return
	#partial switch hdr {
	case .U8, .U16, .U32, .U64, .Neg_U8, .Neg_U16, .Neg_U32, .Neg_U64:
		switch &dst in v {
		case time.Time:
			i: i64
			_unmarshal_any_ptr(r, &i, hdr) or_return
			dst = time.unix(i64(i), 0)
			return
		case:
			return _unmarshal_value(r, v, hdr)
		}

	case .F16, .F32, .F64:
		switch &dst in v {
		case time.Time:
			f: f64
			_unmarshal_any_ptr(r, &f, hdr) or_return
			whole, fract := math.modf(f)
			dst = time.unix(i64(whole), i64(fract * 1e9))
			return
		case:
			return _unmarshal_value(r, v, hdr)
		}

	case:
		maj, add := _header_split(hdr)
		if maj == .Other {
			i := _decode_tiny_u8(add) or_return

			switch &dst in v {
			case time.Time:
				dst = time.unix(i64(i), 0)
			case:
				if _assign_int(v, i) { return }
			}
		}

		// Only numbers and floats are allowed in this tag.
		return .Bad_Tag_Value
	}

	return _unsupported(v, hdr)
}

@(private)
tag_time_marshal :: proc(_: ^Tag_Implementation, e: Encoder, v: any) -> Marshal_Error {
	switch vv in v {
	case time.Time:
		// NOTE: we lose precision here, which is one of the reasons for this tag being opt-in.
		i := time.time_to_unix(vv)

		_encode_u8(e.writer, TAG_EPOCH_TIME_NR, .Tag) or_return
		return err_conv(_encode_uint(e, _int_to_uint(i)))
	case:
		unreachable()
	}
}

@(private)
tag_big_unmarshal :: proc(_: ^Tag_Implementation, r: io.Reader, tnr: Tag_Number, v: any) -> (err: Unmarshal_Error) {
	hdr := _decode_header(r) or_return
	maj, add := _header_split(hdr)
	if maj != .Bytes {
		// Only bytes are supported in this tag.
		return .Bad_Tag_Value
	}

	switch &dst in v {
	case big.Int:
		bytes := err_conv(_decode_bytes(r, add)) or_return
		defer delete(bytes)

		if err := big.int_from_bytes_big(&dst, bytes); err != nil {
			return .Bad_Tag_Value
		}

		if tnr ==  TAG_NEGATIVE_BIG_NR {
			dst.sign = .Negative
		}

		return
	}

	return _unsupported(v, hdr)
}

@(private)
tag_big_marshal :: proc(_: ^Tag_Implementation, e: Encoder, v: any) -> Marshal_Error {
	switch &vv in v {
	case big.Int:
		if !big.int_is_initialized(&vv) {
			_encode_u8(e.writer, TAG_UNSIGNED_BIG_NR, .Tag) or_return
			return _encode_u8(e.writer, 0, .Bytes)
		}

		// NOTE: using the panic_allocator because all procedures should only allocate if the Int
		// is uninitialized (which we checked).

		is_neg, err := big.is_negative(&vv, mem.panic_allocator())
		assert(err == nil, "only errors if not initialized, which has been checked")
		
		tnr: u8 = TAG_NEGATIVE_BIG_NR if is_neg else TAG_UNSIGNED_BIG_NR
		_encode_u8(e.writer, tnr, .Tag) or_return

		size_in_bytes, berr := big.int_to_bytes_size(&vv, false, mem.panic_allocator())
		assert(berr == nil, "only errors if not initialized, which has been checked")
		assert(size_in_bytes >= 0)

		err_conv(_encode_u64(e, u64(size_in_bytes), .Bytes)) or_return

		for offset := (size_in_bytes*8)-8; offset >= 0; offset -= 8 {
			bits, derr := big.int_bitfield_extract(&vv, offset, 8, mem.panic_allocator())
			assert(derr == nil, "only errors if not initialized or invalid argument (offset and count), which won't happen")

			io.write_full(e.writer, {u8(bits & 255)}) or_return
		}
		return nil

	case: unreachable()
	}
}

@(private)
tag_cbor_unmarshal :: proc(_: ^Tag_Implementation, r: io.Reader, _: Tag_Number, v: any) -> Unmarshal_Error {
	hdr := _decode_header(r) or_return
	major, add := _header_split(hdr)
	#partial switch major {
	case .Bytes:
		ti := reflect.type_info_base(type_info_of(v.id))
		return _unmarshal_bytes(r, v, ti, hdr, add)
		
	case: return .Bad_Tag_Value
	}
}

@(private)
tag_cbor_marshal :: proc(_: ^Tag_Implementation, e: Encoder, v: any) -> Marshal_Error {
	_encode_u8(e.writer, TAG_CBOR_NR, .Tag) or_return
	ti := runtime.type_info_base(type_info_of(v.id))
	#partial switch t in ti.variant {
	case runtime.Type_Info_String:
		return marshal_into(e, v)
	case runtime.Type_Info_Array:
		elem_base := reflect.type_info_base(t.elem)
		if elem_base.id != byte { return .Bad_Tag_Value }
		return marshal_into(e, v)
	case runtime.Type_Info_Slice:
		elem_base := reflect.type_info_base(t.elem)
		if elem_base.id != byte { return .Bad_Tag_Value }
		return marshal_into(e, v)
	case runtime.Type_Info_Dynamic_Array:
		elem_base := reflect.type_info_base(t.elem)
		if elem_base.id != byte { return .Bad_Tag_Value }
		return marshal_into(e, v)
	case:
		return .Bad_Tag_Value
	}
}

// NOTE: this could probably be more efficient by decoding bytes from CBOR and then from base64 at the same time.
@(private)
tag_base64_unmarshal :: proc(_: ^Tag_Implementation, r: io.Reader, _: Tag_Number, v: any) -> (err: Unmarshal_Error) {
	hdr := _decode_header(r) or_return
	major, add := _header_split(hdr)
	#partial switch major {
	case .Text:
		ti := reflect.type_info_base(type_info_of(v.id))
		_unmarshal_bytes(r, v, ti, hdr, add) or_return
		#partial switch t in ti.variant {
		case runtime.Type_Info_String:
			switch t.is_cstring {
			case true:
				str := string((^cstring)(v.data)^)
				decoded := base64.decode(str) or_return
				(^cstring)(v.data)^ = strings.clone_to_cstring(string(decoded)) or_return
				delete(decoded)
				delete(str)
			case false:
				str := (^string)(v.data)^
				decoded := base64.decode(str) or_return
				(^string)(v.data)^ = string(decoded)
				delete(str)
			}
			return

		case runtime.Type_Info_Array:
			raw := ([^]byte)(v.data)
			decoded := base64.decode(string(raw[:t.count])) or_return
			copy(raw[:t.count], decoded)
			delete(decoded)
			return

		case runtime.Type_Info_Slice:
			raw := (^[]byte)(v.data)
			decoded := base64.decode(string(raw^)) or_return
			delete(raw^)
			raw^ = decoded
			return

		case runtime.Type_Info_Dynamic_Array:
			raw := (^mem.Raw_Dynamic_Array)(v.data)
			str := string(((^[dynamic]byte)(v.data)^)[:])

			decoded := base64.decode(str) or_return
			delete(str)

			raw.data = raw_data(decoded)
			raw.len  = len(decoded)
			raw.cap  = len(decoded)
			return

		case: unreachable()
		}

	case: return .Bad_Tag_Value
	}
}

@(private)
tag_base64_marshal :: proc(_: ^Tag_Implementation, e: Encoder, v: any) -> Marshal_Error {
	_encode_u8(e.writer, TAG_BASE64_NR, .Tag) or_return

	ti := runtime.type_info_base(type_info_of(v.id))
	a := any{v.data, ti.id}

	bytes: []byte
	switch val in a {
	case string:        bytes = transmute([]byte)val
	case cstring:       bytes = transmute([]byte)string(val)
	case []byte:        bytes = val
	case [dynamic]byte: bytes = val[:]
	case:
		#partial switch t in ti.variant {
		case runtime.Type_Info_Array:
			if t.elem.id != byte { return .Bad_Tag_Value }
			bytes = ([^]byte)(v.data)[:t.count]
		case:
			return .Bad_Tag_Value
		}
	}

	out_len := base64.encoded_length(bytes)
	err_conv(_encode_u64(e, u64(out_len), .Text)) or_return
	return base64.encode_into(e.writer, bytes)
}
