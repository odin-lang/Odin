package test_core_json_differential

import "core:encoding/json"
import "core:fmt"
import "core:math/rand"
import "core:reflect"
import "core:strings"

// Input generation. Everything is drawn from `context.random_generator`, which the test runner
// seeds and logs, so a failure reproduces with `-define:ODIN_TEST_RANDOM_SEED=n`.
//
// The generator is type-directed: given a target type it mostly writes JSON that fits it, so the
// unmarshaller gets past validation and into its reflection paths. `chaos` is the percentage
// chance that any value is replaced by something unexpected, and `noise` the percentage chance
// that a piece of a string literal is lexically invalid (control bytes, bad UTF-8, bad escapes).
// In `exact` mode the generator only writes values the target type accepts, so unmarshalling a
// large struct does not stop at the first deliberately mismatched field.

Gen :: struct {
	b:     strings.Builder,
	spec:  json.Specification,
	depth: int,
	chaos: int,
	noise: int,
	exact: bool,
}

MAX_DEPTH :: 5

SPECS := [?]json.Specification{.JSON, .JSON5, .MJSON}

STRING_PIECES := [?]string{
	"a", "hello", "Hello World", "0123", " ", "_", "key", "Name", "Red",
	"é", "ß", "中文", "🦉", "\u00a0",
	`\n`, `\t`, `\r`, `\b`, `\f`, `\/`, `\\`, `\"`, `\'`,
	`\u0041`, `\u00e9`, `\u00E9`, `\u4e2d`, `\uD83E\uDD89`, `\u0000`, `\u001f`,
}

JSON5_PIECES := [?]string{
	`\x41`, `\xe9`, `\0`, `\v`, "\\\n", "\\\r\n",
}

NOISE_PIECES := [?]string{
	"\x01", "\x1f", "\t", "\r", "\n", "\x7f", "\x00",
	"\x80", "\xc0\xaf", "\xed\xa0\x80", "\xf4\x90\x80\x80", "\xff", "\xe2\x82",
	`\uDC00`, `\uD800`, `\uD800\u0041`, `\uzzzz`, `\u12G4`, `\q`, `\u12`, `\x4`, `\xZZ`, `\8`,
}

INTEGERS := [?]string{
	"0", "1", "-1", "7", "42", "-42",
	"127", "128", "-128", "-129", "255", "256",
	"32767", "32768", "-32769", "65535", "65536",
	"2147483647", "2147483648", "-2147483648", "-2147483649", "4294967295", "4294967296",
	"9223372036854775807", "9223372036854775808", "-9223372036854775808", "-9223372036854775809",
	"18446744073709551615", "18446744073709551616",
	"170141183460469231731687303715884105727", "170141183460469231731687303715884105728",
	"-170141183460469231731687303715884105728", "-170141183460469231731687303715884105729",
	"340282366920938463463374607431768211455", "340282366920938463463374607431768211456",
	"123456789012345678901234567890123456789012345",
	"007", "-007", "00", "-0",
}

JSON5_INTEGERS := [?]string{
	"+5", "+0", "0x1F", "0XfF", "-0x10", "+0x10", "0x", "0x_1", "0xg",
	"0xFFFFFFFFFFFFFFFF", "0x10000000000000000",
}

FLOATS := [?]string{
	"0.0", "-0.0", "1.5", "-2.25", "3.14159", "1e10", "1E-5", "-2.5e+3",
	"1e308", "1e309", "-1e309", "4.9e-324", "5e-325", "2.2250738585072014e-308",
	"123456789012345678901234567890.5", "0.1", "0.30000000000000004",
	"1.0", "100.0", "-5.0", "1.", "1e", "1e+", "1.0e", "0.5e-", "01.5",
}

JSON5_FLOATS := [?]string{
	".5", "-.5", "+.5", "5.", "+1.5",
	"Infinity", "-Infinity", "NaN", "-NaN", "+Infinity", "+NaN", "Infinityx", "-Inf",
}

IDENTS := [?]string{"abc", "True", "nil", "undefined", "Red", "null_", "_x"}

RANDOM_KEYS := [?]string{
	"", "unknown", "NAME", "name ", "a", "b", "c", "id", "tag", "Name", "name", "n", "plain",
	"alias", "-", "ignored", "other", "other_name", "x", "_", "0", "123", "-1",
	"Red", "Green", "Blue", "red", "é", "null", "true", "inner", "s", "i8_",
}

MUTATION_ALPHABET := "{}[]:,\"'\\/*= \t\n\r0123456789.-+eExXabcfnlrstuINaNy_\x00\x80\xff"

chance :: proc(percent: int) -> bool {
	return rand.int_max(100) < percent
}

// A deliberate mismatch between the JSON and the target type, never taken in `exact` mode.
odd :: proc(g: ^Gen, percent: int) -> bool {
	return !g.exact && chance(percent)
}

pick :: proc(options: []string) -> string {
	return rand.choice(options)
}

write :: proc(g: ^Gen, s: string) {
	strings.write_string(&g.b, s)
}

is_identifier :: proc(s: string) -> bool {
	if s == "" {
		return false
	}
	for c, i in transmute([]byte)s {
		switch c {
		case 'A'..='Z', 'a'..='z', '_':
		case '0'..='9':
			if i == 0 {
				return false
			}
		case:
			return false
		}
	}
	return true
}

// Writes optional whitespace and comments. In MJSON a newline after a value inserts a comma, so
// `newline_ok` says whether that is harmless at this point.
gen_space :: proc(g: ^Gen, newline_ok: bool) {
	if !chance(40) {
		return
	}
	relaxed := g.spec != .JSON || chance(g.chaos)
	for _ in 0..<1+rand.int_max(3) {
		switch rand.int_max(10) {
		case 0..=3: write(g, " ")
		case 4:     write(g, "\t")
		case 5:     write(g, "\n" if newline_ok || chance(g.chaos) else " ")
		case 6:     write(g, "\r\n" if newline_ok || chance(g.chaos) else "\r")
		case 7:     write(g, pick({"\v", "\f"}))
		case 8:
			if relaxed {
				write(g, pick({"\u2028", "\u2029", "\uFEFF"}))
			}
		case 9:
			if relaxed {
				if newline_ok && chance(50) {
					write(g, "// line comment\n")
				} else {
					write(g, pick({"/* block */", "/* multi\nline */", "/**/"}))
				}
			}
		}
	}
}

gen_string_piece :: proc(g: ^Gen, quote: byte) {
	switch {
	case chance(g.noise):
		write(g, pick(NOISE_PIECES[:]))
	case g.spec != .JSON && chance(10):
		// `is_valid` only accepts the line continuations.
		write(g, pick({"\\\n", "\\\r\n"}) if g.exact else pick(JSON5_PIECES[:]))
	case chance(5):
		// The other quote character is an ordinary byte inside the string.
		write(g, "'" if quote == '"' else `"`)
	case:
		write(g, pick(STRING_PIECES[:]))
	}
}

gen_quote :: proc(g: ^Gen) -> byte {
	if (g.spec != .JSON && chance(15)) || chance(g.chaos/4) {
		return '\''
	}
	return '"'
}

gen_string :: proc(g: ^Gen) {
	quote := gen_quote(g)
	strings.write_byte(&g.b, quote)
	for _ in 0..<rand.int_max(6) {
		gen_string_piece(g, quote)
	}
	strings.write_byte(&g.b, quote)
}

// Writes `body` as a string literal, sometimes spelling ASCII bytes as `\u` escapes.
gen_quoted :: proc(g: ^Gen, body: string) {
	quote := gen_quote(g)
	strings.write_byte(&g.b, quote)
	escape := chance(15)
	for c in transmute([]byte)body {
		if (escape && c < 0x80 && chance(30)) || c == quote || c == '\\' || c < ' ' {
			fmt.sbprintf(&g.b, `\u%04x` if chance(50) else `\u%04X`, c)
		} else {
			strings.write_byte(&g.b, c)
		}
	}
	strings.write_byte(&g.b, quote)
}

gen_random_digits :: proc(g: ^Gen, n: int) {
	for _ in 0..<n {
		strings.write_byte(&g.b, '0' + byte(rand.int_max(10)))
	}
}

gen_integer :: proc(g: ^Gen) {
	switch {
	case (g.spec != .JSON || chance(g.chaos)) && chance(15):
		write(g, pick(JSON5_INTEGERS[:]))
	case chance(50):
		write(g, pick(INTEGERS[:]))
	case:
		if chance(30) {
			write(g, "-")
		}
		strings.write_byte(&g.b, '1' + byte(rand.int_max(9)))
		gen_random_digits(g, rand.int_max(22))
	}
}

gen_float :: proc(g: ^Gen) {
	switch {
	case (g.spec != .JSON || chance(g.chaos)) && chance(15):
		write(g, pick(JSON5_FLOATS[:]))
	case chance(40):
		write(g, pick(FLOATS[:]))
	case:
		if chance(30) {
			write(g, "-")
		}
		gen_random_digits(g, 1+rand.int_max(8))
		write(g, ".")
		gen_random_digits(g, 1+rand.int_max(12))
		if chance(30) {
			write(g, pick({"e", "E", "e-", "e+", "E-"}))
			gen_random_digits(g, 1+rand.int_max(3))
		}
	}
}

gen_number :: proc(g: ^Gen) {
	if chance(50) {
		gen_integer(g)
	} else {
		gen_float(g)
	}
}

// A number inside a string literal, which `unmarshal_string_token` parses for numeric targets.
gen_quoted_number :: proc(g: ^Gen, integer: bool) {
	inner := Gen{spec = g.spec, chaos = g.chaos}
	strings.builder_init(&inner.b, context.temp_allocator)
	if integer {
		gen_integer(&inner)
	} else {
		gen_float(&inner)
	}
	gen_quoted(g, strings.to_string(inner.b))
}

gen_separator :: proc(g: ^Gen) {
	gen_space(g, false)
	switch {
	case g.spec == .MJSON && chance(30):
		write(g, "\n")
	case g.spec != .JSON && chance(10):
		// Commas are optional between JSON5 and MJSON elements.
		write(g, " ")
	case chance(g.chaos/4):
		write(g, pick({",,", ";", ""}))
	case:
		write(g, ",")
	}
	gen_space(g, true)
}

gen_array :: proc(g: ^Gen, elem: ^reflect.Type_Info, count: int) {
	write(g, "[")
	g.depth += 1
	for i in 0..<count {
		gen_space(g, true)
		gen_value(g, elem)
		if i+1 < count {
			gen_separator(g)
		} else if (g.spec != .JSON || chance(g.chaos)) && chance(20) {
			write(g, ",")
		}
	}
	gen_space(g, true)
	write(g, "]")
	g.depth -= 1
}

Entry :: struct {
	key:  string,
	type: ^reflect.Type_Info, // nil means any value
}

gen_key :: proc(g: ^Gen, name: string) {
	name := name
	if chance(g.chaos) {
		name = pick(RANDOM_KEYS[:])
	}
	if (g.spec != .JSON || chance(g.chaos)) && is_identifier(name) && chance(30) {
		write(g, name)
	} else {
		gen_quoted(g, name)
	}
	gen_space(g, false)
	write(g, "=" if g.spec == .MJSON && chance(30) else ":")
	gen_space(g, true)
}

gen_object_body :: proc(g: ^Gen, entries: []Entry) {
	for e, i in entries {
		gen_space(g, true)
		gen_key(g, e.key)
		gen_value(g, e.type)
		if i+1 < len(entries) {
			gen_separator(g)
		} else if (g.spec != .JSON || chance(g.chaos)) && chance(20) {
			write(g, ",")
		}
	}
	gen_space(g, true)
}

gen_object :: proc(g: ^Gen, entries: []Entry) {
	write(g, "{")
	g.depth += 1
	gen_object_body(g, entries)
	g.depth -= 1
	write(g, "}")
}

random_entries :: proc(g: ^Gen, value_type: ^reflect.Type_Info, key_type: ^reflect.Type_Info) -> []Entry {
	entries := make([dynamic]Entry, 0, 8, context.temp_allocator)
	for _ in 0..<rand.int_max(5) {
		key: string
		switch {
		case key_type != nil && reflect.is_integer(key_type) && g.exact:
			key = fmt.tprintf("%d", rand.int_max(1000) - 500)
		case key_type != nil && reflect.is_integer(key_type) && !chance(10):
			inner := Gen{spec = g.spec}
			strings.builder_init(&inner.b, context.temp_allocator)
			gen_integer(&inner)
			key = strings.to_string(inner.b)
		case chance(70):
			key = pick(RANDOM_KEYS[:])
		case:
			key = fmt.tprintf("k%d", rand.int_max(1000))
		}
		append(&entries, Entry{key, value_type})
	}
	return entries[:]
}

// Collects the keys a struct accepts, descending into `using _` fields like the unmarshaller.
struct_entries :: proc(g: ^Gen, entries: ^[dynamic]Entry, ti: ^reflect.Type_Info) {
	for field in reflect.struct_fields_zipped(ti.id) {
		if field.is_using && field.name == "_" {
			struct_entries(g, entries, field.type)
			continue
		}
		if !chance(80) {
			continue
		}
		name := field.name
		if tag := json_name(field.tag); tag != "" && !chance(10) {
			name = tag
		}
		append(entries, Entry{name, field.type})
		if chance(5) {
			append(entries, Entry{name, field.type}) // duplicate key
		}
	}
}

json_name :: proc(tag: reflect.Struct_Tag) -> string {
	name := reflect.struct_tag_get(tag, "json")
	if comma := strings.index_byte(name, ','); comma >= 0 {
		name = name[:comma]
	}
	return name
}

// The type of the field that `unmarshal_object` stores `key` in, or nil if it skips the key:
// a `json` tag match wins, then an untagged field's name, then fields of `using _` members.
resolve_key :: proc(ti: ^reflect.Type_Info, key: string) -> ^reflect.Type_Info {
	fields := reflect.struct_fields_zipped(ti.id)
	for f in fields {
		if json_name(f.tag) == key {
			return f.type
		}
	}
	for f in fields {
		if json_name(f.tag) == "" && f.name == key {
			return f.type
		}
	}
	resolve_using :: proc(ti: ^reflect.Type_Info, key: string) -> ^reflect.Type_Info {
		for f in reflect.struct_fields_zipped(ti.id) {
			if f.is_using && f.name == "_" {
				if t := resolve_using(f.type, key); t != nil {
					return t
				}
			}
			name := json_name(f.tag)
			if (name == "" && f.name == key) || name == key {
				return f.type
			}
		}
		return nil
	}
	return resolve_using(ti, key)
}

gen_struct_entries :: proc(g: ^Gen, ti: ^reflect.Type_Info) -> []Entry {
	entries := make([dynamic]Entry, 0, 16, context.temp_allocator)
	struct_entries(g, &entries, ti)
	if g.exact {
		for &e in entries {
			e.type = resolve_key(ti, e.key)
		}
	}
	if chance(30) {
		// Most of RANDOM_KEYS name real fields, which would then get a random value.
		append(&entries, Entry{fmt.tprintf("unknown_%d", rand.int_max(10)) if g.exact else pick(RANDOM_KEYS[:]), nil})
	}
	if chance(20) {
		rand.shuffle(entries[:])
	}
	return entries[:]
}

gen_random_value :: proc(g: ^Gen) {
	limit := 10 if g.depth < MAX_DEPTH else 6
	switch rand.int_max(limit) {
	case 0: write(g, "null")
	case 1: write(g, pick({"true", "false"}))
	case 2: gen_integer(g)
	case 3: gen_float(g)
	case 4: gen_string(g)
	case 5:
		if g.spec == .MJSON || chance(g.chaos) {
			write(g, pick(IDENTS[:]))
		} else {
			gen_string(g)
		}
	case 6, 7: gen_array(g, nil, rand.int_max(4))
	case 8, 9: gen_object(g, random_entries(g, nil, nil))
	}
}

gen_value :: proc(g: ^Gen, ti: ^reflect.Type_Info) {
	if ti == nil || ti.id == json.Value || chance(g.chaos) {
		gen_random_value(g)
		return
	}
	if chance(3) {
		write(g, "null")
		return
	}

	base := reflect.type_info_base(ti)
	#partial switch info in base.variant {
	case reflect.Type_Info_Integer:
		switch {
		case odd(g, 10): gen_quoted_number(g, true)
		case odd(g, 10): gen_float(g)
		case:            gen_integer(g)
		}
	case reflect.Type_Info_Float:
		switch {
		case odd(g, 10):  gen_quoted_number(g, chance(50))
		case chance(30): gen_integer(g)
		case:            gen_float(g)
		}
	case reflect.Type_Info_Rune:
		if odd(g, 30) {
			gen_quoted(g, pick({"", "ab", "a🦉"}))
		} else {
			gen_quoted(g, pick({"a", "é", "🦉", "\n", "A"}))
		}
	case reflect.Type_Info_Complex:
		switch {
		case odd(g, 10): gen_array(g, type_info_of(f64), 3)
		case chance(50): gen_number(g)
		case:            gen_array(g, type_info_of(f64), 2)
		}
	case reflect.Type_Info_Quaternion:
		gen_number(g)
	case reflect.Type_Info_Boolean:
		write(g, pick({"true", "false"}))
	case reflect.Type_Info_String:
		switch {
		case g.spec == .MJSON && chance(10): write(g, pick(IDENTS[:]))
		case odd(g, 5):                       gen_number(g)
		case:                                 gen_string(g)
		}
	case reflect.Type_Info_Enum:
		switch rand.int_max(10) {
		case 0..=6:
			name := rand.choice(info.names) if len(info.names) > 0 else "x"
			if chance(10) {
				name = pick(RANDOM_KEYS[:])
			}
			gen_quoted(g, name)
		case 7:
			write(g, rand.choice(info.names) if g.spec == .MJSON && len(info.names) > 0 else "0")
		case:
			gen_integer(g)
		}
	case reflect.Type_Info_Bit_Set, reflect.Type_Info_Bit_Field:
		if chance(70) {
			fmt.sbprintf(&g.b, "%d", rand.int_max(1 << 16))
		} else {
			gen_integer(g)
		}
	case reflect.Type_Info_Array:
		gen_array(g, info.elem, rand.int_max(info.count+(1 if g.exact else 2)))
	case reflect.Type_Info_Enumerated_Array:
		if chance(70) {
			index := reflect.type_info_base(info.index).variant.(reflect.Type_Info_Enum)
			entries := make([dynamic]Entry, 0, len(index.names)+1, context.temp_allocator)
			for name in index.names {
				if chance(70) {
					append(&entries, Entry{name, info.elem})
				}
			}
			if odd(g, 10) {
				append(&entries, Entry{pick(RANDOM_KEYS[:]), info.elem})
			}
			gen_object(g, entries[:])
		} else {
			gen_array(g, info.elem, rand.int_max(info.count+(1 if g.exact else 2)))
		}
	case reflect.Type_Info_Slice:
		gen_array(g, info.elem, rand.int_max(5) if chance(90) else rand.int_max(12))
	case reflect.Type_Info_Dynamic_Array:
		gen_array(g, info.elem, rand.int_max(5) if chance(90) else rand.int_max(12))
	case reflect.Type_Info_Fixed_Capacity_Dynamic_Array:
		gen_array(g, info.elem, rand.int_max(info.capacity+(1 if g.exact else 2)))
	case reflect.Type_Info_Map:
		gen_object(g, random_entries(g, info.value, info.key))
	case reflect.Type_Info_Struct:
		switch {
		case .raw_union not_in info.flags: gen_object(g, gen_struct_entries(g, base))
		case g.exact:                       write(g, "null")
		case:                               gen_random_value(g)
		}
	case reflect.Type_Info_Union:
		if len(info.variants) == 0 || chance(5) {
			write(g, "null")
		} else {
			gen_value(g, rand.choice(info.variants))
		}
	case reflect.Type_Info_Pointer:
		if odd(g, 10) {
			gen_random_value(g)
		} else {
			write(g, "null")
		}
	case:
		gen_random_value(g)
	}
}

// Generates a whole document for `ti` (nil means any value) in the style of `spec`.
generate :: proc(ti: ^reflect.Type_Info, spec: json.Specification, chaos, noise: int, exact := false) -> []byte {
	g := Gen{spec = spec, chaos = chaos, noise = noise, exact = exact}
	strings.builder_init(&g.b, context.temp_allocator)

	if chance(3) {
		write(&g, "\uFEFF")
	}
	gen_space(&g, true)

	base := reflect.type_info_base(ti) if ti != nil else nil
	root_object := false
	if spec == .MJSON && base != nil && chance(50) {
		#partial switch info in base.variant {
		case reflect.Type_Info_Struct:
			root_object = .raw_union not_in info.flags
			if root_object {
				gen_object_body(&g, gen_struct_entries(&g, base))
			}
		case reflect.Type_Info_Map:
			root_object = true
			gen_object_body(&g, random_entries(&g, info.value, info.key))
		}
	}
	if !root_object {
		gen_value(&g, ti)
	}

	gen_space(&g, true)
	if chance(3) {
		write(&g, pick({"x", "]", "}", ",", "1", "\x00"}))
	}
	return g.b.buf[:]
}

// Applies one to three random byte-level edits to a copy of `data`.
mutate :: proc(data: []byte) -> []byte {
	buf := make([dynamic]byte, 0, len(data)+32, context.temp_allocator)
	append(&buf, ..data)
	for _ in 0..<1+rand.int_max(3) {
		n := len(buf)
		if n == 0 {
			append(&buf, MUTATION_ALPHABET[rand.int_max(len(MUTATION_ALPHABET))])
			continue
		}
		i := rand.int_max(n)
		switch rand.int_max(6) {
		case 0:
			ordered_remove(&buf, i)
		case 1:
			inject_at(&buf, i, MUTATION_ALPHABET[rand.int_max(len(MUTATION_ALPHABET))])
		case 2:
			buf[i] = MUTATION_ALPHABET[rand.int_max(len(MUTATION_ALPHABET))]
		case 3:
			span := buf[i:min(n, i+1+rand.int_max(16))]
			tmp := make([]byte, len(span), context.temp_allocator)
			copy(tmp, span)
			inject_at(&buf, rand.int_max(n+1), ..tmp)
		case 4:
			resize(&buf, i)
		case 5:
			j := rand.int_max(n)
			buf[i], buf[j] = buf[j], buf[i]
		}
	}
	return buf[:]
}

random_bytes :: proc(max_len: int) -> []byte {
	buf := make([]byte, rand.int_max(max_len+1), context.temp_allocator)
	for &c in buf {
		if chance(90) {
			c = MUTATION_ALPHABET[rand.int_max(len(MUTATION_ALPHABET))]
		} else {
			c = byte(rand.uint32())
		}
	}
	return buf
}

// Inputs that sit on the quirks of the current implementation.
SEED_CORPUS := [?]string{
	``, ` `, `null`, `true`, `false`, `0`, `-0`, `1.`, `01`, `1e`, `1e+`, `.5`, `5.`, `+5`,
	`0x1F`, `0x`, `0xg`, `-`, `+`, `--1`, `1.5.5`,
	`Infinity`, `-Infinity`, `+Infinity`, `NaN`, `-NaN`, `infinity`,
	`""`, `"`, `"abc`, `"a\"b"`, `'a'`, `'a"b'`, `"a'b"`, `"\u0041"`, `"\uzzzz"`, `"\u12"`,
	`"\uD83E\uDD89"`, `"\uD800"`, `"\x41\0\v"`, `"a\qb"`,
	"\"a\\\nb\"", "\"a\\\r\nb\"", "\"tab\there\"", "\"\x80\"", "\"\xed\xa0\x80\"", "\"a\nb\"",
	`[]`, `[1,]`, `[1 2]`, `[,]`, `[1,,2]`, `[1`, `]`,
	`{}`, `{"a":1,}`, `{a:1}`, `{'a':1}`, `{"a" 1}`, `{"a":1 "b":2}`, `{"a"=1}`, `{"a":1}{`,
	`[1] x`, `{"a":{"b":[1,{"c":null}]}}`, `{"":1}`, `{null:1}`, `{true:1}`,
	"a = 1\nb = 2", "a: 1, b: [1\n2\n3]", "a\n: 1", "\uFEFF{}", "{\x00}",
	"// c\n1", "/* c */ 1", "/* unterminated", "1 // trailing", "[1\n,2]", "{\"a\":1\n}",
	"\u2028[1]", "[\v1\f]",
	`{"Name":"x","name":"y","plain":3,"alias":4}`, `{"id":1,"tag":"t","Base":{}}`,
	`{"n":1,"count":2,"-":3,"ignored":4,"other_name":5,"other":6,"empty":7,"":8}`,
	`{"i8_":128,"u8_":-1,"i128_":170141183460469231731687303715884105728}`,
	`{"color":"Green","sparse":"C","colors":5,"earr":{"Red":1,"Blue":2},"r":"🦉"}`,
	`{"c64":[1,2],"c128":3,"q128":4,"fixed":[1,2,3,4,5],"arr":[1,2,3,4]}`,
	`{"m_int":{"1":"a","x":"b"},"m_u8":{"300":1},"m_cs":{"k":true}}`,
	`{"mixed":{"a":1},"no_nil":2.5,"maybe":3,"raw":1,"ptr":null}`,
}
