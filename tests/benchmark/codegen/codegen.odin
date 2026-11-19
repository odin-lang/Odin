package benchmark_codegen

// Run-time benchmark for compiler code generation. Each workload does a fixed
// amount of work with core packages and returns a checksum. Checksums must match
// between compilers: they double as a correctness check.
//
// Usage: codegen [-cpu:N] [workload...]
// Prints one line per workload: its name, milliseconds, and checksum in hex.
// See README.md for the A/B driver in `compare`.

import "base:runtime"
import "core:compress/deflate"
import "core:crypto/hash"
import "core:diff"
import "core:encoding/json"
import "core:fmt"
import "core:log"
import "core:math"
import "core:math/big"
import "core:math/rand"
import "core:mem/virtual"
import "core:odin/ast"
import "core:odin/parser"
import "core:odin/tokenizer"
import "core:os"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:text/regex"
import "core:time"

Workload :: struct {
	name: string,
	run:  proc() -> u64,
}

@(rodata)
WORKLOADS := [?]Workload{
	{"json_parse",        json_parse},
	{"json_marshal",      json_marshal},
	{"odin_parse",        odin_parse},
	{"fmt",               fmt_work},
	{"strings",           strings_work},
	{"map",               map_work},
	{"sort",              sort_work},
	{"raytrace",          raytrace},
	{"nbody",             nbody},
	{"regex",             regex_work},
	{"big",               big_work},
	{"gzip",              gzip_work},
	{"diff",              diff_work},
	{"sha256",            sha256_work},
	{"log_off_in_callee", log_off_in_callee},
}

g_json_text: string
g_sources:   [dynamic]string
g_gzip:      []byte
g_text:      string
g_text_b:    string
g_items:     []Item

main :: proc() {
	cpu := -1
	only: [dynamic]string
	for arg in os.args[1:] {
		if strings.has_prefix(arg, "-cpu:") {
			n, ok := strconv.parse_int(arg[len("-cpu:"):])
			if !ok || n < 0 {
				fmt.eprintln("invalid CPU number:", arg)
				os.exit(2)
			}
			cpu = n
			continue
		}

		known := false
		for w in WORKLOADS {
			if w.name == arg {
				known = true
			}
		}
		if !known {
			fmt.eprintln("unknown workload:", arg)
			os.exit(2)
		}
		append(&only, arg)
	}

	if !prepare_process(cpu) {
		fmt.eprintfln("cannot pin the benchmark to CPU %d", cpu)
		os.exit(2)
	}

	setup()

	for w in WORKLOADS {
		if len(only) > 0 && !slice.contains(only[:], w.name) {
			continue
		}
		free_all(context.temp_allocator)

		start    := time.tick_now()
		checksum := w.run()
		ms       := time.duration_milliseconds(time.tick_since(start))
		fmt.printf("%s %.3f %x\n", w.name, ms, checksum)
	}
}

setup :: proc() {
	rand.reset(12345)

	// JSON document: an array of records with nested arrays and objects.
	RECORD :: `{{"id":%d,"name":"item_%d","price":%.4f,"tags":["a%d","b%d","c"],"active":%v,` +
	          `"pos":{{"x":%.3f,"y":%.3f,"z":%.3f}},"note":"line\nwith \"escapes\" %d"}}`

	sb := strings.builder_make()
	strings.write_string(&sb, "[")
	for i in 0..<6000 {
		if i > 0 {
			strings.write_string(&sb, ",")
		}

		price  := rand.float64()*1000
		active := i%3 == 0
		x := rand.float64()
		y := rand.float64()
		z := rand.float64()
		fmt.sbprintf(&sb, RECORD, i, i, price, i%17, i%5, active, x, y, z, i)
	}
	strings.write_string(&sb, "]")
	g_json_text = strings.to_string(sb)

	// Odin sources for the parser and gzip workloads. They come from this checkout,
	// not the compiler's root. Both builds in an A/B run see the same bytes.
	corpus := [?][]runtime.Load_Directory_File{
		#load_directory("../../../core/fmt"),
		#load_directory("../../../core/strings"),
		#load_directory("../../../core/encoding/json"),
		#load_directory("../../../core/odin/parser"),
		#load_directory("../../../core/odin/tokenizer"),
		#load_directory("../../../core/math/big"),
		#load_directory("../../../core/slice"),
		#load_directory("../../../core/strconv"),
		#load_directory("../../../core/bytes"),
		#load_directory("../../../core/text/regex/compiler"),
	}
	for files in corpus {
		for f in files {
			if strings.has_suffix(f.name, ".odin") {
				append(&g_sources, string(f.data))
			}
		}
	}

	// The gzip workload inflates the same sources.
	joined := strings.concatenate(g_sources[:])
	gz: [dynamic]byte
	if err := deflate.compress_gzip(&gz, transmute([]byte)joined); err != nil {
		fmt.panicf("deflate: %v", err)
	}
	g_gzip = gz[:]
	delete(joined)

	// Two related texts for the strings, regex, and diff workloads.
	words := [?]string{
		"alpha",  "beta", "gamma", "delta",
		"x",      "y",    "count", "value",
		"return", "if",   "for",   "proc",
		"struct", "1234", "3.14",  "foo@bar.com",
	}
	tb  := strings.builder_make()
	tb2 := strings.builder_make()
	for _ in 0..<20000 {
		n := 3 + rand.int_max(8)
		for k in 0..<n {
			w := words[rand.int_max(len(words))]
			strings.write_string(&tb, w)

			w2 := w
			if rand.int_max(40) == 0 {
				w2 = "changed"
			}
			strings.write_string(&tb2, w2)

			if k+1 < n {
				strings.write_byte(&tb, ' ')
				strings.write_byte(&tb2, ' ')
			}
		}

		strings.write_byte(&tb, '\n')
		if rand.int_max(50) != 0 {
			strings.write_byte(&tb2, '\n')
		}
	}
	g_text   = strings.to_string(tb)
	g_text_b = strings.to_string(tb2)

	// Records for the logging workload.
	rand.reset(777)
	g_items = make([]Item, 2000)
	for &it, i in g_items {
		it = {
			id    = i,
			name  = fmt.aprintf("item_%d", i),
			pos   = {rand.float64(), rand.float64(), rand.float64()},
			vel   = {rand.float64(), rand.float64(), rand.float64()},
			flags = u32(i*7),
			score = rand.float64()*100,
		}
	}
}

mix :: #force_inline proc "contextless" (h, v: u64) -> u64 {
	return (h ~ v) * 0x100000001b3
}

json_sum :: proc(v: json.Value) -> u64 {
	h: u64
	switch x in v {
	case json.Null:
		h = 1
	case json.Integer:
		h = u64(x)
	case json.Float:
		h = u64(x * 1000)
	case json.Boolean:
		h = 3 if x else 5
	case json.String:
		h = u64(len(x))

	case json.Array:
		for e in x {
			h = mix(h, json_sum(e))
		}

	case json.Object:
		for k, e in x {
			h += u64(len(k)) ~ json_sum(e)
		}
	}
	return h
}

json_parse :: proc() -> u64 {
	h: u64
	for _ in 0..<6 {
		v, err := json.parse_string(g_json_text)
		if err != nil {
			fmt.panicf("json: %v", err)
		}
		h = mix(h, json_sum(v))
		json.destroy_value(v)
	}
	return h
}

Position :: struct {
	x, y, z: f64,
}

Record :: struct {
	id:     int,
	name:   string,
	price:  f64,
	tags:   []string,
	active: bool,
	pos:    Position,
	note:   string,
}

json_marshal :: proc() -> u64 {
	h: u64
	records: []Record
	if err := json.unmarshal_string(g_json_text, &records); err != nil {
		fmt.panicf("unmarshal: %v", err)
	}
	for _ in 0..<4 {
		data, err := json.marshal(records)
		if err != nil {
			fmt.panicf("marshal: %v", err)
		}
		h = mix(h, u64(len(data)))

		back: []Record
		if uerr := json.unmarshal(data, &back); uerr != nil {
			fmt.panicf("unmarshal 2: %v", uerr)
		}
		for r in back {
			h = mix(h, u64(r.id) + u64(len(r.tags)))
		}

		for r in back {
			delete(r.name)
			delete(r.note)
			for t in r.tags {
				delete(t)
			}
			delete(r.tags)
		}
		delete(back)
		delete(data)
	}
	return h
}

odin_parse :: proc() -> u64 {
	ignore :: proc(pos: tokenizer.Pos, msg: string, args: ..any) {}

	h: u64
	for _ in 0..<3 {
		arena: virtual.Arena
		_ = virtual.arena_init_growing(&arena)
		context.allocator = virtual.arena_allocator(&arena)
		for src, i in g_sources {
			file := new(ast.File)
			file.src      = src
			file.fullpath = "x.odin"

			p := parser.default_parser()
			p.err  = ignore
			p.warn = ignore
			ok := parser.parse_file(&p, file)

			v := u64(len(file.decls)) + u64(i)
			if ok {
				v += 1
			}
			h = mix(h, v)
		}
		virtual.arena_destroy(&arena)
	}
	return h
}

Fmt_Point :: struct {
	x, y:  f32,
	name:  string,
	flags: bit_set[0..<8],
}

fmt_work :: proc() -> u64 {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	h: u64
	for i in 0..<120000 {
		strings.builder_reset(&sb)
		p := Fmt_Point{
			x     = f32(i)*0.5,
			y     = f32(i%100),
			name  = "pt",
			flags = {0, 3},
		}
		fmt.sbprintf(
			&sb,
			"%d %x %.3f %s %v %8.2e|%-6s|",
			i,
			i*7,
			f64(i)/3,
			"hello",
			p,
			f64(i)*1e-3,
			"ab",
		)
		h = mix(h, u64(strings.builder_len(sb)))
	}
	return h
}

strings_work :: proc() -> u64 {
	h: u64
	for _ in 0..<6 {
		lines := strings.split_lines(g_text)
		for line in lines {
			if len(line) == 0 {
				continue
			}
			fields := strings.fields(line, context.temp_allocator)
			h = mix(h, u64(len(fields)))
			if strings.contains(line, "gamma") {
				h += 1
			}
			idx := strings.index(line, "value")
			h = mix(h, u64(idx + 1))
			up := strings.to_upper(line, context.temp_allocator)
			h = mix(h, u64(up[0]))
			r, _ := strings.replace_all(line, "x", "xx", context.temp_allocator)
			h = mix(h, u64(len(r)))
			if v, ok := strconv.parse_int(fields[0]); ok {
				h += u64(v)
			}
		}
		delete(lines)
		free_all(context.temp_allocator)
	}
	return h
}

map_work :: proc() -> u64 {
	h: u64
	keys := make([]string, 50000)
	defer {
		for k in keys {
			delete(k)
		}
		delete(keys)
	}
	for &k, i in keys {
		k = fmt.aprintf("key_%d_%d", i, i*31)
	}
	for _ in 0..<6 {
		m  := make(map[string]int)
		mi := make(map[int]f64)
		for k, i in keys {
			m[k] = i
			mi[i*7] = f64(i)
		}
		for k, i in keys {
			if v, ok := m[k]; ok {
				h = mix(h, u64(v))
			}
			h = mix(h, u64(mi[i*7]))
			if i % 3 == 0 {
				delete_key(&m, k)
			}
		}
		h = mix(h, u64(len(m)))
		delete(m)
		delete(mi)
	}
	return h
}

Sort_Item :: struct {
	key:  f64,
	id:   int,
	name: string,
}

sort_work :: proc() -> u64 {
	by_key :: proc(a, b: Sort_Item) -> bool {
		return a.key < b.key
	}

	N :: 200000
	items := make([]Sort_Item, N)
	ints  := make([]int, N)
	defer {
		delete(items)
		delete(ints)
	}

	rand.reset(777)
	for &it, i in items {
		it = {key = rand.float64(), id = i, name = "n"}
	}
	for &x in ints {
		x = rand.int_max(1 << 30)
	}
	slice.sort_by(items, by_key)
	slice.sort(ints)

	first  := u64(items[0].id)
	middle := u64(items[N/2].id)
	third  := u64(ints[N/3])
	return mix(0, first ~ middle ~ third)
}

Vec3 :: [3]f64

Ray :: struct {
	origin, dir: Vec3,
}

Material_Kind :: enum u8 {
	Diffuse,
	Metal,
	Glass,
}

Material :: struct {
	kind:   Material_Kind,
	albedo: Vec3,
	fuzz:   f64,
	ior:    f64,
}

Sphere :: struct {
	center: Vec3,
	radius: f64,
	mat:    Material,
}

Hit :: struct {
	p, normal: Vec3,
	t:         f64,
	front:     bool,
	mat:       Material,
}

random_unit :: proc() -> Vec3 {
	for {
		v := Vec3{
			rand.float64()*2 - 1,
			rand.float64()*2 - 1,
			rand.float64()*2 - 1,
		}
		l := v.x*v.x + v.y*v.y + v.z*v.z
		if 1e-12 < l && l <= 1 {
			return v / math.sqrt(l)
		}
	}
}

dot :: proc "contextless" (a, b: Vec3) -> f64 {
	return a.x*b.x + a.y*b.y + a.z*b.z
}

unit :: proc "contextless" (v: Vec3) -> Vec3 {
	return v / math.sqrt(dot(v, v))
}

hit_sphere :: proc "contextless" (s: Sphere, r: Ray, t_min, t_max: f64) -> (hit: Hit, ok: bool) {
	oc := r.origin - s.center
	a  := dot(r.dir, r.dir)
	hb := dot(oc, r.dir)
	c  := dot(oc, oc) - s.radius*s.radius
	disc := hb*hb - a*c
	if disc < 0 {
		return
	}

	sq   := math.sqrt(disc)
	root := (-hb - sq) / a
	if root <= t_min || root >= t_max {
		root = (-hb + sq) / a
		if root <= t_min || root >= t_max {
			return
		}
	}

	hit.t = root
	hit.p = r.origin + r.dir*root
	outward := (hit.p - s.center) / s.radius
	hit.front  = dot(r.dir, outward) < 0
	hit.normal = outward if hit.front else -outward
	hit.mat    = s.mat
	return hit, true
}

hit_world :: proc "contextless" (world: []Sphere, r: Ray, t_min, t_max: f64) -> (best: Hit, ok: bool) {
	closest := t_max
	for &s in world {
		if h, hit := hit_sphere(s, r, t_min, closest); hit {
			best    = h
			ok      = true
			closest = h.t
		}
	}
	return
}

reflectance :: proc "contextless" (cosine, ratio: f64) -> f64 {
	r0 := (1 - ratio) / (1 + ratio)
	r0 = r0*r0
	return r0 + (1 - r0)*math.pow(1 - cosine, 5)
}

scatter :: proc(r: Ray, h: Hit) -> (attenuation: Vec3, scattered: Ray, ok: bool) {
	switch h.mat.kind {
	case .Diffuse:
		d := h.normal + random_unit()
		if abs(d.x) < 1e-8 &&
		   abs(d.y) < 1e-8 &&
		   abs(d.z) < 1e-8 {
			d = h.normal
		}
		return h.mat.albedo, Ray{h.p, d}, true

	case .Metal:
		u := unit(r.dir)
		refl := u - 2*dot(u, h.normal)*h.normal
		s := Ray{h.p, refl + h.mat.fuzz*random_unit()}
		return h.mat.albedo, s, dot(s.dir, h.normal) > 0

	case .Glass:
		ratio := h.mat.ior
		if h.front {
			ratio = 1/h.mat.ior
		}
		u := unit(r.dir)
		cos_t := min(dot(-u, h.normal), 1)
		sin_t := math.sqrt(1 - cos_t*cos_t)

		dir: Vec3
		if ratio*sin_t > 1 || reflectance(cos_t, ratio) > rand.float64() {
			dir = u - 2*dot(u, h.normal)*h.normal
		} else {
			perp := ratio*(u + cos_t*h.normal)
			par  := -math.sqrt(abs(1 - dot(perp, perp)))*h.normal
			dir = perp + par
		}
		return {1, 1, 1}, Ray{h.p, dir}, true
	}
	return
}

ray_color :: proc(world: []Sphere, r: Ray, depth: int) -> Vec3 {
	if depth <= 0 {
		return {}
	}

	if h, ok := hit_world(world, r, 0.001, math.F64_MAX); ok {
		if att, sc, sok := scatter(r, h); sok {
			return att * ray_color(world, sc, depth-1)
		}
		return {}
	}

	u := unit(r.dir)
	t := 0.5*(u.y + 1)
	return (1-t)*Vec3{1, 1, 1} + t*Vec3{0.5, 0.7, 1.0}
}

raytrace :: proc() -> u64 {
	rand.reset(42)
	world := make([dynamic]Sphere, context.temp_allocator)
	append(&world, Sphere{
		center = {0, -1000, 0},
		radius = 1000,
		mat    = {kind = .Diffuse, albedo = {0.5, 0.5, 0.5}},
	})
	for a in -5..<5 {
		for b in -5..<5 {
			center := Vec3{
				f64(a) + 0.9*rand.float64(),
				0.2,
				f64(b) + 0.9*rand.float64(),
			}

			k := rand.float64()
			mat: Material
			switch {
			case k < 0.7:
				mat = {kind = .Diffuse, albedo = {rand.float64(), rand.float64(), rand.float64()}}
			case k < 0.9:
				mat = {kind = .Metal, albedo = {0.5, 0.6, 0.7}, fuzz = 0.2*rand.float64()}
			case:
				mat = {kind = .Glass, ior = 1.5}
			}

			append(&world, Sphere{center = center, radius = 0.2, mat = mat})
		}
	}
	append(&world, Sphere{
		center = {0, 1, 0},
		radius = 1,
		mat    = {kind = .Glass, ior = 1.5},
	})
	append(&world, Sphere{
		center = {-4, 1, 0},
		radius = 1,
		mat    = {kind = .Diffuse, albedo = {0.4, 0.2, 0.1}},
	})
	append(&world, Sphere{
		center = {4, 1, 0},
		radius = 1,
		mat    = {kind = .Metal, albedo = {0.7, 0.6, 0.5}},
	})

	WIDTH   :: 120
	HEIGHT  :: 68
	SAMPLES :: 30

	origin := Vec3{13, 2, 3}
	w := unit(origin - Vec3{0, 0, 0})
	u := unit(Vec3{w.z, 0, -w.x})
	v := Vec3{
		w.y*u.z - w.z*u.y,
		w.z*u.x - w.x*u.z,
		w.x*u.y - w.y*u.x,
	}

	h: u64
	for j in 0..<HEIGHT {
		for i in 0..<WIDTH {
			col: Vec3
			for _ in 0..<SAMPLES {
				s := (f64(i) + rand.float64()) / WIDTH * 2 - 1
				t := (f64(j) + rand.float64()) / HEIGHT * 2 - 1
				dir := -w*3.5 + u*s*1.7 + v*t
				col += ray_color(world[:], Ray{origin, dir}, 12)
			}
			col /= SAMPLES

			red   := u64(col.x*255)
			green := u64(col.y*255)
			blue  := u64(col.z*255)
			h = mix(h, red | green << 8 | blue << 16)
		}
	}
	return h
}

Body :: struct {
	pos, vel: [3]f64,
	mass:     f64,
}

pair_force :: proc "contextless" (a, b: Body) -> (f: [3]f64, dist: f64) {
	d  := b.pos - a.pos
	d2 := d.x*d.x + d.y*d.y + d.z*d.z + 0.01
	dist = math.sqrt(d2)
	f    = d * (a.mass*b.mass / (d2*dist))
	return
}

energy :: proc "contextless" (bodies: []Body) -> (kinetic, potential: f64) {
	for b, i in bodies {
		speed2 := b.vel.x*b.vel.x + b.vel.y*b.vel.y + b.vel.z*b.vel.z
		kinetic += 0.5*b.mass*speed2
		for j in i+1..<len(bodies) {
			_, d := pair_force(b, bodies[j])
			potential -= b.mass*bodies[j].mass/d
		}
	}
	return
}

nbody :: proc() -> u64 {
	rand.reset(99)
	bodies := make([]Body, 160, context.temp_allocator)
	for &b in bodies {
		b = {
			pos  = {rand.float64()*10, rand.float64()*10, rand.float64()*10},
			mass = 0.5 + rand.float64(),
		}
	}

	h: u64
	for step in 0..<600 {
		for i in 0..<len(bodies) {
			acc: [3]f64
			for j in 0..<len(bodies) {
				if i == j {
					continue
				}
				f, _ := pair_force(bodies[i], bodies[j])
				acc += f / bodies[i].mass
			}
			bodies[i].vel += acc*0.001
		}

		for &b in bodies {
			b.pos += b.vel*0.001
		}

		if step % 100 == 0 {
			k, p := energy(bodies)
			h = mix(h, u64(math.abs(k + p)*1e6))
		}
	}
	return h
}

regex_work :: proc() -> u64 {
	patterns := [?]string{
		`[a-z]+@[a-z]+\.com`,
		`\d+\.\d+`,
		`^(if|for) [a-z]+`,
		`(alpha|gamma) (beta|delta)`,
	}
	res: [len(patterns)]regex.Regular_Expression
	for p, i in patterns {
		r, err := regex.create(p, {})
		if err != nil {
			fmt.panicf("regex %s: %v", p, err)
		}
		res[i] = r
	}
	defer for r in res {
		regex.destroy(r)
	}

	lines := strings.split_lines(g_text)
	defer delete(lines)

	h: u64
	for line in lines[:8000] {
		for r in res {
			cap, ok := regex.match(r, line)
			if ok {
				h = mix(h, u64(cap.pos[0][1]))
			}
			regex.destroy(cap)
		}
	}
	return h
}

big_work :: proc() -> u64 {
	h: u64
	for n in 0..<36 {
		a, b, c: big.Int
		defer big.destroy(&a, &b, &c)
		_ = big.factorial(&a, 1500 + (n%6)*100)
		_ = big.set(&b, i64(1234567891011))
		for _ in 0..<40 {
			_ = big.mul(&c, &a, &b)
			_ = big.add(&a, &c, &b)
			_ = big.div(&a, &a, &b)
		}

		s, _ := big.int_itoa_string(&a)
		h = mix(h, u64(len(s)) + u64(s[len(s)-1]))
		delete(s)
	}
	return h
}

gzip_work :: proc() -> u64 {
	h := u64(len(g_gzip))
	for _ in 0..<40 {
		out: [dynamic]byte
		if err := deflate.decompress_gzip(&out, g_gzip); err != nil {
			fmt.panicf("gzip: %v", err)
		}
		h = mix(h, u64(len(out)) + u64(out[len(out)/2]))
		delete(out)
	}
	return h
}

diff_work :: proc() -> u64 {
	h: u64
	for i in 0..<12 {
		algorithm := diff.Algorithm.Myers
		if i % 2 == 1 {
			algorithm = .Histogram
		}

		d, err := diff.diff_text(
			g_text,
			g_text_b,
			context.allocator,
			context.allocator,
			opts = {algorithm = algorithm},
		)
		if err != nil {
			fmt.panicf("diff: %v", err)
		}

		bits := d.changes.bits
		h = mix(h, u64(len(bits)) + u64(bits[len(bits)/2]))
		diff.text_diff_destroy(d, context.allocator)
	}
	return h
}

sha256_work :: proc() -> u64 {
	h: u64
	data := transmute([]byte)g_text
	for _ in 0..<200 {
		d := hash.hash_bytes(.SHA256, data, context.temp_allocator)
		h = mix(h, u64(d[0]) | u64(d[31]) << 8)
	}
	return h
}

Item :: struct {
	id:    int,
	name:  string,
	pos:   [3]f64,
	vel:   [3]f64,
	flags: u32,
	score: f64,
}

score_of :: #force_no_inline proc(it: Item) -> f64 {
	return it.pos.x*it.vel.x + it.pos.y*it.vel.y + it.score + f64(it.flags)
}

trace :: #force_no_inline proc(it: Item) -> u64 {
	log.debugf("trace %d %s", it.id, it.name)
	return u64(score_of(it))
}

// The callee logs its large parameter below the logger's level, then passes it on.
log_off_in_callee :: proc() -> u64 {
	null_logger :: proc(
		data:    rawptr,
		level:   log.Level,
		text:    string,
		options: log.Options,
		location := #caller_location,
	) {}

	context.logger = log.Logger{
		procedure    = null_logger,
		lowest_level = .Info,
	}

	h: u64
	for _ in 0..<6000 {
		for i in 0..<len(g_items) {
			it := g_items[i]
			h = mix(h, trace(it))
		}
	}
	return h
}
