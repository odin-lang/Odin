// #import "fmt.odin";
// Multiple precision decimal numbers
// NOTE: This is only for floating point printing and nothing else

Decimal :: struct {
	digits:        [384]u8; // big-endian digits
	count:         int;
	decimal_point: int;
	neg, trunc:    bool;
}

decimal_to_string :: proc(buf: []u8, a: ^Decimal) -> string {
	digit_zero :: proc(buf: []u8) -> int {
		for _, i in buf do buf[i] = '0';
		return len(buf);
	}


	n := 10 + a.count + abs(a.decimal_point);

	// TODO(bill): make this work with a buffer that's not big enough
	assert(len(buf) >= n);
	buf = buf[0..n];

	if a.count == 0 {
		buf[0] = '0';
		return string(buf[0..1]);
	}

	w := 0;
	if a.decimal_point <= 0 {
		buf[w] = '0'; w+=1;
		buf[w] = '.'; w+=1;
		w += digit_zero(buf[w .. w-a.decimal_point]);
		w += copy(buf[w..], a.digits[0..a.count]);
	} else if a.decimal_point < a.count {
		w += copy(buf[w..], a.digits[0..a.decimal_point]);
		buf[w] = '.'; w+=1;
		w += copy(buf[w..], a.digits[a.decimal_point .. a.count]);
	} else {
		w += copy(buf[w..], a.digits[0..a.count]);
		w += digit_zero(buf[w .. w+a.decimal_point-a.count]);
	}

	return string(buf[0..w]);
}

// trim trailing zeros
trim :: proc(a: ^Decimal) {
	for a.count > 0 && a.digits[a.count-1] == '0' {
		a.count -= 1;
	}
	if a.count == 0 {
		a.decimal_point = 0;
	}
}


assign :: proc(a: ^Decimal, i: u64) {
	buf: [32]u8;
	n := 0;
	for i > 0 {
		j := i/10;
		i -= 10*j;
		buf[n] = u8('0'+i);
		n+=1;
		i = j;
	}

	a.count = 0;
	for n -= 1; n >= 0; n -= 1 {
		a.digits[a.count] = buf[n];
		a.count+=1;
	}
	a.decimal_point = a.count;
	trim(a);
}



shift_right :: proc(a: ^Decimal, k: uint) {
	r := 0; // read index
	w := 0; // write index

	n: uint;
	for ; n>>k == 0; r+=1 {
		if r >= a.count {
			if n == 0 {
				// Just in case
				a.count = 0;
				return;
			}
			for n>>k == 0 {
				n = n * 10;
				r+=1;
			}
			break;
		}
		c := uint(a.digits[r]);
		n = n*10 + c - '0';
	}
	a.decimal_point -= r-1;

	mask: uint = (1<<k) - 1;

	for ; r < a.count; r+=1 {
		c := uint(a.digits[r]);
		dig := n>>k;
		n &= mask;
		a.digits[w] = u8('0' + dig);
		w+=1;
		n = n*10 + c - '0';
	}

	for n > 0 {
		dig := n>>k;
		n &= mask;
		if w < len(a.digits) {
			a.digits[w] = u8('0' + dig);
			w+=1;
		} else if dig > 0 {
			a.trunc = true;
		}
		n *= 10;
	}


	a.count = w;
	trim(a);
}

shift_left :: proc(a: ^Decimal, k: uint) {
	delta := int(k/4);

	r := a.count;       // read index
	w := a.count+delta; // write index

	n: uint;
	for r -= 1; r >= 0; r -= 1 {
		n += (uint(a.digits[r]) - '0') << k;
		quo := n/10;
		rem := n - 10*quo;
		w -= 1;
		if w < len(a.digits) {
			a.digits[w] = u8('0' + rem);
		} else if rem != 0 {
			a.trunc = true;
		}
		n = quo;
	}

	for n > 0 {
		quo := n/10;
		rem := n - 10*quo;
		w -= 1;
		if 0 <= w && w < len(a.digits) {
			a.digits[w] = u8('0' + rem);
		} else if rem != 0 {
			a.trunc = true;
		}
		n = quo;
	}

	a.count += delta;
	a.count = min(a.count, len(a.digits));
	a.decimal_point += delta;
	trim(a);
}

shift :: proc(a: ^Decimal, k: int) {
	uint_size :: 8*size_of(uint);
	max_shift :: uint_size-4;

	match {
	case a.count == 0:
		// no need to update
	case k > 0:
		for k > max_shift {
			shift_left(a, max_shift);
			k -= max_shift;
		}
		shift_left(a, uint(k));


	case k < 0:
		for k < -max_shift {
			shift_right(a, max_shift);
			k += max_shift;
		}
		shift_right(a, uint(-k));
	}
}

can_round_up :: proc(a: ^Decimal, nd: int) -> bool {
	if nd < 0 || nd >= a.count { return false ; }
	if a.digits[nd] == '5' && nd+1 == a.count {
		if a.trunc do return true;
		return nd > 0 && (a.digits[nd-1]-'0')%2 != 0;
	}

	return a.digits[nd] >= '5';
}

round :: proc(a: ^Decimal, nd: int) {
	if nd < 0 || nd >= a.count { return; }
	if can_round_up(a, nd) {
		round_up(a, nd);
	} else {
		round_down(a, nd);
	}
}

round_up :: proc(a: ^Decimal, nd: int) {
	if nd < 0 || nd >= a.count { return; }

	for i := nd-1; i >= 0; i -= 1 {
		if c := a.digits[i]; c < '9' {
			a.digits[i]+=1;
			a.count = i+1;
			return;
		}
	}

	// Number is just 9s
	a.digits[0] = '1';
	a.count = 1;
	a.decimal_point+=1;
}

round_down :: proc(a: ^Decimal, nd: int) {
	if nd < 0 || nd >= a.count { return; }
	a.count = nd;
	trim(a);
}


// Extract integer part, rounded appropriately. There are no guarantees about overflow.
rounded_integer :: proc(a: ^Decimal) -> u64 {
	if a.decimal_point > 20 {
		return 0xffff_ffff_ffff_ffff;
	}
	i: int = 0;
	n: u64 = 0;
	m := min(a.decimal_point, a.count);
	for ; i < m; i += 1 {
		n = n*10 + u64(a.digits[i]-'0');
	}
	for ; i < a.decimal_point; i += 1 {
		n *= 10;
	}
	if can_round_up(a, a.decimal_point) {
		n+=1;
	}
	return n;
}
