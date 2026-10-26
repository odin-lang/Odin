package test_core_json_differential

import "core:encoding/json"
import ref "../reference"

// The types the fuzzer unmarshals into. Between them they reach every branch of
// `unmarshal_value`, `unmarshal_object`, `unmarshal_array` and the `assign_*` helpers.

Color :: enum {
	Red,
	Green,
	Blue,
}

Sparse_Enum :: enum u8 {
	A = 1,
	B = 5,
	C = 200,
}

Colors   :: bit_set[Color]
Flags_16 :: bit_set[0..<16; u16]

Packed :: bit_field u16 {
	lo: u8 | 4,
	hi: u16 | 12,
}

My_Int    :: distinct int
My_String :: distinct string

Inner :: struct {
	a: int,
	b: string,
	c: f32,
}

Base :: struct {
	id:  u64,
	tag: string,
}

// Field lookup priority: a `json` tag match beats a plain name match (`alias` takes the key
// "plain"), an empty tag counts as no tag, and keys can reach into `using _` fields.
Tagged :: struct {
	using _: Base,
	name:    string `json:"Name"`,
	count:   i32    `json:"n,omitempty"`,
	alias:   int    `json:"plain"`,
	plain:   bool,
	empty:   int    `json:""`,
	other:   f64    `xml:"x" json:"other_name"`,
	ignored: int    `json:"-"`,
}

// Keys reach two levels of `using _`, and the fields without a size share their offsets with the
// fields after them, so a struct's fields cannot be told apart by offset.
Deep :: struct {
	using _: Tagged,
	none:    struct{},
	after:   int,
	using _: Inner,
	zero:    [0]int,
	last:    string,
}

Raw :: struct #raw_union {
	i: i32,
	f: f32,
}

// Unmarshalling into a union never clears the previous variant, so when a key repeats with a
// struct value, fields the second value leaves out keep the old bytes. Struct variants therefore
// must not place a non-pointer field over another variant's pointer: it would hold an address,
// and the two packages allocate at different addresses. Here `s` overlays the `string` variant.
Mixed_Object :: struct {
	s: string,
	a: int,
	c: f32,
}

Mixed   :: union {int, string, Mixed_Object}
No_Nil  :: union #no_nil {bool, f64}

Everything :: struct {
	i8_:    i8,
	u8_:    u8,
	i16_:   i16,
	u16_:   u16,
	i32_:   i32,
	u32_:   u32,
	i64_:   i64,
	u64_:   u64,
	i128_:  i128,
	u128_:  u128,
	i32le_: i32le,
	i32be_: i32be,
	u16be_: u16be,
	int_:   int,
	uint_:  uint,
	uptr:   uintptr,
	my_int: My_Int,

	f16_:   f16,
	f32_:   f32,
	f64_:   f64,
	f32be_: f32be,

	b:    bool,
	b8_:  b8,
	b32_: b32,

	s:      string,
	my_str: My_String,
	cs:     cstring,
	r:      rune,

	color:  Color,
	sparse: Sparse_Enum,
	colors: Colors,
	flags:  Flags_16,
	packed: Packed,

	c64:  complex64,
	c128: complex128,
	q128: quaternion128,

	arr:    [3]int,
	earr:   [Color]f32,
	fixed:  [dynamic; 4]u8,
	sl:     []Inner,
	dyn:    [dynamic]string,
	nested: [][]int,

	m_str: map[string]int,
	m_int: map[int]string,
	m_u8:  map[u8]f64,
	m_cs:  map[cstring]bool,
	m_obj: map[string]Inner,

	mixed:  Mixed,
	no_nil: No_Nil,
	maybe:  Maybe(int),

	inner:  Inner,
	ptr:    ^Inner,
	tagged: Tagged,
	raw:    Raw,
}

// `json.Value` is special-cased by the unmarshaller, so each implementation needs a target
// that uses its own `Value` type. The two structs below are compared field by field.
With_Value_Current :: struct {
	id:    int,
	extra: json.Value,
	list:  []json.Value,
	m:     map[string]json.Value,
}

With_Value_Reference :: struct {
	id:    int,
	extra: ref.Value,
	list:  []ref.Value,
	m:     map[string]ref.Value,
}
