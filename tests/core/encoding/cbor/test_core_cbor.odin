package test_encoding_cbor

import "base:intrinsics"
import "core:bytes"
import "core:encoding/cbor"
import "core:fmt"
import "core:io"
import "core:math/big"
import "core:reflect"
import "core:testing"
import "core:time"

Foo :: struct {
	str: string,
	cstr: cstring,
	value: cbor.Value,
	neg: cbor.Negative_U16,
	pos: u16,
	iamint: int,
	base64: string `cbor_tag:"base64"`,
	renamed: f32 `cbor:"renamed :)"`,
	now: time.Time `cbor_tag:"1"`,
	nowie: time.Time,
	child: struct{
		dyn: [dynamic]string,
		mappy: map[string]int,
		my_integers: [10]int,
	},
	my_bytes: []byte,
	ennie: FooBar,
	ennieb: FooBars,
	quat: quaternion64,
	comp: complex128,
	important: rune,
	no: cbor.Nil,
	nos: cbor.Undefined,
	yes: b32,
	biggie: u64,
	smallie: cbor.Negative_U64,
	onetwenty: i128,
	small_onetwenty: i128,
	biggest: big.Int,
	smallest: big.Int,
	ignore_this: ^Foo `cbor:"-"`,
}

FooBar :: enum {
	EFoo,
	EBar,
}

FooBars :: bit_set[FooBar; u16]

@(test)
test_marshalling :: proc(t: ^testing.T) {
	{
		nice := "16 is a nice number"
		now := time.Time{_nsec = 1701117968 * 1e9}
		f: Foo = {
			str = "Hellope",
			cstr = "Hellnope",
			value = &cbor.Map{{u8(16), &nice}, {u8(32), u8(69)}},
			neg = 68,
			pos = 1212,
			iamint = -256,
			base64 = nice,
			renamed = 123123.125,

			now = now,
			nowie = now,

			child = {
				dyn = [dynamic]string{"one", "two", "three", "four"},
				mappy = map[string]int{"one" = 1, "two" = 2, "three" = 3, "four" = 4},
				my_integers = [10]int{1, 2, 3, 4, 5, 6, 7, 8, 9, 10},
			},

			my_bytes = []byte{},

			ennie = .EFoo,
			ennieb = {.EBar},

			quat = quaternion(w=16, x=17, y=18, z=19),
			comp = complex(32, 33),

			important = '!',

			no = cbor.Nil(uintptr(3)),

			yes = true,

			biggie = max(u64),
			smallie = cbor.Negative_U64(max(u64)),
			onetwenty = i128(12345),
			small_onetwenty = -i128(max(u64)),
			ignore_this = &Foo{},
		}

		big.atoi(&f.biggest, "1234567891011121314151617181920")
		big.atoi(&f.smallest, "-1234567891011121314151617181920")

		defer {
			delete(f.child.dyn)
			delete(f.child.mappy)
			big.destroy(&f.biggest)
			big.destroy(&f.smallest)
		}
		
		data, err := cbor.marshal(f, cbor.ENCODE_FULLY_DETERMINISTIC)
		testing.expect_value(t, err, nil)
		defer delete(data)

		decoded, derr := cbor.decode(string(data))
		testing.expect_value(t, derr, nil)
		defer cbor.destroy(decoded)

		diagnosis, eerr := cbor.to_diagnostic_format(decoded)
		testing.expect_value(t, eerr, nil)
		defer delete(diagnosis)

		testing.expect_value(t, diagnosis, `{
	"base64": 34("MTYgaXMgYSBuaWNlIG51bWJlcg=="),
	"biggest": 2(h'f951a9fd3c158afdff08ab8e0'),
	"biggie": 18446744073709551615,
	"child": {
		"dyn": [
			"one",
			"two",
			"three",
			"four"
		],
		"mappy": {
			"one": 1,
			"two": 2,
			"four": 4,
			"three": 3
		},
		"my_integers": [
			1,
			2,
			3,
			4,
			5,
			6,
			7,
			8,
			9,
			10
		]
	},
	"comp": [
		32.0000,
		33.0000
	],
	"cstr": "Hellnope",
	"ennie": 0,
	"ennieb": 512,
	"iamint": -256,
	"important": "!",
	"my_bytes": h'',
	"neg": -69,
	"no": nil,
	"nos": undefined,
	"now": 1(1701117968),
	"nowie": {
		"_nsec": 1701117968000000000
	},
	"onetwenty": 12345,
	"pos": 1212,
	"quat": [
		17.0000,
		18.0000,
		19.0000,
		16.0000
	],
	"renamed :)": 123123.12500000,
	"small_onetwenty": -18446744073709551615,
	"smallest": 3(h'f951a9fd3c158afdff08ab8e0'),
	"smallie": -18446744073709551616,
	"str": "Hellope",
	"value": {
		16: "16 is a nice number",
		32: 69
	},
	"yes": true
}`)

		backf: Foo
		uerr := cbor.unmarshal(string(data), &backf)
		testing.expect_value(t, uerr, nil)
		defer {
			delete(backf.str)
			delete(backf.cstr)
			cbor.destroy(backf.value)
			delete(backf.base64)

			for e in backf.child.dyn { delete(e) }
			delete(backf.child.dyn)

			for k in backf.child.mappy { delete(k) }
			delete(backf.child.mappy)

			delete(backf.my_bytes)

			big.destroy(&backf.biggest)
			big.destroy(&backf.smallest)
		}
		
		testing.expect_value(t, backf.str, f.str)
		testing.expect_value(t, backf.cstr, f.cstr)

		#partial switch v in backf.value {
		case ^cbor.Map:
			for entry, i in v {
				fm := f.value.(^cbor.Map)
				testing.expect_value(t, entry.key, fm[i].key)

				if str, is_str := entry.value.(^cbor.Text); is_str {
					testing.expect_value(t, str^, fm[i].value.(^cbor.Text)^)
				} else {
					testing.expect_value(t, entry.value, fm[i].value)
				}
			}

		case: testing.expectf(t, false, "wrong type %v", v)
		}

		testing.expect_value(t, backf.neg, f.neg)
		testing.expect_value(t, backf.iamint, f.iamint)
		testing.expect_value(t, backf.base64, f.base64)
		testing.expect_value(t, backf.renamed, f.renamed)
		testing.expect_value(t, backf.now, f.now)
		testing.expect_value(t, backf.nowie, f.nowie)
		for e, i in f.child.dyn { testing.expect_value(t, backf.child.dyn[i], e) }
		for key, value in f.child.mappy { testing.expect_value(t, backf.child.mappy[key], value) }
		testing.expect_value(t, backf.child.my_integers, f.child.my_integers)
		testing.expect_value(t, len(backf.my_bytes), 0)
		testing.expect_value(t, len(backf.my_bytes), len(f.my_bytes))
		testing.expect_value(t, backf.ennie, f.ennie)
		testing.expect_value(t, backf.ennieb, f.ennieb)
		testing.expect_value(t, backf.quat, f.quat)
		testing.expect_value(t, backf.comp, f.comp)
		testing.expect_value(t, backf.important, f.important)
		testing.expect_value(t, backf.no, nil)
		testing.expect_value(t, backf.nos, nil)
		testing.expect_value(t, backf.yes, f.yes)
		testing.expect_value(t, backf.biggie, f.biggie)
		testing.expect_value(t, backf.smallie, f.smallie)
		testing.expect_value(t, backf.onetwenty, f.onetwenty)
		testing.expect_value(t, backf.small_onetwenty, f.small_onetwenty)
		testing.expect_value(t, backf.ignore_this, nil)
		
		s_equals, s_err := big.equals(&backf.smallest, &f.smallest)
		testing.expect_value(t, s_err, nil)
		if !s_equals {
			testing.expectf(t, false, "smallest: %v does not equal %v", big.itoa(&backf.smallest), big.itoa(&f.smallest))
		}

		b_equals, b_err := big.equals(&backf.biggest, &f.biggest)
		testing.expect_value(t, b_err, nil)
		if !b_equals {
			testing.expectf(t, false, "biggest: %v does not equal %v", big.itoa(&backf.biggest), big.itoa(&f.biggest))
		}
	}
}

@(test)
test_marshalling_maybe :: proc(t: ^testing.T) {
	maybe_test: Maybe(int) = 1
	data, err := cbor.marshal(maybe_test)
	defer delete(data)
	testing.expect_value(t, err, nil)

	val, derr := cbor.decode(string(data))
	testing.expect_value(t, derr, nil)

	diag := cbor.to_diagnostic_format(val)
	testing.expect_value(t, diag, "1")
	delete(diag)
	
	maybe_dest: Maybe(int)
	uerr := cbor.unmarshal(string(data), &maybe_dest)
	testing.expect_value(t, uerr, nil)
	testing.expect_value(t, maybe_dest, 1)
}

@(test)
test_marshalling_nil_maybe :: proc(t: ^testing.T) {
	maybe_test: Maybe(int)
	data, err := cbor.marshal(maybe_test)
	defer delete(data)
	testing.expect_value(t, err, nil)

	val, derr := cbor.decode(string(data))
	testing.expect_value(t, derr, nil)

	diag := cbor.to_diagnostic_format(val)
	testing.expect_value(t, diag, "nil")
	delete(diag)
	
	maybe_dest: Maybe(int)
	uerr := cbor.unmarshal(string(data), &maybe_dest)
	testing.expect_value(t, uerr, nil)
	testing.expect_value(t, maybe_dest, nil)
}

@(test)
test_marshalling_union :: proc(t: ^testing.T) {
	My_Distinct :: distinct string

	My_Enum :: enum {
		One,
		Two,
	}

	My_Struct :: struct {
		my_enum: My_Enum,
	}

	My_Union :: union {
		string,
		My_Distinct,
		My_Struct,
		int,
	}

	{
		test: My_Union = My_Distinct("Hello, World!")
		data, err := cbor.marshal(test)
		defer delete(data)
		testing.expect_value(t, err, nil)

		val, derr := cbor.decode(string(data))
		defer cbor.destroy(val)
		testing.expect_value(t, derr, nil)

		diag := cbor.to_diagnostic_format(val, -1)
		defer delete(diag)
		testing.expect_value(t, diag, `1010(["My_Distinct", "Hello, World!"])`)

		dest: My_Union
		uerr := cbor.unmarshal(string(data), &dest)
		testing.expect_value(t, uerr, nil)
		testing.expect_value(t, dest, My_Distinct("Hello, World!"))
		if str, ok := dest.(My_Distinct); ok {
			delete(string(str))
		}
	}

	My_Union_No_Nil :: union #no_nil {
		string,
		My_Distinct,
		My_Struct,
		int,
	}

	{
		test: My_Union_No_Nil = My_Struct{.Two}
		data, err := cbor.marshal(test)
		defer delete(data)
		testing.expect_value(t, err, nil)

		val, derr := cbor.decode(string(data))
		defer cbor.destroy(val)
		testing.expect_value(t, derr, nil)

		diag := cbor.to_diagnostic_format(val, -1)
		defer delete(diag)
		testing.expect_value(t, diag, `1010(["My_Struct", {"my_enum": 1}])`)

		dest: My_Union_No_Nil
		uerr := cbor.unmarshal(string(data), &dest)
		testing.expect_value(t, uerr, nil)
		testing.expect_value(t, dest, My_Struct{.Two})
	}
}

@(test)
test_lying_length_array :: proc(t: ^testing.T) {
	// Input says this is an array of length max(u64), this should not allocate that amount.
	input := []byte{0x9B, 0x00, 0x00, 0x42, 0xFA, 0x42, 0xFA, 0x42, 0xFA, 0x42}
	_, err := cbor.decode(string(input))
	testing.expect_value(t, err, io.Error.Unexpected_EOF) // .Out_Of_Memory would be bad.
}

@(test)
test_decode_unsigned :: proc(t: ^testing.T) {
	expect_decoding(t, "\x00", "0", u8)
	expect_decoding(t, "\x01", "1", u8)
	expect_decoding(t, "\x0a", "10", u8)
	expect_decoding(t, "\x17", "23", u8)
	expect_decoding(t, "\x18\x18", "24", u8)
	expect_decoding(t, "\x18\x19", "25", u8)
	expect_decoding(t, "\x18\x64", "100", u8)
	expect_decoding(t, "\x19\x03\xe8", "1000", u16)
	expect_decoding(t, "\x1a\x00\x0f\x42\x40", "1000000", u32) // Million.
	expect_decoding(t, "\x1b\x00\x00\x00\xe8\xd4\xa5\x10\x00", "1000000000000", u64) // Trillion.
	expect_decoding(t, "\x1b\xff\xff\xff\xff\xff\xff\xff\xff", "18446744073709551615", u64) // max(u64).
}

@(test)
test_encode_unsigned :: proc(t: ^testing.T) {
	expect_encoding(t, u8(0), "\x00")
	expect_encoding(t, u8(1), "\x01")
	expect_encoding(t, u8(10), "\x0a")
	expect_encoding(t, u8(23), "\x17")
	expect_encoding(t, u8(24), "\x18\x18")
	expect_encoding(t, u8(25), "\x18\x19")
	expect_encoding(t, u8(100), "\x18\x64")
	expect_encoding(t, u16(1000), "\x19\x03\xe8")
	expect_encoding(t, u32(1000000), "\x1a\x00\x0f\x42\x40") // Million.
	expect_encoding(t, u64(1000000000000), "\x1b\x00\x00\x00\xe8\xd4\xa5\x10\x00") // Trillion.
	expect_encoding(t, u64(18446744073709551615), "\x1b\xff\xff\xff\xff\xff\xff\xff\xff") // max(u64).
}

@(test)
test_decode_negative :: proc(t: ^testing.T) {
	expect_decoding(t, "\x20", "-1", cbor.Negative_U8)
	expect_decoding(t, "\x29", "-10", cbor.Negative_U8)
	expect_decoding(t, "\x38\x63", "-100", cbor.Negative_U8)
	expect_decoding(t, "\x39\x03\xe7", "-1000", cbor.Negative_U16)

	// Negative max(u64).
	expect_decoding(t, "\x3b\xff\xff\xff\xff\xff\xff\xff\xff", "-18446744073709551616", cbor.Negative_U64)
}

@(test)
test_encode_negative :: proc(t: ^testing.T) {
	expect_encoding(t, cbor.Negative_U8(0), "\x20")
	expect_encoding(t, cbor.Negative_U8(9), "\x29")
	expect_encoding(t, cbor.Negative_U8(99), "\x38\x63")
	expect_encoding(t, cbor.Negative_U16(999), "\x39\x03\xe7")

	// Negative max(u64).
	expect_encoding(t, cbor.Negative_U64(18446744073709551615), "\x3b\xff\xff\xff\xff\xff\xff\xff\xff")
}

@(test)
test_decode_simples :: proc(t: ^testing.T) {
	expect_decoding(t, "\xf4", "false", bool)
	expect_decoding(t, "\xf5", "true", bool)
	expect_decoding(t, "\xf6", "nil", cbor.Nil)
	expect_decoding(t, "\xf7", "undefined", cbor.Undefined)

	expect_decoding(t, "\xf0", "simple(16)", cbor.Simple)
	expect_decoding(t, "\xf8\xff", "simple(255)", cbor.Atom)
}

@(test)
test_encode_simples :: proc(t: ^testing.T) {
	expect_encoding(t, bool(false), "\xf4")
	expect_encoding(t, bool(true), "\xf5")
	expect_encoding(t, cbor.Nil{}, "\xf6") // default value for a distinct rawptr, in this case Nil.
	expect_encoding(t, cbor.Undefined{}, "\xf7") // default value for a distinct rawptr, in this case Undefined.

	expect_encoding(t, cbor.Simple(16), "\xf0") // simple(16)
	expect_encoding(t, cbor.Simple(255), "\xf8\xff") // simple(255)
}

@(test)
test_decode_floats :: proc(t: ^testing.T) {
	expect_float(t, "\xf9\x00\x00", f16(0.0))
	expect_float(t, "\xf9\x80\x00", f16(-0.0))
	expect_float(t, "\xf9\x3c\x00", f16(1.0))
	expect_float(t, "\xfb\x3f\xf1\x99\x99\x99\x99\x99\x9a", f64(1.1))
	expect_float(t, "\xf9\x3e\x00", f16(1.5))
	expect_float(t, "\xf9\x7b\xff", f16(65504.0))
	expect_float(t, "\xfa\x47\xc3\x50\x00", f32(100000.0))
	expect_float(t, "\xfa\x7f\x7f\xff\xff", f32(3.4028234663852886e+38))
	expect_float(t, "\xfb\x7e\x37\xe4\x3c\x88\x00\x75\x9c", f64(1.0e+300))
	expect_float(t, "\xf9\x00\x01", f16(5.960464477539063e-8))
	expect_float(t, "\xf9\x04\x00", f16(0.00006103515625))
	expect_float(t, "\xf9\xc4\x00", f16(-4.0))
	expect_float(t, "\xfb\xc0\x10\x66\x66\x66\x66\x66\x66", f64(-4.1))
	expect_decoding(t, "\xf9\x7c\x00", "+Inf", f16)
	expect_decoding(t, "\xf9\x7e\x00", "NaN", f16)
	expect_decoding(t, "\xf9\xfc\x00", "-Inf", f16)
	expect_decoding(t, "\xfa\x7f\x80\x00\x00", "+Inf", f32)
	expect_decoding(t, "\xfa\x7f\xc0\x00\x00", "NaN", f32)
	expect_decoding(t, "\xfa\xff\x80\x00\x00", "-Inf", f32)
	expect_decoding(t, "\xfb\x7f\xf0\x00\x00\x00\x00\x00\x00", "+Inf", f64)
	expect_decoding(t, "\xfb\x7f\xf8\x00\x00\x00\x00\x00\x00", "NaN", f64)
	expect_decoding(t, "\xfb\xff\xf0\x00\x00\x00\x00\x00\x00", "-Inf", f64)
}

@(test)
test_encode_floats :: proc(t: ^testing.T) {
	expect_encoding(t, f16(0.0), "\xf9\x00\x00")
	expect_encoding(t, f16(-0.0), "\xf9\x80\x00")
	expect_encoding(t, f16(1.0), "\xf9\x3c\x00")
	expect_encoding(t, f64(1.1), "\xfb\x3f\xf1\x99\x99\x99\x99\x99\x9a")
	expect_encoding(t, f16(1.5), "\xf9\x3e\x00")
	expect_encoding(t, f16(65504.0), "\xf9\x7b\xff")
	expect_encoding(t, f32(100000.0), "\xfa\x47\xc3\x50\x00")
	expect_encoding(t, f32(3.4028234663852886e+38), "\xfa\x7f\x7f\xff\xff")
	expect_encoding(t, f64(1.0e+300), "\xfb\x7e\x37\xe4\x3c\x88\x00\x75\x9c")
	expect_encoding(t, f16(5.960464477539063e-8), "\xf9\x00\x01")
	expect_encoding(t, f16(0.00006103515625), "\xf9\x04\x00")
	expect_encoding(t, f16(-4.0), "\xf9\xc4\x00")
	expect_encoding(t, f64(-4.1), "\xfb\xc0\x10\x66\x66\x66\x66\x66\x66")
}

@(test)
test_decode_bytes :: proc(t: ^testing.T) {
	expect_decoding(t, "\x40", "h''", ^cbor.Bytes)
	expect_decoding(t, "\x44\x01\x02\x03\x04", "h'1234'", ^cbor.Bytes)

	// Indefinite lengths
	
	expect_decoding(t, "\x5f\x42\x01\x02\x43\x03\x04\x05\xff", "h'12345'", ^cbor.Bytes)
}

@(test)
test_encode_bytes :: proc(t: ^testing.T) {
	expect_encoding(t, &cbor.Bytes{}, "\x40")
	expect_encoding(t, &cbor.Bytes{1, 2, 3, 4}, "\x44\x01\x02\x03\x04")

	// Indefinite lengths
	
	expect_streamed_encoding(t, "\x5f\x42\x01\x02\x43\x03\x04\x05\xff", &cbor.Bytes{1, 2}, &cbor.Bytes{3, 4, 5})
}

@(test)
test_decode_strings :: proc(t: ^testing.T) {
	expect_decoding(t, "\x60", `""`, ^cbor.Text)
	expect_decoding(t, "\x61\x61", `"a"`, ^cbor.Text)
	expect_decoding(t, "\x64\x49\x45\x54\x46", `"IETF"`, ^cbor.Text)
	expect_decoding(t, "\x62\x22\x5c", `""\"`, ^cbor.Text)
	expect_decoding(t, "\x62\xc3\xbc", `"ü"`, ^cbor.Text)
	expect_decoding(t, "\x63\xe6\xb0\xb4", `"水"`, ^cbor.Text)
	expect_decoding(t, "\x64\xf0\x90\x85\x91", `"𐅑"`, ^cbor.Text)

	// Indefinite lengths
	
	expect_decoding(t, "\x7f\x65\x73\x74\x72\x65\x61\x64\x6d\x69\x6e\x67\xff", `"streaming"`, ^cbor.Text)
}

@(test)
test_encode_strings :: proc(t: ^testing.T) {
	expect_encoding(t, &cbor.Text{}, "\x60")

	a := "a"
	expect_encoding(t, &a, "\x61\x61")
	
	b := "IETF"
	expect_encoding(t, &b, "\x64\x49\x45\x54\x46")
	
	c := "\"\\"
	expect_encoding(t, &c, "\x62\x22\x5c")
	
	d := "ü"
	expect_encoding(t, &d, "\x62\xc3\xbc")
	
	e := "水"
	expect_encoding(t, &e, "\x63\xe6\xb0\xb4")

	f := "𐅑"
	expect_encoding(t, &f, "\x64\xf0\x90\x85\x91")

	// Indefinite lengths
	
	sa := "strea"
	sb := "ming"
	expect_streamed_encoding(t, "\x7f\x65\x73\x74\x72\x65\x61\x64\x6d\x69\x6e\x67\xff", &sa, &sb)
}

@(test)
test_decode_lists :: proc(t: ^testing.T) {
	expect_decoding(t, "\x80", "[]", ^cbor.Array)
	expect_decoding(t, "\x83\x01\x02\x03", "[1, 2, 3]", ^cbor.Array)
	expect_decoding(t, "\x83\x01\x82\x02\x03\x82\x04\x05", "[1, [2, 3], [4, 5]]", ^cbor.Array)
	expect_decoding(t, "\x98\x19\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x18\x18\x19", "[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]", ^cbor.Array)
	expect_decoding(t, "\x82\x61\x61\xa1\x61\x62\x61\x63", `["a", {"b": "c"}]`, ^cbor.Array)

	// Indefinite lengths
	
	expect_decoding(t, "\x9f\xff", "[]", ^cbor.Array)
	expect_decoding(t, "\x9f\x01\x82\x02\x03\x9f\x04\x05\xff\xff", "[1, [2, 3], [4, 5]]", ^cbor.Array)
	expect_decoding(t, "\x9f\x01\x82\x02\x03\x82\x04\x05\xff", "[1, [2, 3], [4, 5]]", ^cbor.Array)
	expect_decoding(t, "\x83\x01\x82\x02\x03\x9f\x04\x05\xff", "[1, [2, 3], [4, 5]]", ^cbor.Array)
	expect_decoding(t, "\x83\x01\x9f\x02\x03\xff\x82\x04\x05", "[1, [2, 3], [4, 5]]", ^cbor.Array)
	expect_decoding(t, "\x9f\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x18\x18\x19\xff", "[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25]", ^cbor.Array)
	expect_decoding(t, "\x82\x61\x61\xbf\x61\x62\x61\x63\xff", `["a", {"b": "c"}]`, ^cbor.Array)
}

@(test)
test_encode_lists :: proc(t: ^testing.T) {
	expect_encoding(t, &cbor.Array{}, "\x80")
	expect_encoding(t, &cbor.Array{u8(1), u8(2), u8(3)}, "\x83\x01\x02\x03")
	expect_encoding(t, &cbor.Array{u8(1), &cbor.Array{u8(2), u8(3)}, &cbor.Array{u8(4), u8(5)}}, "\x83\x01\x82\x02\x03\x82\x04\x05")
	expect_encoding(t, &cbor.Array{u8(1), u8(2), u8(3), u8(4), u8(5), u8(6), u8(7), u8(8), u8(9), u8(10), u8(11), u8(12), u8(13), u8(14), u8(15), u8(16), u8(17), u8(18), u8(19), u8(20), u8(21), u8(22), u8(23), u8(24), u8(25)}, "\x98\x19\x01\x02\x03\x04\x05\x06\x07\x08\x09\x0a\x0b\x0c\x0d\x0e\x0f\x10\x11\x12\x13\x14\x15\x16\x17\x18\x18\x18\x19")
	
	{
		a := "a"
		b := "b"
		c := "c"
		expect_encoding(t, &cbor.Array{&a, &cbor.Map{{&b, &c}}}, "\x82\x61\x61\xa1\x61\x62\x61\x63")
	}

	// Indefinite lengths
	
	expect_streamed_encoding(t, "\x9f\xff", &cbor.Array{})

	{
		buf: bytes.Buffer
		bytes.buffer_init_allocator(&buf, 0, 0)
		defer bytes.buffer_destroy(&buf)
		stream  := bytes.buffer_to_stream(&buf)
		encoder := cbor.Encoder{cbor.ENCODE_FULLY_DETERMINISTIC, stream, {}}
		
		err: cbor.Encode_Error
		err = cbor.encode_stream_begin(stream, .Array)
		testing.expect_value(t, err, nil)

		{
			err = cbor.encode_stream_array_item(encoder, u8(1))
			testing.expect_value(t, err, nil)

			err = cbor.encode_stream_array_item(encoder, &cbor.Array{u8(2), u8(3)})
			testing.expect_value(t, err, nil)

			err = cbor.encode_stream_begin(stream, .Array)
			testing.expect_value(t, err, nil)

			{
				err = cbor.encode_stream_array_item(encoder, u8(4))
				testing.expect_value(t, err, nil)

				err = cbor.encode_stream_array_item(encoder, u8(5))
				testing.expect_value(t, err, nil)
			}

			err = cbor.encode_stream_end(stream)
			testing.expect_value(t, err, nil)
		}

		err = cbor.encode_stream_end(stream)
		testing.expect_value(t, err, nil)
		
		testing.expect_value(t, fmt.tprint(bytes.buffer_to_bytes(&buf)), fmt.tprint(transmute([]byte)string("\x9f\x01\x82\x02\x03\x9f\x04\x05\xff\xff")))
	}
	
	{
		buf: bytes.Buffer
		bytes.buffer_init_allocator(&buf, 0, 0)
		defer bytes.buffer_destroy(&buf)
		stream  := bytes.buffer_to_stream(&buf)
		encoder := cbor.Encoder{cbor.ENCODE_FULLY_DETERMINISTIC, stream, {}}
	
		err: cbor.Encode_Error
		err = cbor._encode_u8(stream, 2, .Array)
		testing.expect_value(t, err, nil)
		
		a := "a"
		err = cbor.encode(encoder, &a)
		testing.expect_value(t, err, nil)
		
		{
			err = cbor.encode_stream_begin(stream, .Map)
			testing.expect_value(t, err, nil)
			
			b := "b"
			c := "c"
			err = cbor.encode_stream_map_entry(encoder, &b, &c)
			testing.expect_value(t, err, nil)

			err = cbor.encode_stream_end(stream)
			testing.expect_value(t, err, nil)
		}
		
		testing.expect_value(t, fmt.tprint(bytes.buffer_to_bytes(&buf)), fmt.tprint(transmute([]byte)string("\x82\x61\x61\xbf\x61\x62\x61\x63\xff")))
	}
}

@(test)
test_decode_maps :: proc(t: ^testing.T) {
	expect_decoding(t, "\xa0", "{}", ^cbor.Map)
	expect_decoding(t, "\xa2\x01\x02\x03\x04", "{1: 2, 3: 4}", ^cbor.Map)
	expect_decoding(t, "\xa2\x61\x61\x01\x61\x62\x82\x02\x03", `{"a": 1, "b": [2, 3]}`, ^cbor.Map)
	expect_decoding(t, "\xa5\x61\x61\x61\x41\x61\x62\x61\x42\x61\x63\x61\x43\x61\x64\x61\x44\x61\x65\x61\x45", `{"a": "A", "b": "B", "c": "C", "d": "D", "e": "E"}`, ^cbor.Map)

	// Indefinite lengths

	expect_decoding(t, "\xbf\x61\x61\x01\x61\x62\x9f\x02\x03\xff\xff", `{"a": 1, "b": [2, 3]}`, ^cbor.Map)
	expect_decoding(t, "\xbf\x63\x46\x75\x6e\xf5\x63\x41\x6d\x74\x21\xff", `{"Fun": true, "Amt": -2}`, ^cbor.Map)
}

@(test)
test_encode_maps :: proc(t: ^testing.T) {
	expect_encoding(t, &cbor.Map{}, "\xa0")
	expect_encoding(t, &cbor.Map{{u8(1), u8(2)}, {u8(3), u8(4)}}, "\xa2\x01\x02\x03\x04")

	a := "a"
	b := "b"
	// NOTE: also tests the deterministic nature because it has to swap/sort the entries.
	expect_encoding(t, &cbor.Map{{&b, &cbor.Array{u8(2), u8(3)}}, {&a, u8(1)}}, "\xa2\x61\x61\x01\x61\x62\x82\x02\x03")
	
	fun := "Fun"
	amt := "Amt"
	expect_streamed_encoding(t, "\xbf\x63\x46\x75\x6e\xf5\x63\x41\x6d\x74\x21\xff", &cbor.Map{{&fun, true}, {&amt, cbor.Negative_U8(1)}})
}

@(test)
test_decode_tags :: proc(t: ^testing.T) {
	// Tag number 2 (unsigned bignumber), value bytes, max(u64) + 1.
	expect_tag(t, "\xc2\x49\x01\x00\x00\x00\x00\x00\x00\x00\x00", cbor.TAG_UNSIGNED_BIG_NR, "2(h'100000000')")

	// Tag number 3 (negative bignumber), value bytes, negative max(u64) - 1.
	expect_tag(t, "\xc3\x49\x01\x00\x00\x00\x00\x00\x00\x00\x00", cbor.TAG_NEGATIVE_BIG_NR, "3(h'100000000')")

	expect_tag(t, "\xc1\x1a\x51\x4b\x67\xb0", cbor.TAG_EPOCH_TIME_NR, "1(1363896240)")
	expect_tag(t, "\xc1\xfb\x41\xd4\x52\xd9\xec\x20\x00\x00", cbor.TAG_EPOCH_TIME_NR, "1(1363896240.5000000000000000)")
	expect_tag(t, "\xd8\x18\x45\x64\x49\x45\x54\x46", cbor.TAG_CBOR_NR, "24(h'6449455446')")
}

@(test)
test_encode_tags :: proc(t: ^testing.T) {
	expect_encoding(t, &cbor.Tag{cbor.TAG_UNSIGNED_BIG_NR, &cbor.Bytes{1, 0, 0, 0, 0, 0, 0, 0, 0}}, "\xc2\x49\x01\x00\x00\x00\x00\x00\x00\x00\x00")
	expect_encoding(t, &cbor.Tag{cbor.TAG_EPOCH_TIME_NR, u32(1363896240)}, "\xc1\x1a\x51\x4b\x67\xb0")
	expect_encoding(t, &cbor.Tag{cbor.TAG_EPOCH_TIME_NR, f64(1363896240.500)}, "\xc1\xfb\x41\xd4\x52\xd9\xec\x20\x00\x00")
}

// Helpers

expect_decoding :: proc(t: ^testing.T, encoded: string, decoded: string, type: typeid, loc := #caller_location) {
    res, err := cbor.decode(encoded)
	defer cbor.destroy(res)

	testing.expect_value(t, reflect.union_variant_typeid(res), type, loc)
    testing.expect_value(t, err, nil, loc)

	str := cbor.to_diagnostic_format(res, padding=-1)
	defer delete(str)

    testing.expect_value(t, str, decoded, loc)
}

expect_tag :: proc(t: ^testing.T, encoded: string, nr: cbor.Tag_Number, value_decoded: string, loc := #caller_location) {
	res, err := cbor.decode(encoded)
	defer cbor.destroy(res)

	testing.expect_value(t, err, nil, loc)
	
	if tag, is_tag := res.(^cbor.Tag); is_tag {
		testing.expect_value(t, tag.number, nr, loc)

		str := cbor.to_diagnostic_format(tag, padding=-1)
		defer delete(str)

		testing.expect_value(t, str, value_decoded, loc)
	} else {
		testing.expectf(t, false, "Value %#v is not a tag", res, loc)
	}
}

expect_float :: proc(t: ^testing.T, encoded: string, expected: $T, loc := #caller_location) where intrinsics.type_is_float(T) {
    res, err := cbor.decode(encoded)
	defer cbor.destroy(res)

	testing.expect_value(t, reflect.union_variant_typeid(res), typeid_of(T), loc)
    testing.expect_value(t, err, nil, loc)

	#partial switch r in res {
	case f16:
		when T == f16 { testing.expect_value(t, res, expected, loc) } else { unreachable() }
	case f32:
		when T == f32 { testing.expect_value(t, res, expected, loc) } else { unreachable() }
	case f64:
		when T == f64 { testing.expect_value(t, res, expected, loc) } else { unreachable() }
	case:
		unreachable()
	}
}

expect_encoding :: proc(t: ^testing.T, val: cbor.Value, encoded: string, loc := #caller_location) {
	buf: bytes.Buffer
	bytes.buffer_init_allocator(&buf, 0, 0)
	defer bytes.buffer_destroy(&buf)
	stream  := bytes.buffer_to_stream(&buf)
	encoder := cbor.Encoder{cbor.ENCODE_FULLY_DETERMINISTIC, stream, {}}

	err := cbor.encode(encoder, val, loc)
	testing.expect_value(t, err, nil, loc)
	testing.expect_value(t, fmt.tprint(bytes.buffer_to_bytes(&buf)), fmt.tprint(transmute([]byte)encoded), loc)
}

expect_streamed_encoding :: proc(t: ^testing.T, encoded: string, values: ..cbor.Value, loc := #caller_location) {
	buf: bytes.Buffer
	bytes.buffer_init_allocator(&buf, 0, 0)
	defer bytes.buffer_destroy(&buf)
	stream  := bytes.buffer_to_stream(&buf)
	encoder := cbor.Encoder{cbor.ENCODE_FULLY_DETERMINISTIC, stream, {}}

	for value, i in values {
		err: cbor.Encode_Error
		err2: cbor.Encode_Error
		#partial switch v in value {
		case ^cbor.Bytes:
			if i == 0 { err = cbor.encode_stream_begin(stream, .Bytes) }
			err2 = cbor._encode_bytes(encoder, v^)
		case ^cbor.Text:
			if i == 0 { err = cbor.encode_stream_begin(stream, .Text) }
			err2 = cbor._encode_text(encoder, v^)
		case ^cbor.Array:
			if i == 0 { err = cbor.encode_stream_begin(stream, .Array) }
			for item in v {
				err2 = cbor.encode_stream_array_item(encoder, item)
				if err2 != nil { break } 
			}
		case ^cbor.Map:
			err = cbor.encode_stream_begin(stream, .Map)
			for item in v {
				err2 = cbor.encode_stream_map_entry(encoder, item.key, item.value)
				if err2 != nil { break }
			}
		case:
			testing.expectf(t, false, "%v does not support streamed encoding", reflect.union_variant_typeid(value))
		}

		testing.expect_value(t, err, nil, loc)
		testing.expect_value(t, err2, nil, loc)
	}

	err := cbor.encode_stream_end(stream)
	testing.expect_value(t, err, nil, loc)

	testing.expect_value(t, fmt.tprint(bytes.buffer_to_bytes(&buf)), fmt.tprint(transmute([]byte)encoded), loc)
}
