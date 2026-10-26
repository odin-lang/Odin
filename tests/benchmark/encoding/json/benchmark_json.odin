package benchmark_core_encoding_json

// Throughput of `core:encoding/json` against the frozen copy it is being optimized from
// (`tests/core/encoding/json/reference`), on the same documents:
//
//	odin test tests/benchmark/encoding/json -o:speed
//
// Every cell is the best of as many runs as fit in JSON_BENCH_MIN_MS (at least three). Results are
// produced with an arena (bump allocation, freed between runs) and with the heap allocator, where
// any temporary allocations made while unmarshalling show up as real malloc/free calls. Freeing
// the result is not timed. JSON_BENCH_SCALE multiplies the size of every document.

import "base:runtime"
import "core:encoding/json"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:mem/virtual"
import "core:reflect"
import "core:strings"
import "core:testing"
import "core:text/table"
import "core:time"
import ref "../../../core/encoding/json/reference"

SCALE  :: #config(JSON_BENCH_SCALE, 1)
MIN_MS :: #config(JSON_BENCH_MIN_MS, 300)

Kind :: enum {
	Player,
	Enemy,
	Item,
	Trigger,
}

Stats :: struct {
	hp, mp: i32,
	speed:  f32,
	level:  u8,
}

Record :: struct {
	id:       u64,
	name:     string,
	email:    string `json:"e-mail"`,
	active:   bool,
	score:    f64,
	kind:     Kind,
	position: [3]f32,
	tags:     []string,
	stats:    Stats,
	notes:    string,
}

// The same documents as `Record`, but every key except "id" is skipped.
Record_Id :: struct {
	id: u64,
}

// Deterministic xorshift, so every run benchmarks the same documents.
Rng :: struct {
	state: u64,
}

next :: proc(r: ^Rng) -> u64 {
	r.state ~= r.state << 13
	r.state ~= r.state >> 7
	r.state ~= r.state << 17
	return r.state
}

rand_int :: proc(r: ^Rng, n: int) -> int {
	return int(next(r) % u64(n))
}

rand_f64 :: proc(r: ^Rng) -> f64 {
	return f64(next(r) >> 11) / f64(u64(1) << 53)
}

WORDS := [?]string{
	"alpha", "beta", "gamma", "delta", "epsilon", "zeta", "theta", "lambda", "sigma", "omega",
	"red", "green", "blue", "north", "south", "fire", "water", "stone", "iron", "glass",
	"café", "naïve", "日本", "Ελλάδα", "🦉", `"quoted"`, "tab\there", "line\nbreak", `back\slash`,
}

sentence :: proc(r: ^Rng, min_words, max_words: int, allocator: mem.Allocator) -> string {
	b := strings.builder_make(allocator)
	for i in 0..<min_words+rand_int(r, max_words-min_words+1) {
		if i > 0 {
			strings.write_byte(&b, ' ')
		}
		strings.write_string(&b, WORDS[rand_int(r, len(WORDS))])
	}
	return strings.to_string(b)
}

make_records :: proc(r: ^Rng, n: int, allocator: mem.Allocator) -> []Record {
	records := make([]Record, n, allocator)
	for &rec, i in records {
		rec.id       = u64(i)*7919 + next(r)%1000
		rec.name     = sentence(r, 2, 2, allocator)
		rec.email    = fmt.aprintf("user%d@example.com", next(r)%100000, allocator = allocator)
		rec.active   = next(r)&1 == 0
		rec.score    = rand_f64(r) * 1000
		rec.kind     = Kind(rand_int(r, len(Kind)))
		rec.position = {f32(rand_f64(r)*200 - 100), f32(rand_f64(r)*200 - 100), f32(rand_f64(r)*10)}
		rec.tags     = make([]string, rand_int(r, 5), allocator)
		for &tag in rec.tags {
			tag = WORDS[rand_int(r, 20)]
		}
		rec.stats = {i32(rand_int(r, 1000)), i32(rand_int(r, 500)), f32(rand_f64(r) * 10), u8(rand_int(r, 100))}
		rec.notes = sentence(r, 3, 12, allocator)
	}
	return records
}

marshal :: proc(v: any, opt: json.Marshal_Options, allocator: mem.Allocator) -> []byte {
	data, err := json.marshal(v, opt, allocator)
	assert(err == nil)
	return data
}

Impl :: enum {
	Reference,
	Current,
}

Alloc_Mode :: enum {
	Arena,
	Heap,
}

Bench :: struct {
	tbl:    table.Table,
	arena:  virtual.Arena,
	failed: bool,
	flags:  json.Unmarshal_Flags, // Used by the current package only; the reference always validates.
}

bench_allocator :: proc(b: ^Bench, mode: Alloc_Mode) -> mem.Allocator {
	switch mode {
	case .Arena: return virtual.arena_allocator(&b.arena)
	case .Heap:  return runtime.heap_allocator()
	}
	return {}
}

// Frees everything `unmarshal` allocated for the value at `p`.
free_unmarshaled :: proc(p: rawptr, ti: ^reflect.Type_Info, allocator: mem.Allocator) {
	base := reflect.type_info_base(ti)
	#partial switch info in base.variant {
	case reflect.Type_Info_String:
		if info.is_cstring {
			delete((^cstring)(p)^, allocator)
		} else {
			delete((^string)(p)^, allocator)
		}
	case reflect.Type_Info_Array:
		for i in 0..<info.count {
			free_unmarshaled(rawptr(uintptr(p) + uintptr(i*info.elem_size)), info.elem, allocator)
		}
	case reflect.Type_Info_Slice:
		raw := (^runtime.Raw_Slice)(p)^
		for i in 0..<raw.len {
			free_unmarshaled(rawptr(uintptr(raw.data) + uintptr(i*info.elem_size)), info.elem, allocator)
		}
		mem.free(raw.data, allocator)
	case reflect.Type_Info_Dynamic_Array:
		raw := (^runtime.Raw_Dynamic_Array)(p)^
		for i in 0..<raw.len {
			free_unmarshaled(rawptr(uintptr(raw.data) + uintptr(i*info.elem_size)), info.elem, allocator)
		}
		mem.free(raw.data, raw.allocator)
	case reflect.Type_Info_Struct:
		for i in 0..<int(info.field_count) {
			free_unmarshaled(rawptr(uintptr(p) + info.offsets[i]), info.types[i], allocator)
		}
	case reflect.Type_Info_Map:
		it := 0
		for k, v in reflect.iterate_map(any{p, ti.id}, &it) {
			free_unmarshaled(k.data, info.key, allocator)
			free_unmarshaled(v.data, info.value, allocator)
		}
		_ = runtime.map_free_dynamic((^runtime.Raw_Map)(p)^, info.map_info)
	}
}

// Runs `run` until MIN_MS have passed (and at least three times) and returns the fastest run.
// `run` returns how long the measured part took, or false on failure.
best_of :: proc(b: ^Bench, run: proc(b: ^Bench, data: []byte, mode: Alloc_Mode, impl: Impl) -> (time.Duration, bool), data: []byte, mode: Alloc_Mode, impl: Impl) -> time.Duration {
	best  := max(time.Duration)
	start := time.tick_now()
	for runs := 0; runs < 3 || time.tick_since(start) < MIN_MS*time.Millisecond; runs += 1 {
		d, ok := run(b, data, mode, impl)
		if !ok {
			b.failed = true
			return 0
		}
		best = min(best, d)
	}
	return best
}

add_row :: proc(b: ^Bench, name, op, alloc: string, size: int, times: [Impl]time.Duration) {
	mb_per_s :: proc(size: int, d: time.Duration) -> f64 {
		return f64(size) / 1e6 / time.duration_seconds(d) if d > 0 else 0
	}
	table.aligned_row_of_values(&b.tbl, .Right,
		name, op, alloc,
		fmt.tprintf("%.2f MB", f64(size)/1e6),
		fmt.tprintf("%.2f ms", time.duration_milliseconds(times[.Reference])),
		fmt.tprintf("%.2f ms", time.duration_milliseconds(times[.Current])),
		fmt.tprintf("%.1f", mb_per_s(size, times[.Reference])),
		fmt.tprintf("%.1f", mb_per_s(size, times[.Current])),
		fmt.tprintf("%.2fx", f64(times[.Reference]) / f64(times[.Current]) if times[.Current] > 0 else 0),
	)
}

bench_unmarshal :: proc(b: ^Bench, name: string, data: []byte, $T: typeid, flags := json.Unmarshal_Flags{}) {
	run :: proc(b: ^Bench, data: []byte, mode: Alloc_Mode, impl: Impl) -> (d: time.Duration, ok: bool) {
		allocator := bench_allocator(b, mode)
		v: T
		start := time.tick_now()
		switch impl {
		case .Reference: ok = ref.unmarshal(data, &v, ref.DEFAULT_SPECIFICATION, allocator) == nil
		case .Current:   ok = json.unmarshal(data, &v, json.DEFAULT_SPECIFICATION, allocator, b.flags) == nil
		}
		d = time.tick_since(start)
		switch mode {
		case .Arena: virtual.arena_free_all(&b.arena)
		case .Heap:  free_unmarshaled(&v, type_info_of(T), allocator)
		}
		if !ok {
			log.errorf("%v failed to unmarshal %v", impl, typeid_of(T))
		}
		return
	}
	b.flags = flags
	defer b.flags = {}
	op := "unmarshal" if flags == {} else "unmarshal, no validation"
	for mode in Alloc_Mode {
		times: [Impl]time.Duration
		for impl in Impl {
			times[impl] = best_of(b, run, data, mode, impl)
		}
		add_row(b, name, op, fmt.tprint(mode), len(data), times)
	}
}

bench_parse :: proc(b: ^Bench, name: string, data: []byte) {
	run :: proc(b: ^Bench, data: []byte, mode: Alloc_Mode, impl: Impl) -> (d: time.Duration, ok: bool) {
		allocator := bench_allocator(b, mode)
		start := time.tick_now()
		switch impl {
		case .Reference:
			v, err := ref.parse(data, ref.DEFAULT_SPECIFICATION, false, allocator)
			d, ok = time.tick_since(start), err == nil
			if mode == .Heap {
				ref.destroy_value(v, allocator)
			}
		case .Current:
			v, err := json.parse(data, json.DEFAULT_SPECIFICATION, false, allocator)
			d, ok = time.tick_since(start), err == nil
			if mode == .Heap {
				json.destroy_value(v, allocator)
			}
		}
		if mode == .Arena {
			virtual.arena_free_all(&b.arena)
		}
		if !ok {
			log.errorf("%v failed to parse", impl)
		}
		return
	}
	for mode in Alloc_Mode {
		times: [Impl]time.Duration
		for impl in Impl {
			times[impl] = best_of(b, run, data, mode, impl)
		}
		add_row(b, name, "parse", fmt.tprint(mode), len(data), times)
	}
}

bench_is_valid :: proc(b: ^Bench, name: string, data: []byte) {
	run :: proc(b: ^Bench, data: []byte, mode: Alloc_Mode, impl: Impl) -> (d: time.Duration, ok: bool) {
		start := time.tick_now()
		switch impl {
		case .Reference: ok = ref.is_valid(data, ref.DEFAULT_SPECIFICATION)
		case .Current:   ok = json.is_valid(data, json.DEFAULT_SPECIFICATION)
		}
		return time.tick_since(start), ok
	}
	times: [Impl]time.Duration
	for impl in Impl {
		times[impl] = best_of(b, run, data, .Arena, impl)
	}
	add_row(b, name, "is_valid", "-", len(data), times)
}

@(test)
benchmark_unmarshal :: proc(t: ^testing.T) {
	setup: virtual.Arena
	testing.expect_value(t, virtual.arena_init_growing(&setup), nil)
	defer virtual.arena_destroy(&setup)
	sa := virtual.arena_allocator(&setup)

	b: Bench
	// One large first block, so freeing between runs never returns memory to the OS.
	testing.expect_value(t, virtual.arena_init_growing(&b.arena, 1 << 30), nil)
	defer virtual.arena_destroy(&b.arena)
	table.init(&b.tbl)
	defer table.destroy(&b.tbl)
	table.aligned_header_of_values(&b.tbl, .Right, "Document", "Op", "Alloc", "Size", "Reference", "Current", "Ref MB/s", "Cur MB/s", "Speedup")

	r := Rng{0x9E3779B97F4A7C15}

	records        := make_records(&r, 5000*SCALE, sa)
	records_min    := marshal(records, {}, sa)
	records_pretty := marshal(records, {pretty = true}, sa)

	floats := make([]f64, 200_000*SCALE, sa)
	for &f in floats {
		f = (rand_f64(&r) - 0.5) * f64(u64(1) << uint(rand_int(&r, 40)))
	}
	floats_json := marshal(floats, {}, sa)

	ints := make([]i64, 200_000*SCALE, sa)
	for &i in ints {
		i = i64(next(&r) >> uint(rand_int(&r, 64))) - (1 << 20)
	}
	ints_json := marshal(ints, {}, sa)

	strs := make([]string, 20_000*SCALE, sa)
	for &s in strs {
		s = sentence(&r, 3, 40, sa)
	}
	strs_json := marshal(strs, {}, sa)

	nested := make([][][]i32, 40*SCALE, sa)
	for &plane in nested {
		plane = make([][]i32, 40, sa)
		for &row in plane {
			row = make([]i32, 25, sa)
			for &x in row {
				x = i32(rand_int(&r, 100000))
			}
		}
	}
	nested_json := marshal(nested, {}, sa)

	entities := make(map[string]Stats, 20_000*SCALE, sa)
	for i in 0..<20_000*SCALE {
		entities[fmt.aprintf("entity_%d", i, allocator = sa)] = {i32(rand_int(&r, 1000)), i32(rand_int(&r, 500)), f32(rand_f64(&r)), u8(rand_int(&r, 100))}
	}
	entities_json := marshal(entities, {}, sa)

	// Long strings of plain ASCII, like identifiers, URLs or prose without escapes. Generated last
	// so the documents above stay the same as before it was added.
	ascii := "abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/.:-_"
	long_strs := make([]string, 20_000*SCALE, sa)
	for &s in long_strs {
		buf := make([]byte, 40 + rand_int(&r, 360), sa)
		for &c in buf {
			c = ascii[rand_int(&r, len(ascii))]
		}
		s = string(buf)
	}
	long_strs_json := marshal(long_strs, {}, sa)

	bench_unmarshal(&b, "records",            records_min,    []Record)
	bench_unmarshal(&b, "records (pretty)",   records_pretty, []Record)
	bench_unmarshal(&b, "records, id only",   records_min,    []Record_Id)
	bench_unmarshal(&b, "f64 array",          floats_json,    []f64)
	bench_unmarshal(&b, "i64 array",          ints_json,      []i64)
	bench_unmarshal(&b, "string array",       strs_json,      []string)
	bench_unmarshal(&b, "long ASCII strings", long_strs_json, []string)
	bench_unmarshal(&b, "nested arrays",      nested_json,    [][][]i32)
	bench_unmarshal(&b, "map",                entities_json,  map[string]Stats)
	bench_unmarshal(&b, "records",            records_min,    []Record, {.Skip_Validation})
	bench_unmarshal(&b, "f64 array",          floats_json,    []f64,    {.Skip_Validation})
	bench_unmarshal(&b, "string array",       strs_json,      []string, {.Skip_Validation})
	bench_unmarshal(&b, "long ASCII strings", long_strs_json, []string, {.Skip_Validation})
	bench_parse    (&b, "records",            records_min)
	bench_is_valid (&b, "records",            records_min)
	bench_is_valid (&b, "long ASCII strings", long_strs_json)

	testing.expect(t, !b.failed, "a benchmark failed to unmarshal its document")

	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	fmt.sbprintln(&sb)
	table.write_plain_table(strings.to_writer(&sb), &b.tbl)
	log.info(strings.to_string(sb))
}
