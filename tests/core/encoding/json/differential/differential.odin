package test_core_json_differential

// Differential fuzzing of `core:encoding/json` against a frozen copy of itself (`../reference`).
//
// Every input goes through both packages and everything observable is compared: each token
// (kind, text, position, error) and the public tokenizer state, `is_valid`, `parse`,
// `unquote_string`, and `unmarshal` (the returned error, including the token inside an
// `Unsupported_Type_Error`, plus a deep comparison of everything written to the target).
//
//	odin test tests/core/encoding/json/differential -o:speed -define:JSON_DIFF_ITERATIONS=100000
//
// The runner logs its random seed; reproduce a failure with -define:ODIN_TEST_RANDOM_SEED=n.

import "core:encoding/json"
import "core:fmt"
import "core:log"
import "core:math/rand"
import "core:mem"
import "core:mem/virtual"
import "core:reflect"
import "core:slice"
import "core:strings"
import "core:testing"
import ref "../reference"

ITERATIONS   :: #config(JSON_DIFF_ITERATIONS, 1000)
MAX_FAILURES :: #config(JSON_DIFF_MAX_FAILURES, 5)

// The public `Tokenizer` fields (`r`, `w`, `curr_line_offset`, ...) are compared after every
// token. Turn this off if keeping them identical is ruled out of scope.
CHECK_TOKENIZER_STATE :: #config(JSON_DIFF_CHECK_TOKENIZER_STATE, true)

MAX_TOKENS :: 4096

ref_spec :: proc(spec: json.Specification) -> ref.Specification {
	return ref.Specification(int(spec))
}

random_spec :: proc() -> json.Specification {
	return rand.choice(SPECS[:])
}

Fuzz :: struct {
	t:        ^testing.T,
	arena:    virtual.Arena,
	failures: int,
	outcomes: Outcomes,
	rejected: int, // Inputs the reference rejected as `Invalid_Data` under `.Skip_Validation`.
}

// How the current package's `unmarshal` calls ended, to show that inputs get past validation.
Outcomes :: struct {
	total, ok, invalid_data, unsupported, other: int,
}

count_outcome :: proc(o: ^Outcomes, e: Norm_Error) {
	o.total += 1
	switch {
	case e.kind == .None:                                                    o.ok += 1
	case e.kind == .Data && e.code == int(json.Unmarshal_Data_Error.Invalid_Data): o.invalid_data += 1
	case e.kind == .Unsupported:                                             o.unsupported += 1
	case:                                                                    o.other += 1
	}
}

add_outcomes :: proc(a: ^Outcomes, b: Outcomes) {
	a.total        += b.total
	a.ok           += b.ok
	a.invalid_data += b.invalid_data
	a.unsupported  += b.unsupported
	a.other        += b.other
}

fuzz_init :: proc(f: ^Fuzz, t: ^testing.T) {
	f.t = t
	err := virtual.arena_init_growing(&f.arena)
	testing.expect_value(t, err, nil)
}

fuzz_destroy :: proc(f: ^Fuzz, loc := #caller_location) {
	virtual.arena_destroy(&f.arena)
	if o := f.outcomes; o.total > 0 {
		log.infof("%d unmarshals: %d ok, %d Invalid_Data, %d Unsupported_Type_Error, %d other errors",
			o.total, o.ok, o.invalid_data, o.unsupported, o.other, location = loc)
	}
}

// Frees everything made for one input. Both packages allocate from the same arena, so the
// allocators stored in dynamic arrays and maps compare equal.
fuzz_reset :: proc(f: ^Fuzz) {
	virtual.arena_free_all(&f.arena)
	free_all(context.temp_allocator)
}

fuzz_done :: proc(f: ^Fuzz) -> bool {
	return f.failures >= MAX_FAILURES
}

report :: proc(f: ^Fuzz, what: string, data: []byte, spec: json.Specification, details: string, loc := #caller_location) {
	f.failures += 1
	testing.expectf(f.t, false, "%s differs (spec=%v)\n\tinput:     %q\n%s", what, spec, string(data), details, loc = loc)
}

TARGET_TYPES := [?]typeid{Everything, Tagged, Inner, Mixed, []Inner, map[string]int, [Color]f32}

// A mix of everything the generators make, for the checks that are not tied to a target type.
any_input :: proc() -> []byte {
	spec := random_spec()
	switch rand.int_max(6) {
	case 0:  return random_bytes(48)
	case 1:  return transmute([]byte)rand.choice(SEED_CORPUS[:])
	case 2:  return mutate(transmute([]byte)rand.choice(SEED_CORPUS[:]))
	case 3:  return generate(nil, spec, chaos = 10, noise = 10)
	case 4:  return generate(type_info_of(rand.choice(TARGET_TYPES[:])), spec, chaos = 5, noise = 5)
	case:    return mutate(generate(type_info_of(rand.choice(TARGET_TYPES[:])), spec, chaos = 5, noise = 5))
	}
}

@(test)
differential_enums :: proc(t: ^testing.T) {
	expect_same_enum(t, json.Token_Kind,           ref.Token_Kind)
	expect_same_enum(t, json.Error,                ref.Error)
	expect_same_enum(t, json.Unmarshal_Data_Error, ref.Unmarshal_Data_Error)
	expect_same_enum(t, json.Specification,        ref.Specification)
}

expect_same_enum :: proc(t: ^testing.T, $A, $B: typeid, loc := #caller_location) {
	names_a,  names_b  := reflect.enum_field_names(A),  reflect.enum_field_names(B)
	values_a, values_b := reflect.enum_field_values(A), reflect.enum_field_values(B)
	same := slice.equal(names_a, names_b) && slice.equal(values_a, values_b)
	testing.expectf(t, same, "%v and %v no longer line up: %v vs %v", typeid_of(A), typeid_of(B), names_a, names_b, loc = loc)
}

// Tokens

@(test)
differential_tokenizer :: proc(t: ^testing.T) {
	f: Fuzz
	fuzz_init(&f, t)
	defer fuzz_destroy(&f)

	for _ in 0..<ITERATIONS*4 {
		defer fuzz_reset(&f)
		data := any_input()
		for spec in SPECS {
			check_tokens(&f, data, spec, false)
			check_tokens(&f, data, spec, true)
		}
		if fuzz_done(&f) {
			return
		}
	}
}

// `get_token` judges each string as it scans it, and the validator and the unmarshaller use that
// verdict instead of calling `is_valid_string_literal` again, so the two must agree on every string
// token: exhaustively for short strings over the bytes that matter, and on fuzzed documents.
@(test)
string_token_verdict :: proc(t: ^testing.T) {
	f: Fuzz
	fuzz_init(&f, t)
	defer fuzz_destroy(&f)

	seen: [json.Error]int
	check :: proc(f: ^Fuzz, data: []byte, spec: json.Specification, seen: ^[json.Error]int) {
		tok := json.make_tokenizer(string(data), spec)
		for _ in 0..<MAX_TOKENS {
			token, err := json.get_token(&tok)
			if token.kind == .EOF {
				return
			}
			if token.kind != .String {
				continue
			}
			seen[err] += 1
			if valid := json.is_valid_string_literal(token.text, spec); valid != (err != .Invalid_String) {
				report(f, "string verdict", data, spec, fmt.tprintf("\ttoken %q: err=%v, is_valid_string_literal=%v", token.text, err, valid))
				return
			}
		}
	}

	enumerate :: proc(f: ^Fuzz, alphabet: string, max_len: int, seen: ^[json.Error]int) {
		content := make([]byte, max_len, context.temp_allocator)
		buf := make([dynamic]byte, 0, max_len+2, context.temp_allocator)
		for n in 0..=max_len {
			count := 1
			for _ in 0..<n {
				count *= len(alphabet)
			}
			for index in 0..<count {
				x := index
				for i in 0..<n {
					content[i] = alphabet[x % len(alphabet)]
					x /= len(alphabet)
				}
				for quote in ([]byte{'"', '\''}) {
					for closed in ([]bool{true, false}) {
						clear(&buf)
						append(&buf, quote)
						append(&buf, ..content[:n])
						if closed {
							append(&buf, quote)
						}
						for spec in SPECS {
							check(f, buf[:], spec, seen)
						}
					}
				}
				if fuzz_done(f) {
					return
				}
			}
		}
	}

	enumerate(&f, "\"'\\u0F/n\n\r\x00\x1f\xc3\xa9\xffg ", 4, &seen)
	enumerate(&f, "\\u0Fg\"'", 6, &seen)
	free_all(context.temp_allocator)

	for _ in 0..<ITERATIONS*10 {
		defer fuzz_reset(&f)
		data := any_input()
		for spec in SPECS {
			check(&f, data, spec, &seen)
		}
		if fuzz_done(&f) {
			break
		}
	}

	b := strings.builder_make(context.temp_allocator)
	for n, e in seen {
		if n > 0 {
			fmt.sbprintf(&b, " %v=%d", e, n)
		}
	}
	log.infof("errors on string tokens:%s", strings.to_string(b))
}

check_tokens :: proc(f: ^Fuzz, data: []byte, spec: json.Specification, parse_integers: bool) {
	ta := json.make_tokenizer(string(data), spec, parse_integers)
	tb := ref.make_tokenizer(string(data), ref_spec(spec), parse_integers)

	state_differs :: proc(f: ^Fuzz, data: []byte, spec: json.Specification, ta: json.Tokenizer, tb: ref.Tokenizer, after: string) -> bool {
		if !CHECK_TOKENIZER_STATE {
			return false
		}
		sa, sb := norm_tokenizer_current(ta), norm_tokenizer_reference(tb)
		if sa != sb {
			report(f, "tokenizer state", data, spec, fmt.tprintf("\tafter:     %s\n\tcurrent:   %v\n\treference: %v", after, sa, sb))
			return true
		}
		return false
	}

	if state_differs(f, data, spec, ta, tb, "make_tokenizer") {
		return
	}
	for i in 0..<MAX_TOKENS {
		a, ea := json.get_token(&ta)
		b, eb := ref.get_token(&tb)
		na, nb := norm_token_current(a), norm_token_reference(b)
		if na != nb || int(ea) != int(eb) {
			report(f, "token", data, spec, fmt.tprintf(
				"\ttoken #%d (parse_integers=%v)\n\tcurrent:   %s, err=%v\n\treference: %s, err=%v",
				i, parse_integers, fmt_token(na), ea, fmt_token(nb), json.Error(int(eb)),
			))
			return
		}
		if state_differs(f, data, spec, ta, tb, fmt.tprintf("token #%d %s", i, fmt_token(na))) {
			return
		}
		if a.kind == .EOF {
			return
		}
	}
}

// Validation and `Value` parsing

@(test)
differential_is_valid :: proc(t: ^testing.T) {
	f: Fuzz
	fuzz_init(&f, t)
	defer fuzz_destroy(&f)

	for _ in 0..<ITERATIONS*4 {
		defer fuzz_reset(&f)
		data := any_input()
		for spec in SPECS {
			for parse_integers in ([?]bool{false, true}) {
				a := json.is_valid(data, spec, parse_integers)
				b := ref.is_valid(data, ref_spec(spec), parse_integers)
				if a != b {
					report(&f, "is_valid", data, spec, fmt.tprintf("\tcurrent:   %v\n\treference: %v (parse_integers=%v)", a, b, parse_integers))
				}
			}
		}
		if fuzz_done(&f) {
			return
		}
	}
}

@(test)
differential_parse :: proc(t: ^testing.T) {
	f: Fuzz
	fuzz_init(&f, t)
	defer fuzz_destroy(&f)

	for _ in 0..<ITERATIONS*2 {
		defer fuzz_reset(&f)
		data := any_input()
		for spec in SPECS {
			for parse_integers in ([?]bool{false, true}) {
				allocator := virtual.arena_allocator(&f.arena)
				va, ea := json.parse(data, spec, parse_integers, allocator)
				vb, eb := ref.parse(data, ref_spec(spec), parse_integers, allocator)
				if int(ea) != int(eb) || !values_equal(va, vb) {
					report(&f, "parse", data, spec, fmt.tprintf(
						"\tcurrent:   %v, err=%v\n\treference: %v, err=%v (parse_integers=%v)",
						va, ea, vb, json.Error(int(eb)), parse_integers,
					))
				}
			}
		}
		if fuzz_done(&f) {
			return
		}
	}
}

@(test)
differential_unquote_string :: proc(t: ^testing.T) {
	f: Fuzz
	fuzz_init(&f, t)
	defer fuzz_destroy(&f)

	for _ in 0..<ITERATIONS*4 {
		defer fuzz_reset(&f)

		g := Gen{spec = random_spec(), chaos = 10, noise = 30}
		strings.builder_init(&g.b, context.temp_allocator)
		switch rand.int_max(5) {
		case 0:
			quote := pick({`"`, `'`})
			write(&g, quote)
			write(&g, string(random_bytes(24)))
			write(&g, quote)
		case 1:
			write(&g, pick({``, `"`, `'`, `""`, `''`, `"a'`, `'a"`, `"\`, `"\"`, `"\u`, `"\uD800\u`}))
		case:
			gen_string(&g)
		}
		text := string(g.b.buf[:])

		for spec in SPECS {
			allocator := virtual.arena_allocator(&f.arena)
			sa, ea := json.unquote_string(json.Token{kind = .String, text = text}, spec, allocator)
			sb, eb := ref.unquote_string(ref.Token{kind = .String, text = text}, ref_spec(spec), allocator)
			if sa != sb || int(ea) != int(eb) || (raw_data(sa) == nil) != (raw_data(sb) == nil) {
				report(&f, "unquote_string", transmute([]byte)text, spec, fmt.tprintf(
					"\tcurrent:   %q (nil=%v), err=%v\n\treference: %q (nil=%v), err=%v",
					sa, raw_data(sa) == nil, ea, sb, raw_data(sb) == nil, json.Error(int(eb)),
				))
			}
		}
		if fuzz_done(&f) {
			return
		}
	}
}

// Unmarshalling
//
// `C` is the target type for the current package and `R` the one for the reference. They are the
// same type except where `json.Value` is involved.

compare_unmarshal :: proc(f: ^Fuzz, what: string, data: []byte, spec: json.Specification, a, b: rawptr, $C, $R: typeid, ea, eb: Norm_Error, extra := "", flags := Diff_Flags{}) {
	flags := flags
	if ea.kind != .None && errors_equal(ea, eb) {
		flags += {.After_Error}
	}
	d := diff_values(a, b, type_info_of(C), type_info_of(R), flags)
	if errors_equal(ea, eb) && d == "" && extra == "" {
		return
	}
	value := "same" if d == "" else fmt.tprintf("differs at value%s", d)
	report(f, what, data, spec, fmt.tprintf(
		"\ttarget:    %v\n\tcurrent:   %s\n\treference: %s\n\tresult:    %s%s",
		typeid_of(C), fmt_error(ea), fmt_error(eb), value, extra,
	))
}

// The reference accepts a key that sets a struct field twice, so the current package must match it
// exactly with `.Allow_Duplicate_Fields`, and without it wherever no object repeats a key. The
// reference also gives an empty key to the first field without a `json` tag, where the current
// package only gives it to a field tagged `json:""`, so input with an empty key is not compared.
unmarshal_runs :: proc(data: []byte, spec: json.Specification, flags: json.Unmarshal_Flags) -> (runs: []json.Unmarshal_Flags, comparable: bool) {
	keys := object_keys(data, spec)
	r := make([dynamic]json.Unmarshal_Flags, 0, 2, context.temp_allocator)
	append(&r, flags + {.Allow_Duplicate_Fields})
	if .Allow_Duplicate_Fields not_in flags && !keys.repeated {
		append(&r, flags)
	}
	return r[:], !keys.empty
}

check_unmarshal :: proc(f: ^Fuzz, $C, $R: typeid, data: []byte, spec: json.Specification, flags: json.Unmarshal_Flags = {}) -> (ea: Norm_Error) {
	allocator := virtual.arena_allocator(&f.arena)
	b := new(R, allocator)
	eb := norm_error_reference(ref.unmarshal(data, b, ref_spec(spec), allocator))
	runs, comparable := unmarshal_runs(data, spec, flags)
	for run_flags, run in runs {
		a := new(C, allocator)
		e := norm_error_current(json.unmarshal(data, a, spec, allocator, run_flags))
		if run == 0 {
			ea = e
		}
		what := fmt.tprintf("unmarshal with %v", run_flags)
		if .Skip_Validation in flags && eb.kind == .Data && eb.code == int(json.Unmarshal_Data_Error.Invalid_Data) {
			// The reference rejected the input up front. Without validation any error will do, and
			// the destination may be partly written.
			if run == 0 {
				f.rejected += 1
			}
			if e.kind == .None {
				report(f, what, data, spec, "	accepted input that is_valid rejects")
			}
			continue
		}
		if comparable {
			compare_unmarshal(f, what, data, spec, a, b, C, R, e, eb, flags = {.Any_Map_Cap} if .Reserve_Maps in flags else {})
		}
	}
	return
}

fuzz_unmarshal :: proc(f: ^Fuzz, $C, $R: typeid, iterations: int, flags: json.Unmarshal_Flags = {}) {
	outcomes: Outcomes
	defer {
		add_outcomes(&f.outcomes, outcomes)
		log.debugf("%v: %v", typeid_of(C), outcomes)
		if !fuzz_done(f) && outcomes.total >= 30 {
			testing.expectf(f.t, outcomes.ok > 0, "no input for %v unmarshalled without an error: %v", typeid_of(C), outcomes)
		}
	}
	for _ in 0..<iterations {
		defer fuzz_reset(f)
		data: []byte
		if .Skip_Validation in flags && chance(15) {
			// Without validation, nothing may crash or hang on arbitrary input either.
			data = random_bytes(64) if chance(50) else mutate(transmute([]byte)rand.choice(SEED_CORPUS[:]))
		} else if chance(50) {
			data = generate(type_info_of(C), random_spec(), chaos = 0, noise = 0, exact = true)
		} else {
			chaos := rand.choice([]int{0, 2, 10, 30})
			noise := rand.choice([]int{0, 0, 5})
			data = generate(type_info_of(C), random_spec(), chaos, noise)
			if chance(40) {
				data = mutate(data)
			}
		}
		for spec in SPECS {
			count_outcome(&outcomes, check_unmarshal(f, C, R, data, spec, flags))
		}
		if fuzz_done(f) {
			return
		}
	}
}

@(test)
differential_unmarshal_everything :: proc(t: ^testing.T) {
	f: Fuzz
	fuzz_init(&f, t)
	defer fuzz_destroy(&f)
	fuzz_unmarshal(&f, Everything, Everything, ITERATIONS*2)
}

@(test)
differential_unmarshal_structs :: proc(t: ^testing.T) {
	f: Fuzz
	fuzz_init(&f, t)
	defer fuzz_destroy(&f)
	fuzz_unmarshal(&f, Tagged,   Tagged,   ITERATIONS)
	fuzz_unmarshal(&f, Inner,    Inner,    ITERATIONS)
	fuzz_unmarshal(&f, []Tagged, []Tagged, ITERATIONS)
	fuzz_unmarshal(&f, Raw,      Raw,      ITERATIONS/4)
	fuzz_unmarshal(&f, Deep,     Deep,     ITERATIONS)
}

@(test)
differential_unmarshal_containers :: proc(t: ^testing.T) {
	f: Fuzz
	fuzz_init(&f, t)
	defer fuzz_destroy(&f)
	fuzz_unmarshal(&f, []int,            []int,            ITERATIONS)
	fuzz_unmarshal(&f, [dynamic]f64,     [dynamic]f64,     ITERATIONS)
	fuzz_unmarshal(&f, [][]Inner,        [][]Inner,        ITERATIONS)
	fuzz_unmarshal(&f, map[string]Inner, map[string]Inner, ITERATIONS)
	fuzz_unmarshal(&f, map[int]string,   map[int]string,   ITERATIONS)
	fuzz_unmarshal(&f, [Color]int,       [Color]int,       ITERATIONS/2)
	fuzz_unmarshal(&f, [3]f32,           [3]f32,           ITERATIONS/2)
	fuzz_unmarshal(&f, [dynamic; 4]u8,   [dynamic; 4]u8,   ITERATIONS/2)
	fuzz_unmarshal(&f, complex64,        complex64,        ITERATIONS/2)
}

@(test)
differential_unmarshal_scalars :: proc(t: ^testing.T) {
	f: Fuzz
	fuzz_init(&f, t)
	defer fuzz_destroy(&f)
	n := ITERATIONS/2
	fuzz_unmarshal(&f, string,       string,       n)
	fuzz_unmarshal(&f, cstring,      cstring,      n)
	fuzz_unmarshal(&f, My_String,    My_String,    n)
	fuzz_unmarshal(&f, rune,         rune,         n)
	fuzz_unmarshal(&f, i8,           i8,           n)
	fuzz_unmarshal(&f, u64,          u64,          n)
	fuzz_unmarshal(&f, i128,         i128,         n)
	fuzz_unmarshal(&f, u16be,        u16be,        n)
	fuzz_unmarshal(&f, f32,          f32,          n)
	fuzz_unmarshal(&f, f16be,        f16be,        n)
	fuzz_unmarshal(&f, bool,         bool,         n)
	fuzz_unmarshal(&f, b32,          b32,          n)
	fuzz_unmarshal(&f, Color,        Color,        n)
	fuzz_unmarshal(&f, Sparse_Enum,  Sparse_Enum,  n)
	fuzz_unmarshal(&f, Colors,       Colors,       n)
	fuzz_unmarshal(&f, Flags_16,     Flags_16,     n)
	fuzz_unmarshal(&f, Packed,       Packed,       n)
	fuzz_unmarshal(&f, Mixed,        Mixed,        n)
	fuzz_unmarshal(&f, No_Nil,       No_Nil,       n)
	fuzz_unmarshal(&f, Maybe(Inner), Maybe(Inner), n)
	fuzz_unmarshal(&f, ^Inner,       ^Inner,       n/2)
}

// With `.Skip_Validation`, input the reference accepts must give exactly its result, and input it
// rejects must give some error, without crashing or hanging.
@(test)
differential_unmarshal_skip_validation :: proc(t: ^testing.T) {
	f: Fuzz
	fuzz_init(&f, t)
	defer fuzz_destroy(&f)

	flags := json.Unmarshal_Flags{.Skip_Validation}
	fuzz_unmarshal(&f, Everything,         Everything,           ITERATIONS,   flags)
	fuzz_unmarshal(&f, Tagged,             Tagged,               ITERATIONS/2, flags)
	fuzz_unmarshal(&f, []Tagged,           []Tagged,             ITERATIONS/2, flags)
	fuzz_unmarshal(&f, [][]Inner,          [][]Inner,            ITERATIONS/2, flags)
	fuzz_unmarshal(&f, map[string]Inner,   map[string]Inner,     ITERATIONS/2, flags)
	fuzz_unmarshal(&f, map[int]string,     map[int]string,       ITERATIONS/2, flags)
	fuzz_unmarshal(&f, [Color]int,         [Color]int,           ITERATIONS/2, flags)
	fuzz_unmarshal(&f, [dynamic; 4]u8,     [dynamic; 4]u8,       ITERATIONS/4, flags)
	fuzz_unmarshal(&f, Mixed,              Mixed,                ITERATIONS/2, flags)
	fuzz_unmarshal(&f, string,             string,               ITERATIONS/2, flags)
	fuzz_unmarshal(&f, json.Value,         ref.Value,            ITERATIONS/2, flags)
	fuzz_unmarshal(&f, []json.Value,       []ref.Value,          ITERATIONS/4, flags)
	fuzz_unmarshal(&f, With_Value_Current, With_Value_Reference, ITERATIONS/2, flags)

	log.infof("skip validation: %d of %d unmarshals were of input is_valid rejects", f.rejected, f.outcomes.total)
	if f.outcomes.total >= 100 {
		testing.expect(t, f.rejected > 0, "no input that is_valid rejects was unmarshalled without validation")
	}
}

// With `.Reserve_Maps` the result must match the reference except for map capacities.
@(test)
differential_unmarshal_reserve_maps :: proc(t: ^testing.T) {
	f: Fuzz
	fuzz_init(&f, t)
	defer fuzz_destroy(&f)

	for flags in ([]json.Unmarshal_Flags{{.Reserve_Maps}, {.Reserve_Maps, .Skip_Validation}}) {
		fuzz_unmarshal(&f, Everything,         Everything,           ITERATIONS/2, flags)
		fuzz_unmarshal(&f, map[string]Inner,   map[string]Inner,     ITERATIONS/2, flags)
		fuzz_unmarshal(&f, map[int]string,     map[int]string,       ITERATIONS/2, flags)
		fuzz_unmarshal(&f, With_Value_Current, With_Value_Reference, ITERATIONS/4, flags)
	}
}

@(test)
differential_unmarshal_json_value :: proc(t: ^testing.T) {
	f: Fuzz
	fuzz_init(&f, t)
	defer fuzz_destroy(&f)
	fuzz_unmarshal(&f, json.Value,         ref.Value,            ITERATIONS)
	fuzz_unmarshal(&f, []json.Value,       []ref.Value,          ITERATIONS/2)
	fuzz_unmarshal(&f, With_Value_Current, With_Value_Reference, ITERATIONS)
}

// Unvalidated unmarshalling
//
// When user unmarshalers are registered, `unmarshal_any` skips `is_valid` and goes straight to
// `make_parser` + `unmarshal_value`. Registering one here would also change every other test in
// the binary, so instead this calls the same public procedures directly. The reference asserts
// on malformed token structure, so inputs are first filtered to those whose structure is valid
// but whose contents (strings, numbers) need not be. The parser state afterwards is compared
// too, because a user unmarshaler continues from it.

check_unmarshal_value :: proc(f: ^Fuzz, $C, $R: typeid, data: []byte, spec: json.Specification, parse_integers: bool) {
	allocator := virtual.arena_allocator(&f.arena)
	b := new(R, allocator)
	pb := ref.make_parser(data, ref_spec(spec), parse_integers, allocator)

	context.allocator = allocator
	eb := norm_error_reference(ref.unmarshal_value(&pb, b^))
	runs, comparable := unmarshal_runs(data, spec, {})
	if !comparable {
		return
	}
	for flags in runs {
		check_unmarshal_value_with(f, C, R, data, spec, parse_integers, flags, b, eb, &pb)
	}
}

check_unmarshal_value_with :: proc(f: ^Fuzz, $C, $R: typeid, data: []byte, spec: json.Specification, parse_integers: bool, flags: json.Unmarshal_Flags, b: ^R, eb: Norm_Error, pb: ^ref.Parser) {
	allocator := virtual.arena_allocator(&f.arena)
	a := new(C, allocator)
	pa := json.make_parser(data, spec, parse_integers, allocator)
	ea := norm_error_current(json.unmarshal_value(&pa, a^, flags))

	extra := ""
	curr_a, curr_b := norm_token_current(pa.curr_token), norm_token_reference(pb.curr_token)
	prev_a, prev_b := norm_token_current(pa.prev_token), norm_token_reference(pb.prev_token)
	if curr_a != curr_b || prev_a != prev_b {
		extra = fmt.tprintf(
			"\n\tparser:    current curr=%s prev=%s\n\t           reference curr=%s prev=%s",
			fmt_token(curr_a), fmt_token(prev_a), fmt_token(curr_b), fmt_token(prev_b),
		)
	} else if CHECK_TOKENIZER_STATE {
		if sa, sb := norm_tokenizer_current(pa.tok), norm_tokenizer_reference(pb.tok); sa != sb {
			extra = fmt.tprintf("\n\ttokenizer: current %v\n\t           reference %v", sa, sb)
		}
	}
	compare_unmarshal(f, fmt.tprintf("unmarshal_value (unvalidated) with %v", flags), data, spec, a, b, C, R, ea, eb, extra)
}

Unvalidated_Stats :: struct {
	inputs, structurally_valid, invalid: int,
}

fuzz_unmarshal_value :: proc(f: ^Fuzz, stats: ^Unvalidated_Stats, $C, $R: typeid, iterations: int) {
	for _ in 0..<iterations {
		defer fuzz_reset(f)
		chaos := rand.choice([]int{0, 0, 5})
		noise := rand.choice([]int{10, 30, 60})
		data := generate(type_info_of(C), random_spec(), chaos, noise)
		for spec in SPECS {
			stats.inputs += 1
			if !structurally_valid(data, spec) {
				continue
			}
			stats.structurally_valid += 1
			if !ref.is_valid(data, ref_spec(spec), true) {
				stats.invalid += 1
			}
			check_unmarshal_value(f, C, R, data, spec, chance(80))
		}
		if fuzz_done(f) {
			return
		}
	}
}

@(test)
differential_unmarshal_unvalidated :: proc(t: ^testing.T) {
	f: Fuzz
	fuzz_init(&f, t)
	defer fuzz_destroy(&f)

	stats: Unvalidated_Stats
	fuzz_unmarshal_value(&f, &stats, Everything,         Everything,           ITERATIONS)
	fuzz_unmarshal_value(&f, &stats, Tagged,             Tagged,               ITERATIONS/2)
	fuzz_unmarshal_value(&f, &stats, []Inner,            []Inner,              ITERATIONS/2)
	fuzz_unmarshal_value(&f, &stats, map[string]Inner,   map[string]Inner,     ITERATIONS/2)
	fuzz_unmarshal_value(&f, &stats, Mixed,              Mixed,                ITERATIONS/2)
	fuzz_unmarshal_value(&f, &stats, string,             string,               ITERATIONS/2)
	fuzz_unmarshal_value(&f, &stats, json.Value,         ref.Value,            ITERATIONS/2)
	fuzz_unmarshal_value(&f, &stats, With_Value_Current, With_Value_Reference, ITERATIONS/2)

	log.infof("unvalidated: %d inputs, %d structurally valid, %d of those rejected by is_valid",
		stats.inputs, stats.structurally_valid, stats.invalid)
	if stats.structurally_valid >= 100 {
		testing.expect(t, stats.invalid > 0, "the unvalidated fuzzer never produced an input that is_valid rejects")
	}
}

// Mirrors `is_valid`, minus the string literal checks, using the reference parser.
structurally_valid :: proc(data: []byte, spec: json.Specification) -> bool {
	p := ref.make_parser(data, ref_spec(spec), true, mem.nil_allocator())
	return structure_document(&p)
}

Object_Keys :: struct {
	repeated: bool, // An object has the same key twice (after unquoting).
	empty:    bool, // An object has an empty key.
}

// The keys of every object, up to the first error in the structure.
object_keys :: proc(data: []byte, spec: json.Specification) -> (keys: Object_Keys) {
	p := ref.make_parser(data, ref_spec(spec), true, mem.nil_allocator())
	structure_document(&p, &keys)
	return
}

@(private="file")
structure_document :: proc(p: ^ref.Parser, seen: ^Object_Keys = nil) -> bool {
	if p.spec == .MJSON {
		#partial switch p.curr_token.kind {
		case .Ident, .String:
			return structure_object_body(p, .EOF, seen)
		}
	}
	return structure_value(p, seen)
}

@(private="file")
structure_object_body :: proc(p: ^ref.Parser, end_token: ref.Token_Kind, seen: ^Object_Keys) -> bool {
	keys := make([dynamic]string, context.temp_allocator)
	for p.curr_token.kind != end_token {
		key := p.curr_token
		key_ok := (p.spec != .JSON && ref.allow_token(p, .Ident)) || ref.expect_token(p, .String) == nil
		if !key_ok {
			return false
		}
		if seen != nil {
			name := key.text
			if key.kind == .String {
				name, _ = ref.unquote_string(key, p.spec, context.temp_allocator)
			}
			seen.repeated ||= slice.contains(keys[:], name)
			seen.empty    ||= name == ""
			append(&keys, name)
		}
		if ref.parse_colon(p) != nil || !structure_value(p, seen) {
			return false
		}
		if ref.parse_comma(p) {
			break
		}
	}
	return true
}

@(private="file")
structure_value :: proc(p: ^ref.Parser, seen: ^Object_Keys) -> bool {
	#partial switch p.curr_token.kind {
	case .Null, .False, .True, .Integer, .Float, .String:
		ref.advance_token(p)
		return true
	case .Open_Brace:
		return ref.expect_token(p, .Open_Brace) == nil &&
		       structure_object_body(p, .Close_Brace, seen) &&
		       ref.expect_token(p, .Close_Brace) == nil
	case .Open_Bracket:
		if ref.expect_token(p, .Open_Bracket) != nil {
			return false
		}
		for p.curr_token.kind != .Close_Bracket {
			if !structure_value(p, seen) {
				return false
			}
			if ref.parse_comma(p) {
				break
			}
		}
		return ref.expect_token(p, .Close_Bracket) == nil
	case .Ident:
		if p.spec == .MJSON {
			ref.advance_token(p)
			return true
		}
	case .Infinity, .NaN:
		if p.spec != .JSON {
			ref.advance_token(p)
			return true
		}
	}
	return false
}
