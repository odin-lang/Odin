package container


Ring :: struct(T: typeid) {
	next, prev: ^Ring,
	value: T,
}

ring_init :: proc(r: ^$R/Ring) -> ^R {
	r.prev, r.next = r, r;
	return r;
}

ring_next :: proc(r: ^$R/Ring) -> ^R {
	if r.next == nil {
		return ring_init(r);
	}
	return r.next;
}
ring_prev :: proc(r: ^$R/Ring) -> ^R {
	if r.prev == nil {
		return ring_init(r);
	}
	return r.prev;
}


ring_move :: proc(r: ^$R/Ring, n: int) -> ^R {
	if r.next == nil {
		return ring_init(r);
	}

	switch {
	case n < 0:
		for _ in n..<0 {
			r = r.prev;
		}
	case n > 0:
		for _ in 0..<n {
			r = r.next;
		}
	}
	return r;
}

ring_link :: proc(r, s: ^$R/Ring) -> ^R {
	n := ring_next(r);
	if s != nil {
		p := ring_prev(s);
		r.next = s;
		s.prev = r;
		n.prev = p;
		p.next = n;
	}
	return n;
}
ring_unlink :: proc(r: ^$R/Ring, n: int) -> ^R {
	if n <= 0 {
		return nil;
	}
	return ring_link(r, ring_move(r, n+1));
}
ring_len :: proc(r: ^$R/Ring) -> int {
	n := 0;
	if r != nil {
		n = 1;
		for p := ring_next(p); p != r; p = p.next {
			n += 1;
		}
	}
	return n;
}

