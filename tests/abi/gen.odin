// Generates abi_corpus.odin, abi_corpus.c, abi_main.odin and tiers.c from one
// description.
//
// The runners regenerate into their build directory
//
// The corpus encodes NO ABI. Every check is "Odin and the platform C compiler
// agree", so one corpus is valid on every target without knowing whether it is
// SysV, AAPCS64 or Win64.
//
//	odin run gen.odin -file -- <output directory>
package abi_gen

import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

// ---------------------------------------------------------------- scalars

Scalar :: struct {
	odin:     string,
	c:        string,
	is_float: bool,
}

scalar :: proc(tag: string) -> Scalar {
	switch tag {
	case "i8":   return {"i8", "int8_t", false}
	case "i16":  return {"i16", "int16_t", false}
	case "i32":  return {"i32", "int32_t", false}
	case "i64":  return {"i64", "int64_t", false}
	case "u8":   return {"u8", "uint8_t", false}
	case "u16":  return {"u16", "uint16_t", false}
	case "u32":  return {"u32", "uint32_t", false}
	case "u64":  return {"u64", "uint64_t", false}
	case "bool": return {"bool", "_Bool", false}
	case "f16":  return {"f16", "_Float16", true}
	case "i128": return {"i128", "__int128", false}
	case "enum": return {"E32", "enum E32", false}
	case "c64":  return {"complex64", "float _Complex", false}
	case "c128": return {"complex128", "double _Complex", false}
	case "bset": return {"BS", "unsigned", false}
	case "f32":  return {"f32", "float", true}
	case "f64":  return {"f64", "double", true}
	case "ptr":  return {"rawptr", "void *", false}
	case "cstring": return {"cstring", "char *", false}
	}
	fmt.panicf("unknown scalar tag %q", tag)
}

// Tiers keep a target that lacks an extension from losing the whole corpus.
TIER_CORE :: "core"
TIER_GNU  :: "gnu"  // zero-length arrays, empty structs __GNUC__
TIER_F16  :: "f16"  // _Float16
TIER_I128 :: "i128" // __int128, 64-bit targets only

// A scalar can carry a tier, and any type built from it inherits it: `_Float16`
// is not available everywhere, and a family is only as portable as its members.
scalar_tier :: proc(tag: string) -> (string, bool) {
	switch tag {
	case "f16":  return TIER_F16, true
	case "i128": return TIER_I128, true
	}
	return TIER_CORE, false
}

tier_of :: proc(tags: ..string) -> string {
	for t in tags {
		if tier, ok := scalar_tier(t); ok {
			return tier
		}
	}
	return TIER_CORE
}

// A member spelled differently in the two languages -- matrix indexing, or a
// bare vector, where there is no common accessor.
Leaf :: struct {
	odin_path: string,
	c_path:    string,
	tag:       string,
	val:       string,
}

Ty :: struct {
	name:   string,
	odin:   string,
	c:      string,
	fields: []Leaf,
	tier:   string,
	// Escape hatch for members with no lvalue path on the Odin side. A #simd
	// lane is read with `simd.extract` and written only as a whole vector, so
	// the C side still checks every lane while Odin uses these.
	// odin_set: statements, `{}` is the variable. odin_get: (expr, expected).
	odin_set: []string,
	odin_get: [][2]string,
}

types: [dynamic]Ty

add :: proc(
	name, odin, c: string,
	fields: []Leaf,
	tier: string = TIER_CORE,
	odin_set: []string = nil,
	odin_get: [][2]string = nil,
) {
	append(&types, Ty{name, odin, c, fields, tier, odin_set, odin_get})
}

// A distinct value per field position, so a shifted read is detectable.
val :: proc(i: int, tag: string) -> string {
	if scalar(tag).is_float {
		return tp("%d.5", i * 7 + 3)
	}
	return tp("%d", i * 7 + 3)
}

c_val :: proc(tag, v: string) -> string {
	switch tag {
	case "ptr":     return tp("(void *)(intptr_t)(%s)", v)
	case "cstring": return tp("(char *)(intptr_t)(%s)", v)
	case "bool": return "1"
	case "enum": return tp("(enum E32)(%s)", v)
	case "c64":  return tp("(%s.0f + %d.0if)", v, as_int(v) + 1)
	case "c128": return tp("(%s.0 + %d.0i)", v, as_int(v) + 1)
	case "bset": return tp("(%du)", (1 << u32(as_int(v) % 31)) | 1)
	}
	return v
}

odin_val :: proc(tag, v: string) -> string {
	switch tag {
	case "ptr":  return tp("rawptr(uintptr(%s))", v)
	case "bool": return "true"
	case "enum": return tp("E32(%s)", v)
	case "c64":  return tp("complex64(complex(%s, %d))", v, as_int(v) + 1)
	case "c128": return tp("complex128(complex(%s, %d))", v, as_int(v) + 1)
	case "bset": return tp("(BS{0, %d})", as_int(v) % 31)
	}
	return v
}

// A value the checks MUST reject, for the mutation control.
mutated :: proc(tag, v: string) -> string {
	switch tag {
	case "bool": return "false"
	case "ptr":  return "rawptr(uintptr(999))"
	case "enum": return tp("E32(%d)", as_int(v) + 1)
	case "c64":  return tp("complex64(complex(%d, %d))", as_int(v) + 2, as_int(v) + 1)
	case "c128": return tp("complex128(complex(%d, %d))", as_int(v) + 2, as_int(v) + 1)
	case "bset": return "(BS{2})"
	}
	// every generated float value ends in `.5`, so adding one keeps the form
	if dot := strings.index_byte(v, '.'); dot >= 0 {
		return tp("%d%s", as_int(v[:dot]) + 1, v[dot:])
	}
	return tp("%d", as_int(v) + 1)
}

// core:fmt reads `{` as the start of a format verb and the corpus is mostly
// braces, so they are escaped here rather than at every call site. Every format
// string below can then be written exactly as it should come out.
tp :: proc(format: string, args: ..any) -> string {
	return fmt.tprintf(brace_escape(format), ..args)
}

w :: proc(sb: ^strings.Builder, format: string, args: ..any) {
	fmt.sbprintf(sb, brace_escape(format), ..args)
}

brace_escape :: proc(format: string) -> string {
	if !strings.contains_any(format, "{}") {
		return format
	}
	out, _ := strings.replace_all(format, "{", "{{", context.temp_allocator)
	out, _ = strings.replace_all(out, "}", "}}", context.temp_allocator)
	return out
}

as_int :: proc(s: string) -> int {
	n, ok := strconv.parse_int(s)
	fmt.assertf(ok, "not an integer: %q", s)
	return n
}

leaf :: proc(path, tag: string, i: int) -> Leaf {
	return {path, path, tag, val(i, tag)}
}

leaf2 :: proc(odin_path, c_path, tag, v: string) -> Leaf {
	return {odin_path, c_path, tag, v}
}

// A C member reference. `{}` lets a member be an EXPRESSION rather than a path,
// which is what `__real__ x` needs -- it is a prefix operator.
c_ref :: proc(cp, v: string) -> string {
	if strings.contains(cp, "{}") {
		return sub(cp, v)
	}
	return tp("%s.%s", v, cp)
}

// `{}` -> the variable name.
sub :: proc(s, v: string) -> string {
	out, _ := strings.replace_all(s, "{}", v, context.temp_allocator)
	return out
}

c_conds :: proc(t: Ty, v: string) -> string {
	if len(t.fields) == 0 {
		return "1"
	}
	parts := make([]string, len(t.fields), context.temp_allocator)
	for f, i in t.fields {
		parts[i] = tp("%s == (%s)", c_ref(f.c_path, v), c_val(f.tag, f.val))
	}
	return strings.join(parts, " && ", context.temp_allocator)
}

odin_setters :: proc(t: Ty, v: string) -> []string {
	if len(t.odin_set) > 0 {
		out := make([]string, len(t.odin_set), context.temp_allocator)
		for s, i in t.odin_set {
			out[i] = sub(s, v)
		}
		return out
	}
	out := make([]string, len(t.fields), context.temp_allocator)
	for f, i in t.fields {
		out[i] = tp("%s.%s = %s", v, f.odin_path, odin_val(f.tag, f.val))
	}
	return out
}

odin_getters :: proc(t: Ty, v: string) -> [][2]string {
	if len(t.odin_get) > 0 {
		out := make([][2]string, len(t.odin_get), context.temp_allocator)
		for g, i in t.odin_get {
			out[i] = {sub(g[0], v), g[1]}
		}
		return out
	}
	out := make([][2]string, len(t.fields), context.temp_allocator)
	for f, i in t.fields {
		expected: string
		switch f.tag {
		case "ptr", "bool", "enum", "c64", "c128", "bset":
			expected = odin_val(f.tag, f.val)
		case:
			expected = tp("%s(%s)", scalar(f.tag).odin, f.val)
		}
		out[i] = {tp("%s.%s", v, f.odin_path), expected}
	}
	return out
}

// ---------------------------------------------------------------- corpus

build :: proc() {
	// --- scalar arity 1..4, the merge and by-value/memory boundaries
	combos := [][]string{
		{"i32"}, {"i64"}, {"f32"}, {"f64"}, {"i8"}, {"ptr"},
		{"i32", "i32"}, {"f32", "f32"}, {"f64", "f64"}, {"i64", "f64"},
		{"f64", "i64"}, {"i32", "f32"}, {"f32", "i32"}, {"i8", "i64"},
		{"f32", "f32", "f32"}, {"i32", "i32", "i32"}, {"f64", "f64", "f64"},
		{"i64", "i64", "i64"}, {"f32", "i32", "f32"}, {"i8", "f64", "i8"},
		{"f32", "f32", "f32", "f32"}, {"f64", "f64", "f64", "f64"},
		{"i32", "i32", "i32", "i32"}, {"i64", "i64", "i64", "i64"},
		{"f32", "f32", "f32", "i32"},
		// half, at each arity and mixed: the merge rules turn on the WIDTH of a
		// float member, not just on its being one
		{"f16"}, {"f16", "f16"}, {"f16", "i16"}, {"f16", "f32"},
		{"f16", "f16", "f16"}, {"f16", "f16", "f16", "f16"},
		{"f32", "f16"}, {"f64", "f16"},
		// an enum is only under test if it is explicitly backed: Odin's default
		// is `int`, which is register-sized against C's 4
		{"enum"}, {"enum", "enum"}, {"enum", "f32"}, {"i8", "enum"},
		// the only scalar that spans two eightbytes, and the one that reaches
		// AAPCS64's even-register-pair rule
		{"i128"}, {"i128", "i64"}, {"i8", "i128"}, {"i128", "f64"},
		{"c64"}, {"c128"}, {"c64", "c64"}, {"c64", "f32"}, {"c128", "i64"},
		{"bset"}, {"bset", "bset"}, {"bset", "f32"},
		// the unsigned widths: same size and class as their signed twins, so they are the
		// control on anything that reads signedness where it should not
		{"u8"}, {"u16"}, {"u32"}, {"u64"},
		{"u8", "u32"}, {"u16", "u64"}, {"u32", "f32"}, {"u64", "f64"},
		// a narrow member in FRONT of a complex: the complex aligns to its component, so a wrong
		// component alignment moves it and changes the struct's size. Nothing else here reaches that.
		{"i8", "c64"}, {"i8", "c128"}, {"i16", "c128"},
	}
	for tags in combos {
		odin_members := make([]string, len(tags), context.temp_allocator)
		c_members := make([]string, len(tags), context.temp_allocator)
		fields := make([]Leaf, len(tags))
		for tag, i in tags {
			odin_members[i] = tp("f%d: %s", i, scalar(tag).odin)
			c_members[i] = tp("%s f%d;", scalar(tag).c, i)
			fields[i] = leaf(tp("f%d", i), tag, i)
		}
		add(
			tp("s_%s", strings.join(tags, "_", context.temp_allocator)),
			tp("struct { %s }", strings.join(odin_members, ", ", context.temp_allocator)),
			tp("struct { %s }", strings.join(c_members, " ", context.temp_allocator)),
			fields,
			tier = tier_of(..tags),
		)
	}

	// --- BARE scalars. Every scalar above is a struct MEMBER, and a member never
	// carries a parameter extension attribute: `signext`/`zeroext` exist only on a
	// scalar passed in its own right, and say the CALLER has already widened it to
	// 32 bits. A callee compiled to rely on that reads the untouched high bits.
	// The sub-32-bit widths are the ones that have it; i32 and f32 are the controls
	// that must not.
	for tag in ([]string{
		"i8", "u8", "i16", "u16", "bool", "i32", "u32", "u64", "f32",
		// the kinds whose BARE form asks a different question from their wrapped one: a complex is
		// two floats to the type system and a rule of its own to a psABI, and a bare `f16` is the
		// narrowest float there is
		"f16", "c64", "c128", "ptr", "enum", "bset",
	}) {
		s := scalar(tag)
		v := val(0, tag)
		expected: string
		switch tag {
		case "ptr", "bool", "enum", "c64", "c128", "bset":
			expected = odin_val(tag, v)
		case:
			expected = tp("%s(%s)", s.odin, v)
		}
		add(
			tp("bs_%s", tag),
			s.odin,
			s.c,
			leaves(leaf2("", "{}", tag, v)),
			tier = tier_of(tag),
			odin_set = strs(tp("{} = %s", odin_val(tag, v))),
			odin_get = pairs([2]string{"{}", expected}),
		)
	}

	// --- cstring, the shape every C binding is made of. It is a pointer, but `==` on a cstring
	// has STRING semantics in Odin and would dereference the fabricated address, so the Odin side
	// compares the pointer VALUE while the C side compares the pointer directly.
	{
		v := val(0, "cstring")
		add(
			"bs_cstring", "cstring", "char *",
			leaves(leaf2("", "{}", "cstring", v)),
			odin_set = strs(tp("{} = transmute(cstring)uintptr(%s)", v)),
			odin_get = pairs([2]string{"transmute(uintptr)({})", tp("uintptr(%s)", v)}),
		)
		add(
			"s_cstring", "struct { a: cstring }", "struct { char *a; }",
			leaves(leaf2("a", "a", "cstring", v)),
			odin_set = strs(tp("{}.a = transmute(cstring)uintptr(%s)", v)),
			odin_get = pairs([2]string{"transmute(uintptr)({}.a)", tp("uintptr(%s)", v)}),
		)
	}

	// --- quaternions. There is no C quaternion, but Odin's lowers to four floats in memory:
	// `[x, y, z, w]`. The counterpart is the struct a C binding would actually declare, 
	// and the question this asks is exactly the one interop depends on: does a quaternion
	// travel the way the equivalent four-float struct does?
	//
	// The accessors differ on the two sides (`imag/jmag/kmag/real` against `.x/.y/.z/.w`), which is
	// what `c_path`'s `{}` form and the `odin_get` hatch are for.
	{
		Quat :: struct {
			name:  string,
			odin:  string,
			c_elem: string,
			tag:   string,
			tier:  string,
		}
		quats := []Quat{
			{"q128", "quaternion128", "float",    "f32", TIER_CORE},
			{"q256", "quaternion256", "double",   "f64", TIER_CORE},
			{"q64",  "quaternion64",  "_Float16", "f16", TIER_F16},
		}
		lanes := [4]string{"x", "y", "z", "w"}
		// memory order is x,y,z,w; the accessors for those are imag,jmag,kmag,real
		accessors := [4]string{"imag", "jmag", "kmag", "real"}
		for q in quats {
			fields := make([]Leaf, 4)
			getters := make([][2]string, 4)
			for i in 0 ..< 4 {
				v := val(i, q.tag)
				fields[i] = leaf2("", tp("{}.%s", lanes[i]), q.tag, v)
				getters[i] = {
					tp("%s({})", accessors[i]),
					tp("%s(%s)", scalar(q.tag).odin, v),
				}
			}
			// the same aggregate with a narrow member in front, which is what catches a
			// wrong component alignment: it moves the quaternion and resizes the struct
			off_fields := make([]Leaf, 5)
			off_getters := make([][2]string, 5)
			off_fields[0] = leaf("a", "i8", 0)
			off_getters[0] = {"{}.a", tp("i8(%s)", val(0, "i8"))}
			for i in 0 ..< 4 {
				v := val(i, q.tag)
				off_fields[i + 1] = leaf2("", tp("{}.q.%s", lanes[i]), q.tag, v)
				off_getters[i + 1] = {
					tp("%s({}.q)", accessors[i]),
					tp("%s(%s)", scalar(q.tag).odin, v),
				}
			}
			add(
				tp("off_%s", q.name),
				tp("struct { a: i8, q: %s }", q.odin),
				tp("struct { int8_t a; struct { %s x, y, z, w; } q; }", q.c_elem),
				off_fields,
				tier = q.tier,
				odin_set = strs(
					tp("{}.a = %s", val(0, "i8")),
					tp("{}.q = quaternion(x=%s, y=%s, z=%s, w=%s)",
						val(0, q.tag), val(1, q.tag), val(2, q.tag), val(3, q.tag)),
				),
				odin_get = off_getters,
			)
			add(
				tp("bs_%s", q.name),
				q.odin,
				tp("struct { %s x, y, z, w; }", q.c_elem),
				fields,
				tier = q.tier,
				odin_set = strs(tp("{} = quaternion(x=%s, y=%s, z=%s, w=%s)",
					val(0, q.tag), val(1, q.tag), val(2, q.tag), val(3, q.tag))),
				odin_get = getters,
			)
		}
	}

	// --- arrays: the same eightbytes from one declaration
	for tag in ([]string{"f32", "f64", "i32", "i64", "i8", "f16", "enum", "i128"}) {
		for cnt in 1 ..= 5 {
			fields := make([]Leaf, cnt)
			for i in 0 ..< cnt {
				fields[i] = leaf(tp("a[%d]", i), tag, i)
			}
			add(
				tp("a%d_%s", cnt, tag),
				tp("struct { a: [%d]%s }", cnt, scalar(tag).odin),
				tp("struct { %s a[%d]; }", scalar(tag).c, cnt),
				fields,
				tier = tier_of(tag),
			)
		}
	}

	// --- nesting: same leaves reached through another level
	nests := [][2]string{
		{"f32", "f32"}, {"f64", "f64"}, {"i32", "f32"}, {"f32", "i64"},
		{"f16", "f16"}, {"f16", "i32"},
		// a lone f32 in eightbyte 0 reached through a level, then an f64: the
		// shape #7292 was about
		{"f32", "f64"},
	}
	for pair in nests {
		a, b := pair[0], pair[1]
		add(
			tp("n_%s_%s", a, b),
			tp("struct { i: struct { x: %s, y: %s } }", scalar(a).odin, scalar(b).odin),
			tp("struct { struct { %s x; %s y; } i; }", scalar(a).c, scalar(b).c),
			leaves(leaf("i.x", a, 0), leaf("i.y", b, 1)),
			tier = tier_of(a, b),
		)
		add(
			tp("n2_%s_%s", a, b),
			tp("struct { i: struct { x: %s }, y: %s }", scalar(a).odin, scalar(b).odin),
			tp("struct { struct { %s x; } i; %s y; }", scalar(a).c, scalar(b).c),
			leaves(leaf("i.x", a, 0), leaf("y", b, 1)),
			tier = tier_of(a, b),
		)
	}

	// --- unions, and a union below the top level
	unions := [][2]string{
		{"f32", "i32"}, {"f64", "i64"}, {"f32", "f32"}, {"f64", "f32"},
		{"f16", "i16"}, {"f16", "f32"},
	}
	for pair in unions {
		a, b := pair[0], pair[1]
		add(
			tp("u_%s_%s", a, b),
			tp("struct #raw_union { x: %s, y: %s }", scalar(a).odin, scalar(b).odin),
			tp("union { %s x; %s y; }", scalar(a).c, scalar(b).c),
			leaves(leaf("x", a, 0)),
			tier = tier_of(a, b),
		)
		add(
			tp("su_%s_%s", a, b),
			tp("struct { u: struct #raw_union { x: %s }, y: %s }", scalar(a).odin, scalar(b).odin),
			tp("struct { union { %s x; } u; %s y; }", scalar(a).c, scalar(b).c),
			leaves(leaf("u.x", a, 0), leaf("y", b, 1)),
			tier = tier_of(a, b),
		)
		// TWO members in the nested union. The one-member form above is the case
		// overlap alone cannot detect; this is its control, and it is the shape
		// `test_issue_sysv_abi` pins.
		add(
			tp("su2_%s_%s", a, b),
			tp("struct { u: struct #raw_union { x, y: %s }, z: %s }", scalar(a).odin, scalar(b).odin),
			tp("struct { union { %s x, y; } u; %s z; }", scalar(a).c, scalar(b).c),
			leaves(leaf("u.x", a, 0), leaf("z", b, 1)),
			tier = tier_of(a, b),
		)
	}

	// --- homogeneous float aggregates and the shapes that disqualify them
	for tag in ([]string{"f32", "f64", "f16"}) {
		w, cw := scalar(tag).odin, scalar(tag).c
		abcd := leaves(leaf("a", tag, 0), leaf("b", tag, 1), leaf("c", tag, 2), leaf("d", tag, 3))
		add(
			tp("hfa4_%s", tag),
			tp("struct { a, b, c, d: %s }", w),
			tp("struct { %s a, b, c, d; }", cw),
			abcd,
			tier = tier_of(tag),
		)
		add(
			tp("hfa5_%s", tag),
			tp("struct { a, b, c, d, e: %s }", w),
			tp("struct { %s a, b, c, d, e; }", cw),
			leaves(
				leaf("a", tag, 0), leaf("b", tag, 1), leaf("c", tag, 2),
				leaf("d", tag, 3), leaf("e", tag, 4),
			),
			tier = tier_of(tag),
		)
		// zero-length array member -- disqualifies the HFA
		add(
			tp("zla_%s", tag),
			tp("struct { z: [0]f32, a, b, c, d: %s }", w),
			tp("struct { float z[0]; %s a, b, c, d; }", cw),
			abcd,
			tier = TIER_GNU,
		)
		add(
			tp("zlat_%s", tag),
			tp("struct { a, b, c, d: %s, z: [0]f32 }", w),
			tp("struct { %s a, b, c, d; float z[0]; }", cw),
			abcd,
			tier = TIER_GNU,
		)
		// empty struct member -- does NOT disqualify it
		add(
			tp("esm_%s", tag),
			tp("struct { e: struct {}, a, b, c, d: %s }", w),
			tp("struct { struct {} e; %s a, b, c, d; }", cw),
			abcd,
			tier = TIER_GNU,
		)
	}

	// --- alignment: changes size and placement without changing any field type
	for al in ([]int{2, 4, 8, 16, 32, 64}) {
		// a small struct whose ALIGNMENT is the only thing that varies: same
		// fields, same field offsets, different slot
		add(
			tp("aln%d", al),
			tp("struct #align(%d) { a: i8, b: i32 }", al),
			tp("struct __attribute__((aligned(%d))) { int8_t a; int32_t b; }", al),
			leaves(leaf("a", "i8", 0), leaf("b", "i32", 1)),
			tier = TIER_GNU,
		)
	}
	for al in ([]int{16, 32}) {
		add(
			tp("al%d", al),
			tp("struct #align(%d) { a, b, c: f64 }", al),
			tp("struct __attribute__((aligned(%d))) { double a, b, c; }", al),
			leaves(leaf("a", "f64", 0), leaf("b", "f64", 1), leaf("c", "f64", 2)),
			tier = TIER_GNU,
		)
	}
	// an over-aligned member in TRAILING position, which adds interior padding
	// before it rather than after
	add(
		"oamt",
		"struct #min_field_align(16) { a: f32, b: i8 }",
		"struct { float a; int8_t b __attribute__((aligned(16))); }",
		leaves(leaf("a", "f32", 0), leaf("b", "i8", 1)),
		tier = TIER_GNU,
	)
	add(
		"pk",
		"struct #packed { a: i8, b: i32, c: i64 }",
		"struct __attribute__((packed)) { int8_t a; int32_t b; int64_t c; }",
		leaves(leaf("a", "i8", 0), leaf("b", "i32", 1), leaf("c", "i64", 2)),
		tier = TIER_GNU,
	)
	// `#max_field_align` CAPS a member's alignment where `#packed` removes it
	// entirely, so the struct keeps interior padding but less of it, and its size
	// is not a multiple of the widest member. C spells it `#pragma pack(n)`.
	// `#pragma pack(n)` has no expression form, so the C side caps each member
	// with `packed, aligned(n)`, which is the same rule applied per member.
	for al in ([]int{2, 4}) {
		add(
			tp("mfa%d", al),
			tp("struct #max_field_align(%d) { a: i8, b: i32, c: i64 }", al),
			tp("struct { int8_t a; int32_t b __attribute__((packed, aligned(%d)));" +
				" int64_t c __attribute__((packed, aligned(%d))); }", al, al),
			leaves(leaf("a", "i8", 0), leaf("b", "i32", 1), leaf("c", "i64", 2)),
			tier = TIER_GNU,
		)
	}

	// --- explicit padding, the shape that started this file
	add(
		"pad_i64_f32",
		"struct { a: i64, b: f32 }",
		"struct { int64_t a; float b; }",
		leaves(leaf("a", "i64", 0), leaf("b", "f32", 1)),
	)
	add(
		"pad_f32_f64",
		"struct { a: f32, b: f64 }",
		"struct { float a; double b; }",
		leaves(leaf("a", "f32", 0), leaf("b", "f64", 1)),
	)

	// --- #simd vectors. Three ABIs disagree completely: x86-64 puts a 16-byte
	// one in a single xmm (SSE then SSEUP), AAPCS64 gives it a Q register and
	// lets several form a homogeneous VECTOR aggregate, Win64 passes every
	// vector by reference, and i386 has a separate xmm argument file.
	Vec :: struct {
		tag:   string,
		lanes: int,
	}
	for v in ([]Vec{{"f32", 4}, {"f32", 2}, {"f64", 2}, {"i32", 4}, {"i8", 16}}) {
		ct, cc := scalar(v.tag).odin, scalar(v.tag).c
		fields := make([]Leaf, v.lanes)
		getters := make([][2]string, v.lanes)
		for i in 0 ..< v.lanes {
			fields[i] = leaf(tp("v[%d]", i), v.tag, i)
			getters[i] = {
				tp("simd.extract({}.v, %d)", i),
				tp("%s(%s)", ct, val(i, v.tag)),
			}
		}
		add(
			tp("v%d_%s", v.lanes, v.tag),
			tp("struct { v: #simd[%d]%s }", v.lanes, ct),
			tp("struct { %s v __attribute__((vector_size(%d * sizeof(%s)))); }", cc, v.lanes, cc),
			fields,
			tier = TIER_GNU,
			odin_set = strs(tp("{}.v = {%s}", vals(0, v.lanes, v.tag))),
			odin_get = getters,
		)
	}
	// two vectors: an HVA on AAPCS64, memory on x86-64
	{
		fields := make([]Leaf, 8)
		getters := make([][2]string, 8)
		for i in 0 ..< 4 {
			fields[i] = leaf(tp("a[%d]", i), "f32", i)
			fields[i + 4] = leaf(tp("b[%d]", i), "f32", i + 4)
			getters[i] = {tp("simd.extract({}.a, %d)", i), tp("f32(%s)", val(i, "f32"))}
			getters[i + 4] = {tp("simd.extract({}.b, %d)", i), tp("f32(%s)", val(i + 4, "f32"))}
		}
		add(
			"v4f32x2",
			"struct { a, b: #simd[4]f32 }",
			"struct { float a __attribute__((vector_size(16))), b __attribute__((vector_size(16))); }",
			fields,
			tier = TIER_GNU,
			odin_set = strs(
				tp("{}.a = {%s}", vals(0, 4, "f32")),
				tp("{}.b = {%s}", vals(4, 8, "f32")),
			),
			odin_get = getters,
		)
	}
	// a vector beside a scalar: homogeneous no longer
	{
		fields := make([]Leaf, 5)
		getters := make([][2]string, 5)
		for i in 0 ..< 4 {
			fields[i] = leaf(tp("a[%d]", i), "f32", i)
			getters[i] = {tp("simd.extract({}.a, %d)", i), tp("f32(%s)", val(i, "f32"))}
		}
		fields[4] = leaf("b", "i64", 4)
		getters[4] = {"{}.b", tp("i64(%s)", val(4, "i64"))}
		add(
			"v4f32_i64",
			"struct { a: #simd[4]f32, b: i64 }",
			"struct { float a __attribute__((vector_size(16))); int64_t b; }",
			fields,
			tier = TIER_GNU,
			odin_set = strs(
				tp("{}.a = {%s}", vals(0, 4, "f32")),
				tp("{}.b = %s", val(4, "i64")),
			),
			odin_get = getters,
		)
	}

	// --- BARE vectors, and 4-byte widths.
	//
	// Every vector row above wraps the vector in a struct, and the two are not
	// the same question: `struct{v8f}` returns correctly where a bare
	// `#simd[8]f32` does not. 4-byte widths were absent entirely. Measured
	// against clang on x86-64, the divergence is purely SIZE-driven and
	// independent of the element: 4-byte and >=32-byte diverge, 8- and 16-byte
	// agree. Every 8-byte element type is here for that reason -- LLVM rounds a
	// bare vector's stack slot up to the legal vector width whatever it holds,
	// so one 8-byte row would only have caught the defect for its own element.
	Bare :: struct {
		tag:   string,
		lanes: int,
		cname: string,
		tier:  string,
		// the same width WRAPPED, so the pair is directly comparable
		wrap:  bool,
	}
	bares := []Bare{
		{"i8", 4, "rx_i8x4", TIER_GNU, true},
		{"i8", 8, "rx_i8x8", TIER_GNU, true},
		{"i16", 2, "rx_i16x2", TIER_GNU, true},
		{"i16", 4, "rx_i16x4", TIER_GNU, false},
		{"i32", 2, "rx_i32x2", TIER_GNU, false},
		{"f32", 2, "rx_f32x2", TIER_GNU, false},
		{"i32", 8, "rx_i32x8", TIER_GNU, false},
		{"i64", 4, "rx_i64x4", TIER_GNU, false},
		{"f32", 8, "rx_f32x8", TIER_GNU, false},
		{"f32", 16, "rx_f32x16", TIER_GNU, false},
		{"f16", 2, "rx_f16x2", TIER_F16, true},
	}
	for b in bares {
		ot := scalar(b.tag).odin
		// only the first four lanes are checked; a shifted read moves all of them
		checked := min(b.lanes, 4)
		fields := make([]Leaf, checked)
		getters := make([][2]string, checked)
		for i in 0 ..< checked {
			fields[i] = leaf2("", tp("{}[%d]", i), b.tag, val(i, b.tag))
			getters[i] = {
				tp("simd.extract({}, %d)", i),
				tp("%s(%s)", ot, val(i, b.tag)),
			}
		}
		add(
			tp("bv%d_%s", b.lanes, b.tag),
			tp("#simd[%d]%s", b.lanes, ot),
			b.cname,
			fields,
			tier = b.tier,
			odin_set = strs(tp("{} = {%s}", vals(0, b.lanes, b.tag))),
			odin_get = getters,
		)
	}
	for b in bares {
		if !b.wrap {
			continue
		}
		ot := scalar(b.tag).odin
		checked := min(b.lanes, 4)
		fields := make([]Leaf, checked)
		getters := make([][2]string, checked)
		for i in 0 ..< checked {
			fields[i] = leaf2("", tp("v[%d]", i), b.tag, val(i, b.tag))
			getters[i] = {
				tp("simd.extract({}.v, %d)", i),
				tp("%s(%s)", ot, val(i, b.tag)),
			}
		}
		add(
			tp("wv%d_%s", b.lanes, b.tag),
			tp("struct { v: #simd[%d]%s }", b.lanes, ot),
			tp("struct { %s v; }", b.cname),
			fields,
			tier = b.tier,
			odin_set = strs(tp("{}.v = {%s}", vals(0, b.lanes, b.tag))),
			odin_get = getters,
		)
	}

	// --- bit-fields. A member measured in BITS is neither an integer nor
	// padding: x86-64 merges its eightbyte to INTEGER, and RISC-V's hardware
	// float rule names it explicitly. The BACKING must match C's allocation
	// unit -- `bit_field u8` against `unsigned a:3` is a different type.
	for w in ([][2]int{{3, 5}, {1, 31}, {17, 15}}) {
		w1, w2 := w[0], w[1]
		// the value must fit the width AND leave room for the mutation control
		va := w1 > 1 ? min(5, (1 << uint(w1)) - 1) : 0
		vb := min(9, (1 << uint(w2)) - 1)
		add(
			tp("bf_%d_%d", w1, w2),
			tp("bit_field u32 { a: u32 | %d, b: u32 | %d }", w1, w2),
			tp("struct { unsigned a : %d; unsigned b : %d; }", w1, w2),
			leaves(
				leaf2("a", "a", "u32", tp("%d", va)),
				leaf2("b", "b", "u32", tp("%d", vb)),
			),
		)
	}
	add(
		"bff_f32",
		"struct { f: f32, b: bit_field u32 { a: u32 | 3 } }",
		"struct { float f; struct { unsigned a : 3; } b; }",
		leaves(leaf("f", "f32", 0), leaf2("b.a", "b.a", "u32", "5")),
	)

	// --- matrix, which lowers to an array with its own alignment
	// a matrix aligns to its element, so the counterpart is a plain array
	{
		fields := make([]Leaf, 4)
		for i in 0 ..< 4 {
			fields[i] = leaf2(
				tp("m[%d, %d]", i % 2, i / 2),
				tp("m[%d]", i),
				"f32",
				val(i, "f32"),
			)
		}
		add(
			"m22_f32",
			"struct { m: matrix[2,2]f32 }",
			"struct { float m[4]; }",
			fields,
			tier = TIER_GNU,
		)
	}

	// Complex is covered by the scalar families above, compared as a WHOLE value rather than
	// per lane -- `==` on a complex compares both halves, so a dropped or corrupted half is
	// caught without needing an accessor. The lanes carry DIFFERENT values (`v` and `v+1`)
	// because equal ones would make a swapped real/imag undetectable.
	//
	// Per-lane checks are expressible if a failure ever needs to name which half: `c_ref`'s `{}`
	// form takes an expression rather than a path, so C's prefix `__real__ {}` works, and the
	// Odin side uses the `odin_get` hatch with `real({})`. That was the accessor problem.

	// --- array OF struct: the array rule and the struct rule compose, and a
	// stride bug lives in the composition
	add(
		"aos",
		"struct { a: [2]struct{ x, y: f32 } }",
		"struct { struct { float x, y; } a[2]; }",
		leaves(
			leaf("a[0].x", "f32", 0), leaf("a[0].y", "f32", 1),
			leaf("a[1].x", "f32", 2), leaf("a[1].y", "f32", 3),
		),
	)
	add(
		"aos2",
		"struct { a: [2][2]f32 }",
		"struct { float a[2][2]; }",
		leaves(
			leaf("a[0][0]", "f32", 0), leaf("a[0][1]", "f32", 1),
			leaf("a[1][0]", "f32", 2), leaf("a[1][1]", "f32", 3),
		),
	)

	// --- an over-aligned MEMBER, which leaves an interior gap. A layout walk
	// that sums field sizes gets this wrong and a per-field check catches it.
	add(
		"oam",
		"struct #min_field_align(16) { a: i8, b: f32 }",
		"struct { int8_t a; float b __attribute__((aligned(16))); }",
		leaves(leaf("a", "i8", 0), leaf("b", "f32", 1)),
		tier = TIER_GNU,
	)

	// --- a union whose MEMBERS are aggregates: the merge has two composite
	// candidates for one byte, not two scalars
	add(
		"ua_s2_f64",
		"struct #raw_union { a: struct{ x, y: f32 }, b: f64 }",
		"union { struct { float x, y; } a; double b; }",
		leaves(leaf("a.x", "f32", 0), leaf("a.y", "f32", 1)),
	)
	{
		fields := make([]Leaf, 4)
		for i in 0 ..< 4 {
			fields[i] = leaf(tp("a[%d]", i), "f32", i)
		}
		add(
			"ua_arr",
			"struct #raw_union { a: [4]f32, b: [2]f64 }",
			"union { float a[4]; double b[2]; }",
			fields,
		)
		add(
			"ua_arr_n4",
			"struct #raw_union { a: [4]f32, b: f32 }",
			"union { float a[4]; float b; }",
			fields,
		)
	}
	// The rows above are equal-width, so "the last member's type" happens to give
	// the right answer and cannot detect a classifier that uses it. These two are
	// the pair that can: an aggregate member followed by a NARROWER one, and the
	// same two members the other way round as the control.
	add(
		"ua_arr_n",
		"struct #raw_union { a: [2]f32, b: f32 }",
		"union { float a[2]; float b; }",
		leaves(leaf("a[0]", "f32", 0), leaf("a[1]", "f32", 1)),
	)
	add(
		"ua_arr_w",
		"struct #raw_union { b: f32, a: [2]f32 }",
		"union { float b; float a[2]; }",
		leaves(leaf("a[0]", "f32", 0), leaf("a[1]", "f32", 1)),
	)

	// --- three levels of nesting: SysV flattens, and anything that classifies
	// per top-level member stops early
	add(
		"n3_deep",
		"struct { a: struct{ b: struct{ c: f32, d: f32 } } }",
		"struct { struct { struct { float c, d; } b; } a; }",
		leaves(leaf("a.b.c", "f32", 0), leaf("a.b.d", "f32", 1)),
	)
	add(
		"n3_mix",
		"struct { a: struct{ b: struct{ c: i64 }, d: f32 }, e: f64 }",
		"struct { struct { struct { int64_t c; } b; float d; } a; double e; }",
		leaves(leaf("a.b.c", "i64", 0), leaf("a.d", "f32", 1), leaf("e", "f64", 2)),
	)

	// NOTE: `#packed` with `#align(N)` is rejected by Odin ("'#align' cannot be
	// applied with '#packed'") though C accepts the combination, so there is no
	// shape to compare.

	// --- zero-sized on its own, in argument and return position
	add("empty", "struct { e: struct{} }", "struct { struct {} e; }", nil, tier = TIER_GNU)
	add("zarr", "struct { z: [0]f32 }", "struct { float z[0]; }", nil, tier = TIER_GNU)

	// --- an array OF vectors, and a vector wider than one register
	// The C paths index the vector array directly; only the ODIN side needs the
	// hatch.
	{
		fields := make([]Leaf, 8)
		for i in 0 ..< 8 {
			fields[i] = leaf2("", tp("a[%d][%d]", i / 4, i % 4), "f32", tp("%d.5", i + 1))
		}
		add(
			"av2_f32",
			"struct { a: [2]#simd[4]f32 }",
			"struct { rx_v4f a[2]; }",
			fields,
			tier = TIER_GNU,
			odin_set = strs("{}.a[0] = {1.5, 2.5, 3.5, 4.5}", "{}.a[1] = {5.5, 6.5, 7.5, 8.5}"),
			odin_get = pairs({"simd.extract({}.a[0], 0)", "f32(1.5)"}, {"simd.extract({}.a[1], 3)", "f32(8.5)"}),
		)
	}
	// A wide vector NOT at offset 0. Its alignment decides where it starts, so a
	// wrong alignment moves the member and changes `size_of` -- which is the only
	// way the difference is observable on a target that passes a >16-byte
	// aggregate by POINTER (AAPCS64), where the slot alignment never shows.
	{
		fields := make([]Leaf, 9)
		getters := make([][2]string, 9)
		fields[0] = leaf("a", "i8", 0)
		getters[0] = {"{}.a", "i8(3)"}
		for i in 0 ..< 8 {
			fields[i + 1] = leaf(tp("v[%d]", i), "f32", i)
			getters[i + 1] = {
				tp("simd.extract({}.v, %d)", i),
				tp("f32(%s)", val(i, "f32")),
			}
		}
		add(
			"v8_off",
			"struct { a: i8, v: #simd[8]f32 }",
			"struct { int8_t a; float v __attribute__((vector_size(32))); }",
			fields,
			tier = TIER_GNU,
			odin_set = strs("{}.a = 3", tp("{}.v = {%s}", vals(0, 8, "f32"))),
			odin_get = getters,
		)
	}
	{
		fields := make([]Leaf, 8)
		getters := make([][2]string, 8)
		for i in 0 ..< 8 {
			fields[i] = leaf(tp("v[%d]", i), "f32", i)
			getters[i] = {
				tp("simd.extract({}.v, %d)", i),
				tp("f32(%s)", val(i, "f32")),
			}
		}
		add(
			"v8_f32",
			"struct { v: #simd[8]f32 }",
			"struct { float v __attribute__((vector_size(32))); }",
			fields,
			tier = TIER_GNU,
			odin_set = strs(tp("{}.v = {%s}", vals(0, 8, "f32"))),
			odin_get = getters,
		)
	}

	// --- large, past every by-value threshold
	{
		fields := make([]Leaf, 8)
		for i in 0 ..< 8 {
			fields[i] = leaf(tp("a[%d]", i), "i64", i)
		}
		add("big", "struct { a: [8]i64 }", "struct { int64_t a[8]; }", fields)
	}
}

// `val(lo..<hi)` as an initialiser list body.
vals :: proc(lo, hi: int, tag: string) -> string {
	out := make([]string, hi - lo, context.temp_allocator)
	for i in lo ..< hi {
		out[i - lo] = val(i, tag)
	}
	return strings.join(out, ", ", context.temp_allocator)
}

leaves :: proc(items: ..Leaf) -> []Leaf {
	out := make([]Leaf, len(items))
	copy(out, items)
	return out
}

strs :: proc(items: ..string) -> []string {
	out := make([]string, len(items))
	copy(out, items)
	return out
}

pairs :: proc(items: ..[2]string) -> [][2]string {
	out := make([][2]string, len(items))
	copy(out, items)
	return out
}

// ---------------------------------------------------------------- emit

guard_of :: proc(tier: string) -> string {
	switch tier {
	case TIER_GNU:  return "ABI_TIER_GNU"
	case TIER_F16:  return "ABI_TIER_F16"
	case TIER_I128: return "ABI_TIER_I128"
	}
	return ""
}

// The tier conditions live here. The corpus is guarded by them, `tiers.c` reports them.
TIER_CONDS := [][2]string{
	{TIER_GNU, "defined(__GNUC__)"},
	{TIER_F16, "defined(__FLT16_MANT_DIG__) && !defined(_MSC_VER)"},
	{TIER_I128, "defined(__SIZEOF_INT128__)"},
}

emit_tiers_c :: proc() -> string {
	sb := strings.builder_make()
	strings.write_string(
		&sb,
		`/* GENERATED by tests/abi/gen.odin -- do not edit.
   Preprocess this and grep the markers: it answers which tiers the C
   compiler actually has, so the Odin side can be gated by the same
   answer rather than by a restatement of the condition. */
`,
	)
	for tc in TIER_CONDS {
		name, _ := strings.replace_all(guard_of(tc[0]), "ABI_TIER_", "", context.temp_allocator)
		w(&sb, "#if %s\nABI_YES_%s\n#endif\n", tc[1], name)
	}
	return strings.to_string(sb)
}

C_HEAD :: `/* GENERATED by tests/abi/gen.odin -- do not edit. */
#include <stdint.h>
#include <stdarg.h>

/* Tier guards. A target whose C compiler lacks an extension still runs the
   core corpus; the Odin side is gated by the matching -define. */
@TIER_DEFINES@

/* An enum with an explicit wide enumerator, so it is int-sized rather than
   whatever the compiler picks for a small one. */
enum E32 { E32_LO = 0, E32_HI = 0x7fffffff };

/* ` + "`vector_size`" + ` attaches to the ELEMENT, so an array of vectors needs a name. */
#if defined(__GNUC__)
typedef float rx_v4f __attribute__((vector_size(16)));
/* Named vectors, so a BARE vector row can be ` + "`typedef rx_<x> <name>;`" + `. */
typedef signed char rx_i8x4  __attribute__((vector_size(4)));
typedef signed char rx_i8x8  __attribute__((vector_size(8)));
typedef short       rx_i16x2 __attribute__((vector_size(4)));
typedef short       rx_i16x4 __attribute__((vector_size(8)));
typedef int         rx_i32x2 __attribute__((vector_size(8)));
typedef float       rx_f32x2 __attribute__((vector_size(8)));
typedef int         rx_i32x8 __attribute__((vector_size(32)));
typedef long long   rx_i64x4 __attribute__((vector_size(32)));
typedef float       rx_f32x8 __attribute__((vector_size(32)));
typedef float       rx_f32x16 __attribute__((vector_size(64)));
#endif
#if defined(__FLT16_MANT_DIG__) && !defined(_MSC_VER)
typedef _Float16    rx_f16x2 __attribute__((vector_size(4)));
#endif
`

emit_c :: proc() -> string {
	sb := strings.builder_make()

	defines := strings.builder_make(context.temp_allocator)
	for tc in TIER_CONDS {
		w(&defines, "#if %s\n#define %s 1\n#endif\n", tc[1], guard_of(tc[0]))
	}
	head, _ := strings.replace_all(
		C_HEAD,
		"@TIER_DEFINES@",
		strings.trim_right_space(strings.to_string(defines)),
		context.temp_allocator,
	)
	strings.write_string(&sb, head)

	for t in types {
		g := guard_of(t.tier)
		if g != "" {
			w(&sb, "\n#ifdef %s\n", g)
		}
		w(&sb, "\ntypedef %s %s;\n", t.c, t.name)
		// _arg: return the argument that FOLLOWS the aggregate
		w(&sb, "double %s_arg(%s s, double next) { (void)s; return next; }\n", t.name, t.name)
		// _chk: every field, so a wrong offset is caught as well as a wrong register
		w(&sb, "int %s_chk(%s s) { return (%s) ? 0 : 1; }\n", t.name, t.name, c_conds(t, "s"))
		// _ret: return position
		w(&sb, "%s %s_ret(void) { %s s; ", t.name, t.name, t.name)
		for f in t.fields {
			w(&sb, "%s = (%s); ", c_ref(f.c_path, "s"), c_val(f.tag, f.val))
		}
		strings.write_string(&sb, "return s; }\n")
		// _ex: the aggregate after the argument registers are gone
		w(
			&sb,
			"double %s_ex(int64_t a, int64_t b, int64_t c, int64_t d, int64_t e," +
			" int64_t f, int64_t o, double g, double h, double i, double j, double k," +
			" double l, double m, double n, %s s, double next) {\n",
			t.name,
			t.name,
		)
		strings.write_string(&sb, "\t(void)a;(void)b;(void)c;(void)d;(void)e;(void)f;(void)o;(void)g;(void)h;\n")
		strings.write_string(&sb, "\t(void)i;(void)j;(void)k;(void)l;(void)m;(void)n;(void)s;\n\treturn next;\n}\n")
		// _ex2: SysV has six integer registers but AAPCS64 and RISC-V have eight,
		// so `_ex` only partially fills those. Nine of each exhausts all three.
		w(&sb, "double %s_ex2(%s, %s, %s s, double next) {\n\t",
			t.name, numbered("int64_t q%d", 9), numbered("double w%d", 9), t.name)
		for i in 0 ..< 9 {
			w(&sb, "(void)q%d;", i)
		}
		for i in 0 ..< 9 {
			w(&sb, "(void)w%d;", i)
		}
		strings.write_string(&sb, "(void)s;\n\treturn next;\n}\n")
		// _two: the FIRST aggregate's register consumption decides the second's
		// placement, which nothing with a single aggregate can observe
		w(&sb, "double %s_two(%s s1, %s s2, double next) {\n", t.name, t.name, t.name)
		w(&sb, "\tif (!(%s)) return -1;\n", c_conds(t, "s1"))
		w(&sb, "\tif (!(%s)) return -2;\n\treturn next;\n}\n", c_conds(t, "s2"))
		// _back: the other direction -- C calls an exported Odin callee, which is
		// what a callback does and what nothing else here covers
		w(&sb, "extern double o_%s_take(%s s, double next);\n", t.name, t.name)
		w(&sb, "extern %s o_%s_make(void);\n", t.name, t.name)
		w(&sb, "int %s_back(void) {\n\t%s s; ", t.name, t.name)
		for f in t.fields {
			w(&sb, "%s = (%s); ", c_ref(f.c_path, "s"), c_val(f.tag, f.val))
		}
		w(&sb, "\n\tif (o_%s_take(s, 7) != 7) return 1;\n", t.name)
		w(&sb, "\t%s r = o_%s_make();\n", t.name, t.name)
		w(&sb, "\tif (!(%s)) return 2;\n\treturn 0;\n}\n", c_conds(t, "r"))
		// _can: the aggregate wedged between two stack neighbours, after the
		// registers are gone. `_ex` only checks what follows; a wrongly sized or
		// wrongly aligned slot can equally eat what precedes it, and an
		// over-aligned slot slides the aggregate onto its own neighbour.
		w(
			&sb,
			"double %s_can(int64_t q0, int64_t q1, int64_t q2, int64_t q3," +
			" int64_t q4, int64_t q5, int64_t q6, double w0, double w1, double w2," +
			" double w3, double w4, double w5, double w6, double w7," +
			" int64_t before, %s s, int64_t after, double last) {\n",
			t.name,
			t.name,
		)
		strings.write_string(&sb, "\t(void)q0;(void)q1;(void)q2;(void)q3;(void)q4;(void)q5;(void)q6;\n")
		strings.write_string(&sb, "\t(void)w0;(void)w1;(void)w2;(void)w3;(void)w4;(void)w5;(void)w6;(void)w7;\n")
		strings.write_string(&sb, "\tif (before != 0x1111111111111111LL) return -1;\n")
		strings.write_string(&sb, "\tif (after  != 0x2222222222222222LL) return -2;\n")
		w(&sb, "\tif (!(%s)) return -3;\n\treturn last;\n}\n", c_conds(t, "s"))
		// _can2: same idea as `_can`, but with enough integer fillers to push the
		// aggregate to an outgoing offset that is 16-aligned and NOT 32-aligned.
		// At offset 0 a 16- and a 32-aligned slot coincide, so an over-aligned
		// aggregate is invisible there -- which is why `_can` alone passes on
		// AArch64 while its vector alignment disagrees with clang.
		w(
			&sb,
			"double %s_can2(%s, int64_t before, %s s, int64_t after, double last) {\n\t",
			t.name,
			numbered("int64_t p%d", 11),
			t.name,
		)
		for i in 0 ..< 11 {
			w(&sb, "(void)p%d;", i)
		}
		strings.write_string(&sb, "\n\tif (before != 0x1111111111111111LL) return -1;\n")
		strings.write_string(&sb, "\tif (after  != 0x2222222222222222LL) return -2;\n")
		w(&sb, "\tif (!(%s)) return -3;\n\treturn last;\n}\n", c_conds(t, "s"))
		// _va: the variadic path, which is a separate set of rules -- SysV's AL
		// register count, Win64 duplicating a float into the matching GPR,
		// Darwin-arm64 stacking every variadic argument. A zero-sized type has
		// no meaningful `va_arg`, so it is skipped.
		if len(t.fields) > 0 {
			w(&sb, "double %s_va(int n, ...) {\n\tva_list ap; va_start(ap, n);\n", t.name)
			w(&sb, "\t%s s = va_arg(ap, %s);\n", t.name, t.name)
			strings.write_string(&sb, "\tdouble next = va_arg(ap, double);\n\tva_end(ap);\n")
			w(&sb, "\treturn (%s) ? next : -1;\n}\n", c_conds(t, "s"))
		}
		if g != "" {
			w(&sb, "\n#endif /* %s */\n", g)
		}
	}
	return strings.to_string(sb)
}

// `p0, p1, ... p<n-1>`, from a format holding one %d.
numbered :: proc(format: string, n: int) -> string {
	out := make([]string, n, context.temp_allocator)
	for i in 0 ..< n {
		out[i] = tp(format, i)
	}
	return strings.join(out, ", ", context.temp_allocator)
}

ODIN_HEAD :: `// GENERATED by tests/abi/gen.odin -- do not edit.
//
// Every procedure below asks one question: does Odin place this value where the
// platform C compiler expects it? No ABI is encoded here, so the same corpus is
// valid on SysV, AAPCS64 and Win64 without changing a line.
//
// Three checks per type, because they fail for different reasons:
//   _arg   the value AFTER the aggregate comes back -- catches a wrong size or
//          a wrong number of consumed registers, deterministically rather than
//          by scratch-register luck
//   _chk   every field of the aggregate itself -- catches a wrong offset
//   _ret   the aggregate in return position -- a separate classifier path
package test_abi

import "core:simd"
import "core:testing"
_ :: simd

ABI_TIER_GNU :: #config(ABI_TIER_GNU, true)
ABI_TIER_F16 :: #config(ABI_TIER_F16, true)
ABI_TIER_I128 :: #config(ABI_TIER_I128, true)

// The mutation control. With ` + "`-define:ABI_MUTATE=true`" + ` every type feeds a value
// the C side must reject, so the suite MUST go red. A suite that cannot fail is
// not evidence, and once the defects it currently catches are fixed this is the
// only thing left proving the checks still bite.
ABI_MUTATE :: #config(ABI_MUTATE, false)

// Variadic coverage, OFF by default.
//
// This measures one direction: Odin calling a C variadic. Receiving one is a
// separate mechanism -- a #c_vararg parameter cannot be read directly, and the
// compiler points you at c_va_start / c_va_list; nothing here covers it.
//
// The scalar half of the calling side is correct: the C default-argument promotions 
// are implemented, so i8, u16, f32, bool and every pointer come out matching clang 
// arg for arg. 
//
// What is missing is the step after promotion. An aggregate is handed to LLVM raw
// where clang coerces it per the psABI:
//
//     odin   send(i32 1, { float, float } %h, double 7.0)
//     clang  send(i32 1, <2 x float> %h,      double 7.0)
//
// It is a single defect, but very noisy in the test results as ~75% trip it.
// Turn it on with ` + "`-define:ABI_VARARGS=true`" + ` to measure it.
ABI_VARARGS :: #config(ABI_VARARGS, false)



E32 :: enum i32 { LO = 0, HI = 0x7fffffff }
BS  :: bit_set[0..<31; u32]

foreign import lib "abi_corpus_c.o"
`

// The corpus declarations, identical in the test and the freestanding driver:
// the type, the C functions it calls, and the two callees C calls back into.
emit_odin_decls :: proc(sb: ^strings.Builder, t: Ty, ind: string) {
	w(sb, "%s%s :: %s\n", ind, t.name, t.odin)
	w(sb, "%s@(default_calling_convention=\"c\")\n%sforeign lib {\n", ind, ind)
	w(sb, "%s\t%s_arg :: proc(s: %s, next: f64) -> f64 ---\n", ind, t.name, t.name)
	w(sb, "%s\t%s_chk :: proc(s: %s) -> i32 ---\n", ind, t.name, t.name)
	w(sb, "%s\t%s_ret :: proc() -> %s ---\n", ind, t.name, t.name)
	w(sb, "%s\t%s_ex  :: proc(a, b, c, d, e, f, o: i64, g, h, i, j, k, l, m, n: f64," +
		" s: %s, next: f64) -> f64 ---\n", ind, t.name, t.name)
	w(sb, "%s\t%s_ex2 :: proc(q0, q1, q2, q3, q4, q5, q6, q7, q8: i64," +
		" w0, w1, w2, w3, w4, w5, w6, w7, w8: f64, s: %s, next: f64) -> f64 ---\n", ind, t.name, t.name)
	w(sb, "%s\t%s_two :: proc(s1, s2: %s, next: f64) -> f64 ---\n", ind, t.name, t.name)
	w(sb, "%s\t%s_back :: proc() -> i32 ---\n", ind, t.name)
	w(sb, "%s\t%s_can2 :: proc(p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10: i64," +
		" before: i64, s: %s, after: i64, last: f64) -> f64 ---\n", ind, t.name, t.name)
	w(sb, "%s\t%s_can :: proc(q0, q1, q2, q3, q4, q5, q6: i64," +
		" w0, w1, w2, w3, w4, w5, w6, w7: f64," +
		" before: i64, s: %s, after: i64, last: f64) -> f64 ---\n", ind, t.name, t.name)
	if len(t.fields) > 0 {
		w(sb, "%s\t%s_va  :: proc(n: i32, #c_vararg args: ..any) -> f64 ---\n", ind, t.name)
	}
	w(sb, "%s}\n", ind)
	// the callees C calls back into: the direction a callback uses
	w(sb, "%s@(export) o_%s_take :: proc \"c\" (s: %s, next: f64) -> f64 {\n", ind, t.name, t.name)
	for g in odin_getters(t, "s") {
		w(sb, "%s\tif %s != %s { return -1 }\n", ind, g[0], g[1])
	}
	w(sb, "%s\treturn next\n%s}\n", ind, ind)
	w(sb, "%s@(export) o_%s_make :: proc \"c\" () -> %s {\n%s\ts: %s\n", ind, t.name, t.name, ind, t.name)
	for st in odin_setters(t, "s") {
		w(sb, "%s\t%s\n", ind, st)
	}
	w(sb, "%s\treturn s\n%s}\n", ind, ind)
}

emit_odin :: proc() -> string {
	sb := strings.builder_make()
	strings.write_string(&sb, ODIN_HEAD)
	for t in types {
		g := guard_of(t.tier)
		ind := g != "" ? "\t" : ""
		strings.write_string(&sb, "\n")
		if g != "" {
			w(&sb, "when %s {\n", g)
		}
		emit_odin_decls(&sb, t, ind)
		w(&sb, "%s@(test)\n%stest_%s :: proc(t: ^testing.T) {\n", ind, ind, t.name)
		w(&sb, "%s\ts: %s\n", ind, t.name)
		for st in odin_setters(t, "s") {
			w(&sb, "%s\t%s\n", ind, st)
		}
		// types whose members have no lvalue path (#simd) are set as a whole and
		// cannot be perturbed field-wise, so the control skips them
		if len(t.fields) > 0 && len(t.odin_set) == 0 {
			f := t.fields[0]
			w(&sb, "%s\twhen ABI_MUTATE { s.%s = %s }\n", ind, f.odin_path, mutated(f.tag, f.val))
		}
		w(&sb, "%s\ttesting.expect_value(t, %s_arg(s, 7), f64(7))\n", ind, t.name)
		w(&sb, "%s\ttesting.expect_value(t, %s_chk(s), i32(0))\n", ind, t.name)
		w(&sb, "%s\ttesting.expect_value(t, %s_ex(1,2,3,4,5,6,7, 1,2,3,4,5,6,7,8, s, 7), f64(7))\n", ind, t.name)
		w(&sb, "%s\ttesting.expect_value(t, %s_ex2(1,2,3,4,5,6,7,8,9, 1,2,3,4,5,6,7,8,9, s, 7), f64(7))\n", ind, t.name)
		w(&sb, "%s\ttesting.expect_value(t, %s_two(s, s, 7), f64(7))\n", ind, t.name)
		w(&sb, "%s\ttesting.expect_value(t, %s_can(1,2,3,4,5,6,7, 1,2,3,4,5,6,7,8, 0x1111111111111111, s, 0x2222222222222222, 7), f64(7))\n", ind, t.name)
		w(&sb, "%s\ttesting.expect_value(t, %s_can2(1,2,3,4,5,6,7,8,9,10,11, 0x1111111111111111, s, 0x2222222222222222, 7), f64(7))\n", ind, t.name)
		w(&sb, "%s\ttesting.expect_value(t, %s_back(), i32(0))\n", ind, t.name)
		if len(t.fields) > 0 {
			w(&sb, "%s\twhen ABI_VARARGS {\n", ind)
			w(&sb, "%s\t\ttesting.expect_value(t, %s_va(1, s, f64(7)), f64(7))\n", ind, t.name)
			w(&sb, "%s\t}\n", ind)
		}
		w(&sb, "%s\tr := %s_ret()\n", ind, t.name)
		getters := odin_getters(t, "r")
		if len(getters) == 0 {
			w(&sb, "%s\t_ = r\n", ind)
		}
		for g in getters {
			w(&sb, "%s\ttesting.expect_value(t, %s, %s)\n", ind, g[0], g[1])
		}
		w(&sb, "%s}\n", ind)
		if g != "" {
			strings.write_string(&sb, "}\n")
		}
	}
	return strings.to_string(sb)
}

MAIN_HEAD :: `// GENERATED by tests/abi/gen.odin -- do not edit.
//
// The same corpus as a freestanding driver, for a target with no test runner.
// Exits with the number of failing types, so a cross target can be checked
// under an emulator in CI without core:testing or a thread.
package abi_main

import "core:simd"
_ :: simd

ABI_TIER_GNU :: #config(ABI_TIER_GNU, true)
ABI_TIER_F16 :: #config(ABI_TIER_F16, true)
ABI_TIER_I128 :: #config(ABI_TIER_I128, true)

E32 :: enum i32 { LO = 0, HI = 0x7fffffff }
BS  :: bit_set[0..<31; u32]

// Types at or below this index are skipped, so a runner can enumerate every
// failure by re-running from the last one rather than only seeing a count.
ABI_SKIP :: #config(ABI_SKIP, 0)

// Variadic coverage, OFF by default.
//
// This measures one direction: Odin calling a C variadic. Receiving one is a
// separate mechanism -- a #c_vararg parameter cannot be read directly, and the
// compiler points you at c_va_start / c_va_list; nothing here covers it.
//
// The scalar half of the calling side is correct: the C default-argument promotions 
// are implemented, so i8, u16, f32, bool and every pointer come out matching clang 
// arg for arg. 
//
// What is missing is the step after promotion. An aggregate is handed to LLVM raw
// where clang coerces it per the psABI:
//
//     odin   send(i32 1, { float, float } %h, double 7.0)
//     clang  send(i32 1, <2 x float> %h,      double 7.0)
//
// It is a single defect, but very noisy in the test results as ~75% trip it.
// Turn it on with ` + "`-define:ABI_VARARGS=true`" + ` to measure it.
ABI_VARARGS :: #config(ABI_VARARGS, false)



foreign import lib "../abi_corpus_c.o"
`

emit_main :: proc() -> string {
	sb := strings.builder_make()
	strings.write_string(&sb, MAIN_HEAD)
	body := strings.builder_make(context.temp_allocator)

	for t, idx in types {
		g := guard_of(t.tier)
		ind := g != "" ? "\t" : ""
		strings.write_string(&sb, "\n")
		if g != "" {
			w(&sb, "when %s {\n", g)
		}
		emit_odin_decls(&sb, t, ind)
		w(&sb, "%scheck_%s :: proc \"contextless\" () -> i32 {\n", ind, t.name)
		w(&sb, "%s\ts: %s\n", ind, t.name)
		for st in odin_setters(t, "s") {
			w(&sb, "%s\t%s\n", ind, st)
		}
		w(&sb, "%s\tif %s_arg(s, 7) != 7 { return 1 }\n", ind, t.name)
		w(&sb, "%s\tif %s_chk(s) != 0 { return 1 }\n", ind, t.name)
		w(&sb, "%s\tif %s_ex(1,2,3,4,5,6,7, 1,2,3,4,5,6,7,8, s, 7) != 7 { return 1 }\n", ind, t.name)
		w(&sb, "%s\tif %s_ex2(1,2,3,4,5,6,7,8,9, 1,2,3,4,5,6,7,8,9, s, 7) != 7 { return 1 }\n", ind, t.name)
		w(&sb, "%s\tif %s_two(s, s, 7) != 7 { return 1 }\n", ind, t.name)
		w(&sb, "%s\tif %s_can(1,2,3,4,5,6,7, 1,2,3,4,5,6,7,8, 0x1111111111111111, s, 0x2222222222222222, 7) != 7 { return 1 }\n", ind, t.name)
		w(&sb, "%s\tif %s_can2(1,2,3,4,5,6,7,8,9,10,11, 0x1111111111111111, s, 0x2222222222222222, 7) != 7 { return 1 }\n", ind, t.name)
		w(&sb, "%s\tif %s_back() != 0 { return 1 }\n", ind, t.name)
		w(&sb, "%s\tr := %s_ret()\n", ind, t.name)
		getters := odin_getters(t, "r")
		if len(getters) == 0 {
			w(&sb, "%s\t_ = r\n", ind)
		}
		for gt in getters {
			w(&sb, "%s\tif %s != %s { return 1 }\n", ind, gt[0], gt[1])
		}
		w(&sb, "%s\treturn 0\n%s}\n", ind, ind)
		if g != "" {
			strings.write_string(&sb, "}\n")
		}

		n := idx + 1
		chk := tp("if %d > ABI_SKIP && check_%s() != 0 { return %d }", n, t.name, n)
		if g != "" {
			w(&body, "\twhen %s { %s }\n", g, chk)
		} else {
			w(&body, "\t%s\n", chk)
		}
	}

	strings.write_string(&sb, "\n@(export)\nprobe_main :: proc \"c\" () -> i32 {\n")
	strings.write_string(&sb, strings.to_string(body))
	strings.write_string(&sb, "\treturn 0\n}\n")
	strings.write_string(&sb, "\n// index -> name\n")
	for t, idx in types {
		w(&sb, "// %d\t%s\n", idx + 1, t.name)
	}
	return strings.to_string(sb)
}

// ---------------------------------------------------------------- main

main :: proc() {
	// Written into the caller's build directory, not the source tree: nothing
	// generated is checked in, so the two languages cannot drift apart.
	dir := len(os.args) > 1 ? os.args[1] : "."

	build()

	write :: proc(dir, name, content: string) {
		path := tp("%s/%s", dir, name)
		if err := os.write_entire_file(path, content); err != nil {
			fmt.eprintfln("could not write %s: %v", path, err)
			os.exit(1)
		}
	}
	write(dir, "abi_corpus.c", emit_c())
	write(dir, "abi_corpus.odin", emit_odin())
	write(dir, "abi_main.odin", emit_main())
	write(dir, "tiers.c", emit_tiers_c())

	c_funcs := 0
	for t in types {
		c_funcs += len(t.fields) > 0 ? 8 : 7
	}
	fmt.printfln("%d types, %d C functions, %d Odin callees", len(types), c_funcs, len(types) * 2)
}
