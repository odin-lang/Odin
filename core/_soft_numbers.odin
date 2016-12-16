#shared_global_scope;

/*
#import "fmt.odin"

__u128_mod :: proc(a, b: u128) -> u128 #link_name "__umodti3" {
	_, r := __u128_quo_mod(a, b)
	return r
}

__u128_quo :: proc(a, b: u128) -> u128 #link_name "__udivti3" {
	n, _ := __u128_quo_mod(a, b)
	return n
}

__i128_mod :: proc(a, b: i128) -> i128 #link_name "__modti3" {
	_, r := __i128_quo_mod(a, b)
	return r
}

__i128_quo :: proc(a, b: i128) -> i128 #link_name "__divti3" {
	n, _ := __i128_quo_mod(a, b)
	return n
}

__i128_quo_mod :: proc(a, b: i128) -> (i128, i128) #link_name "__divmodti4" {
	s := b >> 127
	b = (b ~ s) - s
	s = a >> 127
	a = (a ~ s) - s

	n, r := __u128_quo_mod(a as u128, b as u128)
	return (n as i128 ~ s) - s, (r as i128 ~ s) - s
}


__u128_quo_mod :: proc(a, b: u128) -> (u128, u128) #link_name "__udivmodti4" {
	clz :: proc(x: u64) -> u64 {
		clz_u64 :: proc(x: u64, is_zero_undef: bool) -> u64 #foreign "llvm.ctlz.i64"
		return clz_u64(x, false)
	}
	ctz :: proc(x: u64) -> u64 {
		ctz_u64 :: proc(x: u64, is_zero_undef: bool) -> u64 #foreign "llvm.cttz.i64"
		return ctz_u64(x, false)
	}


	u128_lo_hi :: raw_union {
		all: u128
		using _lohi: struct {lo, hi: u64;}
	}

	n, d, q, r: u128_lo_hi
	sr: u64

	n.all = a
	d.all = b

	if n.hi == 0 {
		if d.hi == 0 {
			return (n.lo / d.lo) as u128, (n.lo % d.lo) as u128
		}
		return 0, n.lo as u128
	}
	if d.lo == 0 {
		if d.hi == 0 {
			return (n.hi / d.lo) as u128, (n.hi % d.lo) as u128
		}
		if n.lo == 0 {
			r.hi = n.hi % d.hi
			r.lo = 0
			return (n.hi / d.hi) as u128, r.all
		}
		if (d.hi & (d.hi-1)) == 0 {
			r.lo = n.lo
			r.hi = n.hi & (d.hi-1)
			return (n.hi >> ctz(d.hi)) as u128, r.all
		}

		sr = clz(d.hi) - clz(n.hi)
		if sr > 64 - 2 {
			return 0, n.all
		}
		sr++
		q.lo = 0
		q.hi = n.lo << (64-sr)
		r.hi = n.hi >> sr
		r.lo = (n.hi << (64-sr)) | (n.lo >> sr)
	} else {
		if d.hi == 0 {
			if (d.lo & (d.lo - 1)) == 0 {
				rem := (n.lo % (d.lo - 1)) as u128
				if d.lo == 1 {
					return n.all, rem
				}
				sr = ctz(d.lo)
				q.hi = n.hi >> sr
				q.lo = (n.hi << (64-sr)) | (n.lo >> sr)
				return q.all, rem
			}

			sr = 1 + 64 + clz(d.lo) - clz(n.hi)

			q.all = n.all << (128-sr)
			r.all = n.all >> sr
			if sr == 64 {
				q.lo = 0
				q.hi = n.lo
				r.hi = 0
				r.lo = n.hi
			} else if sr < 64 {
				q.lo = 0
				q.hi = n.lo << (64-sr)
				r.hi = n.hi >> sr
				r.lo = (n.hi << (64-sr)) | (n.lo >> sr)
			} else {
				q.lo = n.lo << (128-sr)
				q.hi = (n.hi << (128-sr)) | (n.lo >> (sr-64))
				r.hi = 0
				r.lo = n.hi >> (sr-64)
			}
		} else {
			sr = clz(d.hi) - clz(n.hi)
			if sr > 64-1 {
				return 0, n.all
			}
			sr++
			q.lo = 0
			q.hi = n.lo << (64-sr)
			r.all = n.all >> sr
			if sr < 64 {
				r.hi = n.hi >> sr
				r.lo = (n.hi << (64-sr)) | (n.lo >> sr)
			} else {
				r.hi = 0
				r.lo = n.hi
			}
		}
	}

	carry: u64
	for ; sr > 0; sr-- {
		r.hi = (r.hi << 1) | (r.lo >> (64-1))
		r.lo = (r.lo << 1) | (r.hi >> (64-1))
		q.hi = (q.hi << 1) | (q.lo >> (64-1))
		q.lo = (q.lo << 1) | carry

		carry = 0
		if r.all >= d.all {
			r.all -= d.all
			carry = 1
		}
	}

	q.all = (q.all << 1) | (carry as u128)
	return q.all, r.all
}
*/
