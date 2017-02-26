// #import "fmt.odin";
// Multiple precision decimal numbers
// NOTE: This is only for floating point printing and nothing else

Decimal :: struct {
	d:     [384]byte, // big-endian digits
	ndu:   int,
	dp:    int,
	neg:   bool,
	trunc: bool,
}

decimal_to_string :: proc(buf: []byte, a: ^Decimal) -> string {
	digit_zero :: proc(buf: []byte) -> int {
		for _, i in buf {
			buf[i] = '0';
		}
		return buf.count;
	}


	n := 10 + a.ndu + abs(a.dp);

	// TODO(bill): make this work with a buffer that's not big enough
	assert(buf.count >= n);
	buf = buf[:n];

	if a.ndu == 0 {
		buf[0] = '0';
		return cast(string)buf[0:1];
	}

	w := 0;
	if a.dp <= 0 {
		buf[w] = '0'; w++;
		buf[w] = '.'; w++;
		w += digit_zero(buf[w: w-a.dp]);
		w += copy(buf[w:], a.d[0:a.ndu]);
	} else if a.dp < a.ndu {
		w += copy(buf[w:], a.d[0:a.dp]);
		buf[w] = '.'; w++;
		w += copy(buf[w:], a.d[a.dp:a.ndu]);
	} else {
		w += copy(buf[w:], a.d[0:a.ndu]);
		w += digit_zero(buf[w : w+a.dp-a.ndu]);
	}

	return cast(string)buf[0:w];
}

// trim trailing zeros
trim :: proc(a: ^Decimal) {
	for a.ndu > 0 && a.d[a.ndu-1] == '0' {
		a.ndu--;
	}
	if a.ndu == 0 {
		a.dp = 0;
	}
}


assign :: proc(a: ^Decimal, i: u64) {
	buf: [32]byte;
	n := 0;
	for i > 0 {
		j := i/10;
		i -= 10*j;
		buf[n] = cast(byte)('0'+i);
		n++;
		i = j;
	}

	a.ndu = 0;
	for n--; n >= 0; n-- {
		a.d[a.ndu] = buf[n];
		a.ndu++;
	}
	a.dp = a.ndu;
	trim(a);
}

uint_size :: 8*size_of(uint);
max_shift :: uint_size-4;

shift_right :: proc(a: ^Decimal, k: uint) {
	r := 0; // read index
	w := 0; // write index

	n: uint;
	for ; n>>k == 0; r++ {
		if r >= a.ndu {
			if n == 0 {
				// Just in case
				a.ndu = 0;
				return;
			}
			for n>>k == 0 {
				n = n * 10;
				r++;
			}
			break;
		}
		c := cast(uint)a.d[r];
		n = n*10 + c - '0';
	}
	a.dp -= r-1;

	mask: uint = (1<<k) - 1;

	for ; r < a.ndu; r++ {
		c := cast(uint)a.d[r];
		dig := n>>k;
		n &= mask;
		a.d[w] = cast(byte)('0' + dig);
		w++;
		n = n*10 + c - '0';
	}

	for n > 0 {
		dig := n>>k;
		n &= mask;
		if w < a.d.count {
			a.d[w] = cast(byte)('0' + dig);
			w++;
		} else if dig > 0 {
			a.trunc = true;
		}
		n *= 10;
	}


	a.ndu = w;
	trim(a);
}

shift_left :: proc(a: ^Decimal, k: uint) {
	delta := cast(int)(k/4);

	r := a.ndu;       // read index
	w := a.ndu+delta; // write index

	n: uint;
	for r--; r >= 0; r-- {
		n += (cast(uint)a.d[r] - '0') << k;
		quo := n/10;
		rem := n - 10*quo;
		w--;
		if w < a.d.count {
			a.d[w] = cast(byte)('0' + rem);
		} else if rem != 0 {
			a.trunc = true;
		}
		n = quo;
	}

	for n > 0 {
		quo := n/10;
		rem := n - 10*quo;
		w--;
		if w < a.d.count {
			a.d[w] = cast(byte)('0' + rem);
		} else if rem != 0 {
			a.trunc = true;
		}
		n = quo;
	}

	a.ndu += delta;
	a.ndu = min(a.ndu, a.d.count);
	a.dp += delta;
	trim(a);
}

shift :: proc(a: ^Decimal, k: int) {
	match {
	case a.ndu == 0:
		// no need to update
	case k > 0:
		for k > max_shift {
			shift_left(a, max_shift);
			k -= max_shift;
		}
		shift_left(a, cast(uint)k);


	case k < 0:
		for k < -max_shift {
			shift_right(a, max_shift);
			k += max_shift;
		}
		shift_right(a, cast(uint)-k);
	}
}

can_round_up :: proc(a: ^Decimal, nd: int) -> bool {
	if nd < 0 || nd >= a.ndu { return false ; }
	if a.d[nd] == '5' && nd+1 == a.ndu {
		if a.trunc {
			return true;
		}
		return nd > 0 && (a.d[nd-1]-'0')%2 != 0;
	}

	return a.d[nd] >= '5';
}

round :: proc(a: ^Decimal, nd: int) {
	if nd < 0 || nd >= a.ndu { return; }
	if can_round_up(a, nd) {
		round_up(a, nd);
	} else {
		round_down(a, nd);
	}
}

round_up :: proc(a: ^Decimal, nd: int) {
	if nd < 0 || nd >= a.ndu { return; }

	for i := nd-1; i >= 0; i-- {
		if c := a.d[i]; c < '9' {
			a.d[i]++;
			a.ndu = i+1;
			return;
		}
	}

	// Number is just 9s
	a.d[0] = '1';
	a.ndu = 1;
	a.dp++;
}

round_down :: proc(a: ^Decimal, nd: int) {
	if nd < 0 || nd >= a.ndu { return; }
	a.ndu = nd;
	trim(a);
}


// Extract integer part, rounded appropriately. There are no guarantees about overflow.
rounded_integer :: proc(a: ^Decimal) -> u64 {
	if a.dp > 20 {
		return 0xffff_ffff_ffff_ffff;
	}
	i: int;
	n: u64 = 0;
	m := min(a.dp, a.ndu);
	for i = 0; i < m; i++ {
		n = n*10 + cast(u64)(a.d[i]-'0');
	}
	for ; i < a.dp; i++ {
		n *= 10;
	}
	if can_round_up(a, a.dp) {
		n++;
	}
	return n;
}
