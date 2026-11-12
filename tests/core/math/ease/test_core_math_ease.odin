package test_core_math_ease

import "core:math/ease"
import "core:testing"
import "core:time"

@(private="file")
MONOTONIC :: bit_set[ease.Ease]{
	.Linear,
	.Quadratic_In, .Quadratic_Out, .Quadratic_In_Out,
	.Cubic_In, .Cubic_Out, .Cubic_In_Out,
	.Quartic_In, .Quartic_Out, .Quartic_In_Out,
	.Quintic_In, .Quintic_Out, .Quintic_In_Out,
	.Sine_In, .Sine_Out, .Sine_In_Out,
	.Circular_In, .Circular_Out, .Circular_In_Out,
	.Exponential_In, .Exponential_Out, .Exponential_In_Out,
}

@(private="file", rodata)
grid := [7]f64{0.0625, 0.1875, 0.3125, 0.5, 0.6875, 0.8125, 0.9375}

@(private="file")
Row :: struct {
	type: ease.Ease,
	want: [len(grid)]f64,
}

@(private="file", rodata)
ease_rows := [?]Row{
	{.Linear,             {0h3fb0000000000000, 0h3fc8000000000000, 0h3fd4000000000000, 0h3fe0000000000000, 0h3fe6000000000000, 0h3fea000000000000, 0h3fee000000000000}},
	{.Quadratic_In,       {0h3f70000000000000, 0h3fa2000000000000, 0h3fb9000000000000, 0h3fd0000000000000, 0h3fde400000000000, 0h3fe5200000000000, 0h3fec200000000000}},
	{.Quadratic_Out,      {0h3fbf000000000000, 0h3fd5c00000000000, 0h3fe0e00000000000, 0h3fe8000000000000, 0h3fece00000000000, 0h3feee00000000000, 0h3fefe00000000000}},
	{.Quadratic_In_Out,   {0h3f80000000000000, 0h3fb2000000000000, 0h3fc9000000000000, 0h3fe0000000000000, 0h3fe9c00000000000, 0h3fedc00000000000, 0h3fefc00000000000}},
	{.Cubic_In,           {0h3f30000000000000, 0h3f7b000000000000, 0h3f9f400000000000, 0h3fc0000000000000, 0h3fd4cc0000000000, 0h3fe12a0000000000, 0h3fea5e0000000000}},
	{.Cubic_Out,          {0h3fc6880000000000, 0h3fddac0000000000, 0h3fe59a0000000000, 0h3fec000000000000, 0h3fef060000000000, 0h3fefca0000000000, 0h3feffe0000000000}},
	{.Cubic_In_Out,       {0h3f50000000000000, 0h3f9b000000000000, 0h3fbf400000000000, 0h3fe0000000000000, 0h3fec180000000000, 0h3fef280000000000, 0h3feff80000000000}},
	{.Quartic_In,         {0h3ef0000000000000, 0h3f54400000000000, 0h3f83880000000000, 0h3fb0000000000000, 0h3fcc988000000000, 0h3fdbe44000000000, 0h3fe8b82000000000}},
	{.Quartic_Out,        {0h3fcd1f8000000000, 0h3fe20de000000000, 0h3fe8d9e000000000, 0h3fee000000000000, 0h3fefb1e000000000, 0h3feff5e000000000, 0h3fefffe000000000}},
	{.Quartic_In_Out,     {0h3f20000000000000, 0h3f84400000000000, 0h3fb3880000000000, 0h3fe0000000000000, 0h3fed8f0000000000, 0h3fefaf0000000000, 0h3fefff0000000000}},
	{.Quintic_In,         {0h3eb0000000000000, 0h3f2e600000000000, 0h3f686a0000000000, 0h3fa0000000000000, 0h3fc3a8d800000000, 0h3fd6a97400000000, 0h3fe72c9e00000000}},
	{.Quintic_Out,        {0h3fd1a6c400000000, 0h3fe4ab4600000000, 0h3feb15ca00000000, 0h3fef000000000000, 0h3fefe79600000000, 0h3feffe1a00000000, 0h3feffffe00000000}},
	{.Quintic_In_Out,     {0h3ef0000000000000, 0h3f6e600000000000, 0h3fa86a0000000000, 0h3fe0000000000000, 0h3fee796000000000, 0h3fefe1a000000000, 0h3fefffe000000000}},
	{.Sine_In,            {0h3f73b92e176d6d31, 0h3fa60bea939d225a, 0h3fbe3a6873fa1279, 0h3fd2bec333018867, 0h3fe0ea5163fc84e2, 0h3fe6b5fce895307d, 0h3fecdd0b287ac97b}},
	{.Sine_Out,           {0h3fb917a6bc29b42c, 0h3fd294062ed59f06, 0h3fde2b5d3806f63b, 0h3fe6a09e667f3bcd, 0h3fec38b2f180bdb1, 0h3fee9f4156c62dda, 0h3fefd88da3d12526}},
	{.Sine_In_Out,        {0h3f83ad06011469fb, 0h3fb592675bc57974, 0h3fcc71898ca32e6f, 0h3fe0000000000000, 0h3fe8e39d9cd73464, 0h3fed4db3148750d2, 0h3fefb14be7fbae58}},
	{.Circular_In,        {0h3f6004020140e0a9, 0h3f92293a5b119e6a, 0h3fa9a4612145c722, 0h3fc126145e9ecd56, 0h3fd18631f60909b9, 0h3fdab0c38ba65a35, 0h3fe4dd4dfd4b9f1e}},
	{.Circular_Out,       {0h3fd645640568c1c3, 0h3fe2a79e3a2cd2e6, 0h3fe73ce704fb7b23, 0h3febb67ae8584caa, 0h3fee65b9edeba38e, 0h3fef6eb62d27730d, 0h3fefeffbfdfebf1f}},
	{.Circular_In_Out,    {0h3f70102050e2a85b, 0h3fa2ae8082a8f140, 0h3fbc147cfa94b1d8, 0h3fe0000000000000, 0h3fec7d7060ad69c5, 0h3feed517f7d570ec, 0h3fefdfdfbf5e3aaf}},
	{.Exponential_In,     {0h3f58ace5422aa0db, 0h3f6d5818dcfba487, 0h3f8172b83c7d517b, 0h3fa0000000000000, 0h3fbd5818dcfba487, 0h3fd172b83c7d517b, 0h3fe4bfdad5362a27}},
	{.Exponential_Out,    {0h3fd6804a5593abb2, 0h3fe746a3e1c15743, 0h3fec54fce4608b6f, 0h3fef000000000000, 0h3fefba351f0e0aba, 0h3fefe2a7e723045b, 0h3feff3a98d5eeab0}},
	{.Exponential_In_Out, {0h3f5306fe0a31b715, 0h3f7ae89f995ad3ad, 0h3fa306fe0a31b715, 0h3fe0000000000000, 0h3feecf901f5ce48f, 0h3fefca2ec0cd4a59, 0h3feff67c80fae724}},
	{.Elastic_In,         {0h3f579ce46343e24b, 0hbf629d9fbc1d2375, 0h3f4b5d0a9ac3a643, 0hbf96a09e667f3bcd, 0h3fbd33eca04d7fc7, 0hbfcaf9a45a0acea2, 0h3fc817ccdcbfd1d6}},
	{.Elastic_Out,        {0h3fe9fa0cc8d00b8a, 0h3ff35f348b4159d4, 0h3fec59826bf65007, 0h3ff05a827999fcef, 0h3feff928bd594f16, 0h3ff0094ecfde0e92, 0h3feff4318dce5e0f}},
	{.Elastic_In_Out,     {0h3f45245b50d4b41e, 0h3f7a6442ade788c6, 0h3f7db2448929e670, 0h3fe0000000000000, 0h3fefc49b76edac33, 0h3fefcb377aa430ee, 0h3feffab6e92bcad3}},
	{.Back_In,            {0hbf8878b83c69a60b, 0hbfb8fad8d6859d2d, 0hbfcd5a3fb3524a0c, 0hbfd8000000000000, 0hbfcf9358f0e83c80, 0h3fb5c0ff091256e9, 0h3fe483b4d1d73d15}},
	{.Back_Out,           {0h3fd6f8965c5185d5, 0h3fed47e01eddb523, 0h3ff3f26b1e1d0790, 0h3ff6000000000000, 0h3ff3ab47f66a4941, 0h3ff18fad8d6859d3, 0h3ff030f17078d34c}},
	{.Back_In_Out,        {0hbf977de2a6aea963, 0hbfc2cc50db65e9f5, 0hbfc55486c2ff3098, 0h3fe0000000000000, 0h3ff2aa90d85fe613, 0h3ff2598a1b6cbd3f, 0h3ff05df78a9abaa6}},
	{.Bounce_In,          {0h3f99eb851eb851ec, 0h3fb7093805ac5243, 0h3fbdeccccccccccd, 0h3fd2000000000000, 0h3fd0bc0000000000, 0h3fe77e0000000000, 0h3fef0e0000000000}},
	{.Bounce_Out,         {0h3f9e400000000000, 0h3fd1040000000000, 0h3fe7a20000000000, 0h3fe7000000000000, 0h3fec426666666666, 0h3fed1ed8ff4a75b8, 0h3fef30a3d70a3d71}},
	{.Bounce_In_Out,      {0h3f96d10e0a7ecb62, 0h3fbf0ccccccccccd, 0h3f9299999999999a, 0h3fe0000000000000, 0h3fef6b3333333333, 0h3fec1e6666666666, 0h3fef49778fac09a5}},
}

@(private="file", rodata)
inverse_rows := [?]Row{
	{.Linear,             {0h3fb0000000000000, 0h3fc8000000000000, 0h3fd4000000000000, 0h3fe0000000000000, 0h3fe6000000000000, 0h3fea000000000000, 0h3fee000000000000}},
	{.Quadratic_In,       {0h3fd0000000000000, 0h3fdbb67ae8584caa, 0h3fe1e3779b97f4a8, 0h3fe6a09e667f3bcd, 0h3fea887293fd6f34, 0h3fecd82b446159f3, 0h3feefbdeb14f4eda}},
	{.Quadratic_Out,      {0h3fa04214eb0b1265, 0h3fb93ea5dcf53065, 0h3fc5de35b00a4330, 0h3fd2bec333018867, 0h3fdc3910c8d016b0, 0h3fe224c28bd3d9ab, 0h3fe8000000000000}},
	{.Quadratic_In_Out,   {0h3fc6a09e667f3bcd, 0h3fd3988e1409212e, 0h3fd94c583ada5b53, 0h3fe0000000000000, 0h3fe359d3e292d257, 0h3fe633b8f5fb6f69, 0h3fea57d86660310d}},
	{.Cubic_In,           {0h3fd965fea53d6e3d, 0h3fe250bfe1b082f5, 0h3fe5b7209557b0ee, 0h3fe965fea53d6e3d, 0h3fec3e27449db536, 0h3feddc2ecf33e1b5, 0h3fef51a62037e955}},
	{.Cubic_Out,          {0h3f95cb3bf902d554, 0h3fb11e898660f257, 0h3fbe0ec5db12564f, 0h3fca68056b0a470e, 0h3fd491bed5509e25, 0h3fdb5e803c9efa16, 0h3fe34d00ad6148e2}},
	{.Cubic_In_Out,       {0h3fd0000000000000, 0h3fd7137449123ef6, 0h3fdb5c0fbcfec4d4, 0h3fe0000000000000, 0h3fe251f821809d96, 0h3fe47645db76e085, 0h3fe8000000000000}},
	{.Quartic_In,         {0h3fe0000000000000, 0h3fe50ea39fcbf166, 0h3fe7ecf2d7f7566e, 0h3feae89f995ad3ad, 0h3fed2378f80be1d9, 0h3fee619a6f92fd8c, 0h3fef7ce2bccf3689}},
	{.Quartic_Out,        {0h3f9063a866192ed5, 0h3fa9e65906d02740, 0h3fb6e4383fa0f134, 0h3fc45d819a94b14b, 0h3fd0261a50115324, 0h3fd5e2b8c0681d33, 0h3fe0000000000000}},
	{.Quartic_In_Out,     {0h3fd306fe0a31b715, 0h3fd90a9620ee37f6, 0h3fdc73d51c54470e, 0h3fe0000000000000, 0h3fe1c61571d5dc79, 0h3fe37ab4ef88e405, 0h3fe67c80fae72475}},
	{.Quintic_In,         {0h3fe2611186bae675, 0h3fe6e53fd5cef2aa, 0h3fe95bb8f6d46052, 0h3febdb8cdadbe120, 0h3fedb08a65ca9787, 0h3feeb2c54cea8893, 0h3fef96f088f80944}},
	{.Quintic_Out,        {0h3f8a43ddc1fdaee7, 0h3fa4d3ab315776ce, 0h3fb27bacd1ab43cb, 0h3fc091cc94907b7f, 0h3fca911c24ae7eb6, 0h3fd2358054621aad, 0h3fdb3ddcf28a3317}},
	{.Quintic_In_Out,     {0h3fd51cb453b9536c, 0h3fda4cceb7e84435, 0h3fdd2107ee043ebf, 0h3fe0000000000000, 0h3fe16f7c08fde0a0, 0h3fe2d998a40bdde5, 0h3fe571a5d623564a}},
	{.Sine_In,            {0h3fccf65aef5bb0e9, 0h3fd95b89ef63a29b, 0h3fe08eac8ba44167, 0h3fe5555555555555, 0h3fe9867d401eb24a, 0h3fec28547200bd60, 0h3feeb9d68d76c2da}},
	{.Sine_Out,           {0h3fa462972893d260, 0h3fbebd5c6ffa1501, 0h3fc9e60aff8536d7, 0h3fd5555555555555, 0h3fdee2a6e8b77d33, 0h3fe3523b084e2eb3, 0h3fe8c269442913c6}},
	{.Sine_In_Out,        {0h3fc49719f07a5377, 0h3fd23f0fb3d19b8b, 0h3fd82b4c5074a21b, 0h3fe0000000000000, 0h3fe3ea59d7c5aef3, 0h3fe6e0782617323b, 0h3feada3983e16b22}},
	{.Circular_In,        {0h3fd645640568c1c3, 0h3fe2a79e3a2cd2e6, 0h3fe73ce704fb7b23, 0h3febb67ae8584caa, 0h3fee65b9edeba38e, 0h3fef6eb62d27730d, 0h3fefeffbfdfebf1f}},
	{.Circular_Out,       {0h3f6004020140e0a9, 0h3f92293a5b119e6a, 0h3fa9a4612145c722, 0h3fc126145e9ecd56, 0h3fd18631f60909b9, 0h3fdab0c38ba65a35, 0h3fe4dd4dfd4b9f1e}},
	{.Circular_In_Out,    {0h3fcefbdeb14f4eda, 0h3fd8fae0c15ad38a, 0h3fddaa2fefaae1d8, 0h3fe0000000000000, 0h3fe12ae8082a8f14, 0h3fe3828f9f52963b, 0h3fe8410853ac2c4a}},
	{.Exponential_In,     {0h3fe3333333333333, 0h3fe84599ed865915, 0h3feaa152d0970e2d, 0h3feccccccccccccd, 0h3fee452a98028bb4, 0h3fef0a99a7d3f414, 0h3fefb3b98aea340f}},
	{.Exponential_Out,    {0h3f83119d4572fc3d, 0h3f9eaccb05817d74, 0h3fabad567fd744c1, 0h3fb999999999999a, 0h3fc57ab4bda3c74b, 0h3fcee99849e69bac, 0h3fd999999999999a}},
	{.Exponential_In_Out, {0h3fd6666666666666, 0h3fdb78cd20b98c48, 0h3fddd48603ca4161, 0h3fe0000000000000, 0h3fe115bcfe1adf50, 0h3fe243996fa339dc, 0h3fe4cccccccccccd}},
}

@(private="file")
check_rows :: proc(t: ^testing.T, $T: typeid, rows: []Row, inverse: bool, tolerance: f64) {
	for row in rows {
		for p, i in grid {
			got := f64(ease.ease_inverse(row.type, T(p)) if inverse else ease.ease(row.type, T(p)))
			testing.expectf(t, abs(got - row.want[i]) <= tolerance, "%v %v%s(%v) = %v, want %v", typeid_of(T), row.type, "_inverse" if inverse else "", p, got, row.want[i])
		}
	}
}

@(test)
test_ease_values :: proc(t: ^testing.T) {
	check_rows(t, f64, ease_rows[:], false, 1.0 / (1 << 48))
	check_rows(t, f32, ease_rows[:], false, 1.0 / (1 << 23))
	check_rows(t, f16, ease_rows[:], false, 1.0 / (1 << 10))
}

@(test)
test_ease_inverse_values :: proc(t: ^testing.T) {
	check_rows(t, f64, inverse_rows[:], true, 1.0 / (1 << 48))
	check_rows(t, f32, inverse_rows[:], true, 1.0 / (1 << 23))
	check_rows(t, f16, inverse_rows[:], true, 1.0 / (1 << 10))
}

@(private="file")
monotonic :: proc(t: ^testing.T, type: ease.Ease, p: $T, prev: ^[2]T) -> bool {
	y := ease.ease(type, p)
	ok := testing.expectf(t, prev[0] <= y && y <= 1, "%v %v(%v) = %v, after %v", typeid_of(T), type, p, y, prev[0])
	prev[0] = y
	if p == 0 || p == 1 {
		return ok
	}
	x := ease.ease_inverse(type, p)
	ok_inverse := testing.expectf(t, prev[1] <= x, "%v %v_inverse(%v) = %v, after %v", typeid_of(T), type, p, x, prev[1])
	prev[1] = x
	return ok && ok_inverse
}

@(test)
test_monotonic :: proc(t: ^testing.T) {
	STEPS :: 1 << 16
	for type in MONOTONIC {
		prev16 := [2]f16{0, min(f16)}
		for bits in u16(0)..=0x3c00 {
			if !monotonic(t, type, transmute(f16)bits, &prev16) {
				break
			}
		}
		prev32 := [2]f32{0, min(f32)}
		for i in 0..=STEPS {
			if !monotonic(t, type, f32(i) / STEPS, &prev32) {
				break
			}
		}
		prev64 := [2]f64{0, min(f64)}
		for i in 0..=STEPS {
			if !monotonic(t, type, f64(i) / STEPS, &prev64) {
				break
			}
		}
	}
}

@(private="file")
Procs :: struct {
	type:    ease.Ease,
	forward: proc "contextless" (f64) -> f64,
	inverse: proc "contextless" (f64) -> f64,
}

@(test)
test_dispatch :: proc(t: ^testing.T) {
	procs := [?]Procs{
		{.Quadratic_In,       ease.quadratic_in,       ease.quadratic_in_inverse},
		{.Quadratic_Out,      ease.quadratic_out,      ease.quadratic_out_inverse},
		{.Quadratic_In_Out,   ease.quadratic_in_out,   ease.quadratic_in_out_inverse},
		{.Cubic_In,           ease.cubic_in,           ease.cubic_in_inverse},
		{.Cubic_Out,          ease.cubic_out,          ease.cubic_out_inverse},
		{.Cubic_In_Out,       ease.cubic_in_out,       ease.cubic_in_out_inverse},
		{.Quartic_In,         ease.quartic_in,         ease.quartic_in_inverse},
		{.Quartic_Out,        ease.quartic_out,        ease.quartic_out_inverse},
		{.Quartic_In_Out,     ease.quartic_in_out,     ease.quartic_in_out_inverse},
		{.Quintic_In,         ease.quintic_in,         ease.quintic_in_inverse},
		{.Quintic_Out,        ease.quintic_out,        ease.quintic_out_inverse},
		{.Quintic_In_Out,     ease.quintic_in_out,     ease.quintic_in_out_inverse},
		{.Sine_In,            ease.sine_in,            ease.sine_in_inverse},
		{.Sine_Out,           ease.sine_out,           ease.sine_out_inverse},
		{.Sine_In_Out,        ease.sine_in_out,        ease.sine_in_out_inverse},
		{.Circular_In,        ease.circular_in,        ease.circular_in_inverse},
		{.Circular_Out,       ease.circular_out,       ease.circular_out_inverse},
		{.Circular_In_Out,    ease.circular_in_out,    ease.circular_in_out_inverse},
		{.Exponential_In,     ease.exponential_in,     ease.exponential_in_inverse},
		{.Exponential_Out,    ease.exponential_out,    ease.exponential_out_inverse},
		{.Exponential_In_Out, ease.exponential_in_out, ease.exponential_in_out_inverse},
		{.Elastic_In,         ease.elastic_in,         nil},
		{.Elastic_Out,        ease.elastic_out,        nil},
		{.Elastic_In_Out,     ease.elastic_in_out,     nil},
		{.Back_In,            ease.back_in,            nil},
		{.Back_Out,           ease.back_out,           nil},
		{.Back_In_Out,        ease.back_in_out,        nil},
		{.Bounce_In,          ease.bounce_in,          nil},
		{.Bounce_Out,         ease.bounce_out,         nil},
		{.Bounce_In_Out,      ease.bounce_in_out,      nil},
	}
	seen: bit_set[ease.Ease]
	for row in procs {
		seen += {row.type}
	}
	testing.expect_value(t, card(seen), len(ease.Ease) - 1)
	testing.expect(t, .Linear not_in seen)

	for p in grid {
		testing.expect_value(t, ease.ease(.Linear, p), p)
		testing.expect_value(t, ease.ease_inverse(.Linear, p), p)
		for row in procs {
			got, want := ease.ease(row.type, p), row.forward(p)
			testing.expectf(t, got == want, "ease(%v, %v) = %v, want %v", row.type, p, got, want)
			got = ease.ease_inverse(row.type, p)
			want = row.inverse(p) if row.inverse != nil else 0
			testing.expectf(t, got == want, "ease_inverse(%v, %v) = %v, want %v", row.type, p, got, want)
		}
	}
}

@(private="file")
Flux_State :: struct {
	value:     f64,
	starts:    int,
	updates:   int,
	completes: int,
}

@(private="file")
count_calls :: proc(tween: ^ease.Flux_Tween(f64), s: ^Flux_State) {
	tween.data = s
	tween.on_start = proc(flux: ^ease.Flux_Map(f64), data: rawptr) {
		(^Flux_State)(data).starts += 1
	}
	tween.on_update = proc(flux: ^ease.Flux_Map(f64), data: rawptr) {
		(^Flux_State)(data).updates += 1
	}
	tween.on_complete = proc(flux: ^ease.Flux_Map(f64), data: rawptr) {
		(^Flux_State)(data).completes += 1
	}
}

@(test)
test_flux_tween :: proc(t: ^testing.T) {
	m := ease.flux_init(f64)
	defer ease.flux_destroy(m)

	s := Flux_State{value = 2}
	count_calls(ease.flux_to(&m, &s.value, 10, .Quadratic_In, 2 * time.Second), &s)
	testing.expect_value(t, ease.flux_tween_time_left(m, &s.value), 2)

	ease.flux_update(&m, 0.5)
	testing.expect_value(t, s.value, 2.5)
	testing.expect_value(t, ease.flux_tween_time_left(m, &s.value), 1.5)

	ease.flux_update(&m, 0.5)
	testing.expect_value(t, s.value, 4)

	ease.flux_update(&m, 1)
	testing.expect_value(t, s.value, 10)
	testing.expect_value(t, len(m.values), 0)

	ease.flux_update(&m, 1)
	testing.expect_value(t, s.value, 10)
	testing.expect_value(t, s.starts, 1)
	testing.expect_value(t, s.updates, 3)
	testing.expect_value(t, s.completes, 1)
}

@(test)
test_flux_defaults :: proc(t: ^testing.T) {
	m := ease.flux_init(f32)
	defer ease.flux_destroy(m)

	v: f32
	tween := ease.flux_to(&m, &v, 1)
	testing.expect_value(t, tween.type, ease.Ease.Quadratic_Out)
	testing.expect_value(t, tween.duration, time.Second)
	testing.expect_value(t, tween.delay, 0)
	testing.expect_value(t, tween.data, rawptr(&v))

	ease.flux_update(&m, 0.5)
	testing.expect_value(t, v, 0.75)
}

@(test)
test_flux_retarget :: proc(t: ^testing.T) {
	m := ease.flux_init(f64)
	defer ease.flux_destroy(m)

	v: f64
	_ = ease.flux_to(&m, &v, 10, .Linear)
	ease.flux_update(&m, 0.5)
	testing.expect_value(t, v, 5)

	_ = ease.flux_to(&m, &v, 0, .Linear)
	testing.expect_value(t, len(m.values), 1)
	ease.flux_update(&m, 0.5)
	testing.expect_value(t, v, 2.5)
	ease.flux_update(&m, 0.5)
	testing.expect_value(t, v, 0)
	testing.expect_value(t, len(m.values), 0)
}

@(test)
test_flux_stop :: proc(t: ^testing.T) {
	m := ease.flux_init(f64)
	defer ease.flux_destroy(m)

	a, b: Flux_State
	count_calls(ease.flux_to(&m, &a.value, 1, .Linear), &a)
	_ = ease.flux_to(&m, &b.value, 1, .Linear)
	ease.flux_update(&m, 0.25)

	testing.expect(t, ease.flux_stop(&m, &a.value))
	testing.expect(t, !ease.flux_stop(&m, &a.value))
	testing.expect_value(t, ease.flux_tween_time_left(m, &a.value), 0)
	testing.expect_value(t, len(m.values), 1)

	ease.flux_update(&m, 1)
	testing.expect_value(t, a.value, 0.25)
	testing.expect_value(t, a.updates, 1)
	testing.expect_value(t, a.completes, 0)
	testing.expect_value(t, b.value, 1)
	testing.expect_value(t, len(m.values), 0)
}

@(test)
test_flux_clear :: proc(t: ^testing.T) {
	m := ease.flux_init(f64)
	defer ease.flux_destroy(m)

	vs: [4]f64
	for &v in vs {
		_ = ease.flux_to(&m, &v, 1, .Linear)
	}
	ease.flux_update(&m, 0.5)
	ease.flux_clear(&m)
	testing.expect_value(t, len(m.values), 0)

	ease.flux_update(&m, 1)
	for v in vs {
		testing.expect_value(t, v, 0.5)
	}
}

@(test)
test_flux_zero_duration :: proc(t: ^testing.T) {
	m := ease.flux_init(f64)
	defer ease.flux_destroy(m)

	a, b: Flux_State
	count_calls(ease.flux_to(&m, &a.value, 5, .Linear, 0), &a)
	count_calls(ease.flux_to(&m, &b.value, 5, .Linear, 0, 0.5), &b)
	testing.expect_value(t, ease.flux_tween_time_left(m, &a.value), 0)
	testing.expect_value(t, ease.flux_tween_time_left(m, &b.value), 0.5)

	ease.flux_update(&m, 0)
	testing.expect_value(t, a.value, 5)
	testing.expect_value(t, a.completes, 1)
	testing.expect_value(t, b.value, 0)
	testing.expect_value(t, len(m.values), 1)

	ease.flux_update(&m, 0.5)
	testing.expect_value(t, b.value, 5)
	testing.expect_value(t, b.starts, 1)
	testing.expect_value(t, b.updates, 1)
	testing.expect_value(t, b.completes, 1)
	testing.expect_value(t, len(m.values), 0)
}
