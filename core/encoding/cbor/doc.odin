/*
Package cbor encodes, decodes, marshals and unmarshals types from/into RCF 8949 compatible CBOR binary.
Also provided are conversion to and from JSON and the CBOR diagnostic format.

**Allocations:**

In general, when in the following table it says allocations are done on the `temp_allocator`, these allocations
are still attempted to be deallocated.
This allows you to use an allocator with freeing implemented as the `temp_allocator` which is handy with big CBOR.

- *Encoding*:  If the `.Deterministic_Map_Sorting` flag is set on the encoder, this allocates on the given `temp_allocator`
               some space for the keys of maps in order to sort them and then write them.
               Other than that there are no allocations (only for the final bytes if you use `cbor.encode_into_bytes`.

- *Decoding*:  Allocates everything on the given allocator and input given can be deleted after decoding.
               *No* temporary allocations are done.

- *Marshal*:   Same allocation strategy as encoding.

- *Unmarshal*: Allocates everything on the given allocator and input given can be deleted after unmarshalling.
               Some temporary allocations are done on the given `temp_allocator`.

**Determinism:**

CBOR defines a deterministic en/decoder, which among other things uses the smallest type possible for integers and floats,
and sorts map keys by their (encoded) lexical bytewise order.

You can enable this behaviour using a combination of flags, also available as the `cbor.ENCODE_FULLY_DETERMINISTIC` constant.
If you just want the small size that comes with this, but not the map sorting (which has a performance cost) you can use the
`cbor.ENCODE_SMALL` constant for the flags.

A deterministic float is a float in the smallest type (f16, f32, f64) that hasn't changed after conversion.
A deterministic integer is an integer in the smallest representation (u8, u16, u32, u64) it fits in.

**Untrusted Input:**

By default input is treated as untrusted, this means the sizes that are encoded in the CBOR are not blindly trusted.
If you were to trust these sizes, and allocate space for them an attacker would be able to cause massive allocations with small payloads.

The decoder has a `max_pre_alloc` field that specifies the maximum amount of bytes (roughly) to pre allocate, a KiB by default.

This does mean reallocations are more common though, you can, if you know the input is trusted, add the `.Trusted_Input` flag to the decoder.

**Tags:**

CBOR describes tags that you can wrap values with to assign a number to describe what type of data will follow.

More information and a list of default tags can be found here: [[RFC 8949 Section 3.4;https://www.rfc-editor.org/rfc/rfc8949.html#name-tagging-of-items]].

A list of registered extension types can be found here: [[IANA CBOR assignments;https://www.iana.org/assignments/cbor-tags/cbor-tags.xhtml]].

Tags can either be assigned to a distinct Odin type (used by default),
or be used with struct tags (`cbor_tag:"base64"`, or `cbor_tag:"1"` for example).

By default, the following tags are supported/provided by this implementation:

- *1/epoch*:   Assign this tag to `time.Time` or integer fields to use the defined seconds since epoch format.

- *24/cbor*:   Assign this tag to string or byte fields to store encoded CBOR (not decoding it).

- *34/base64*: Assign this tag to string or byte fields to store and decode the contents in base64.

- *2 & 3*:     Used automatically by the implementation to encode and decode big numbers into/from `core:math/big`.

- *55799*:     Self described CBOR, used when `.Self_Described_CBOR` flag is used to wrap the entire binary.
               This shows other implementations that we are dealing with CBOR by just looking at the first byte of input.

- *1010*:      An extension tag that defines a string type followed by its value, this is used by this implementation to support Odin's unions.

Users can provide their own tag implementations using the `cbor.tag_register_type(...)` to register a tag for a distinct Odin type
used automatically when it is encountered during marshal and unmarshal.
Or with `cbor.tag_register_number(...)` to register a tag number along with an identifier for convenience that can be used with struct tags,
e.g. `cbor_tag:"69"` or `cbor_tag:"my_tag"`.

You can look at the default tags provided for pointers on how these implementations work.

Example:
	package main

	import "base:intrinsics"

	import "core:encoding/cbor"
	import "core:fmt"
	import "core:reflect"
	import "core:time"

	Possibilities :: union {
		string,
		int,
	}

	Data :: struct {
		str: string,
		neg: cbor.Negative_U16,            // Store a CBOR value directly.
		now: time.Time `cbor_tag:"epoch"`, // Wrapped in the epoch tag.
		ignore_this: ^Data `cbor:"-"`,     // Ignored by implementation.
		renamed: f32 `cbor:"renamed :)"`,  // Renamed when encoded.
		my_union: Possibilities,           // Union support.

		my_raw: [8]u32 `cbor_tag:"raw"`, // Custom tag that just writes the value as bytes.
	}

	main :: proc() {
		// Example custom tag implementation that instead of breaking down all parts,
		// just writes the value as a big byte blob. This is an advanced feature but very powerful.
		RAW_TAG_NR :: 200
		cbor.tag_register_number({
			marshal = proc(_: ^cbor.Tag_Implementation, e: cbor.Encoder, v: any) -> cbor.Marshal_Error {
				cbor._encode_u8(e.writer, RAW_TAG_NR, .Tag) or_return
				return cbor.err_conv(cbor._encode_bytes(e, reflect.as_bytes(v)))
			},
			unmarshal = proc(_: ^cbor.Tag_Implementation, d: cbor.Decoder, _: cbor.Tag_Number, v: any) -> (cbor.Unmarshal_Error) {
				hdr := cbor._decode_header(d.reader) or_return
				maj, add := cbor._header_split(hdr)
				if maj != .Bytes {
					return .Bad_Tag_Value
				}

				bytes := cbor.err_conv(cbor._decode_bytes(d, add, maj)) or_return
				intrinsics.mem_copy_non_overlapping(v.data, raw_data(bytes), len(bytes))
				return nil
			},
		}, RAW_TAG_NR, "raw")

		now := time.Time{_nsec = 1701117968 * 1e9}

		data := Data{
			str         = "Hello, World!",
			neg         = 300,
			now         = now,
			ignore_this = &Data{},
			renamed     = 123123.125,
			my_union    = 3,
			my_raw      = {1=1, 2=2, 3=3},
		}

		// Marshal the struct into binary CBOR.
		binary, err := cbor.marshal(data, cbor.ENCODE_FULLY_DETERMINISTIC)
		fmt.assertf(err == nil, "marshal error: %v", err)
		defer delete(binary)

		// Decode the binary data into a `cbor.Value`.
		decoded, derr := cbor.decode(string(binary))
		fmt.assertf(derr == nil, "decode error: %v", derr)
		defer cbor.destroy(decoded)

		// Turn the CBOR into a human readable representation defined as the diagnostic format in [[RFC 8949 Section 8;https://www.rfc-editor.org/rfc/rfc8949.html#name-diagnostic-notation]].
		diagnosis, eerr := cbor.to_diagnostic_format(decoded)
		fmt.assertf(eerr == nil, "to diagnostic error: %v", eerr)
		defer delete(diagnosis)

		fmt.println(diagnosis)
	}

Output:
	{
		"my_raw": 200(h'00001000200030000000000000000000'),
		"my_union": 1010([
			"int",
			3
		]),
		"neg": -301,
		"now": 1(1701117968),
		"renamed :)": 123123.12500000,
		"str": "Hello, World!"
	}
*/
package encoding_cbor

