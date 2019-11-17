package eca

import "core:fmt"
import "core:math/rand"
import "core:time"
import "intrinsics"

elementary_cellular_automata :: proc(state: $T, rule: u8, generations: int, pause: time.Duration = 0)
	where intrinsics.type_is_integer(T),
		  intrinsics.type_is_unsigned(T) {
	N :: 8*size_of(state);

	output :: proc(state: T) {
		buf: [N]byte;
		for i in 0..<T(N) {
			c := byte('#');
			// c := byte(rand.int_max(26) + 'A' + ('a'-'A')*rand.int_max(2));
			buf[N-1-i] = state & (1<<i) != 0 ? c : ' ';
		}
		fmt.println(string(buf[:]));
	}

	bit :: proc(x, i: T) -> T {
		return (x >> i) & 0x1;
	}
	set :: proc(x: ^T, cell, k: T, rule: u8) {
		x^ &~= 1<<cell;
		if rule>>k&1 != 0 {
			x^ |= 1<<cell;
		}
	}


	a := state;
	a1 := T(0);

	output(a);

	last := T(N-1);
	for r in 0..<generations {
		if pause > 0 do time.sleep(pause);
	

		k := bit(a, last) | bit(a, 0)<<1 | bit(a, 1)<<2;
		set(&a1, 0, k, rule);
		a1 |= (1<<0) * T(rule>>k&1);
		for c in 1..<last {
			k = k>>1 | bit(a, c+1)<<2;
			set(&a1, c, k, rule);
		}
		set(&a1, last, k>>1|bit(a, 0)<<2, rule);
		a, a1 = a1, a;
		output(a);
		if a == a1 {
			return;
		}
	}
}

main :: proc() {
	elementary_cellular_automata(
		state=rand.uint128(),
		rule=30,
		generations=5000,
		pause=100*time.Millisecond,
	);
}