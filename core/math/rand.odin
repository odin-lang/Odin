Rand :: struct {
	state: u64,
	inc:   u64,
}

init :: proc(r: ^Rand, seed: u64 = 8675309) {
	r.state = 0;
	r.inc = (seed << 1) | 1;
	_random(r);
	r.state += seed;
	_random(r);
}

_random :: proc(r: ^Rand) -> u32 {
	old_state := r.state;
	r.state = old_state * 6364136223846793005 + (r.inc|1);
	xor_shifted := u32(((old_state>>18) ~ old_state) >> 27);
	rot := u32(old_state >> 59);
	return (xor_shifted >> rot) | (xor_shifted << ((-rot) & 31));
}

uint32 :: proc(r: ^Rand) -> u32 { return _random(r); }

uint64 :: proc(r: ^Rand) -> u64 {
	a := u64(_random(r));
	b := u64(_random(r));
	return (a<<32) | b;
}

int31 :: proc(r: ^Rand) -> i32 { return i32(uint32(r) << 1 >> 1); }
int63 :: proc(r: ^Rand) -> i64 { return i64(uint64(r) << 1 >> 1); }

int31_max :: proc(r: ^Rand, n: i32) -> i32 {
	if n <= 0 do panic("Invalid argument to int31_max");
	if n&(n-1) == 0 {
		return int31(r) & (n-1);
	}
	max := i32((1<<31) - 1 - (1<<31)&u32(n));
	v := int31(r);
	for v > max {
		v = int31(r);
	}
	return v % n;
}

int63_max :: proc(r: ^Rand, n: i64) -> i64 {
	if n <= 0 do panic("Invalid argument to int63_max");
	if n&(n-1) == 0 {
		return int63(r) & (n-1);
	}
	max := i64((1<<63) - 1 - (1<<63)&u64(n));
	v := int63(r);
	for v > max {
		v = int63(r);
	}
	return v % n;
}

float64 :: proc(r: ^Rand) -> f64 { return f64(int63_max(r, 1<<53)) / (1 << 53); }
float32 :: proc(r: ^Rand) -> f32 { return f32(float64(r)); }
