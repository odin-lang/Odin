// #import "fmt.odin";
// Multiple precision decimal numbers
// NOTE: This is only for floating point printing and nothing else

type Decimal struct {
	digits:        [384]u8, // big-endian digits
	count:         int,
	decimal_point: int,
	neg, trunc:    bool,
}

proc decimal_to_string(buf: []u8, a: ^Decimal) -> string {
	proc digit_zero(buf: []u8) -> int {
		for _, i in buf {
			buf[i] = '0';
		}
		return len(buf);
	}


	var n = 10 + a.count + abs(a.decimal_point);

	// TODO(bill): make this work with a buffer that's not big enough
	assert(len(buf) >= n);
	buf = buf[0..<n];

	if a.count == 0 {
		buf[0] = '0';
		return string(buf[0..<1]);
	}

	var w = 0;
	if a.decimal_point <= 0 {
		buf[w] = '0'; w++;
		buf[w] = '.'; w++;
		w += digit_zero(buf[w ..< w-a.decimal_point]);
		w += copy(buf[w..], a.digits[0..<a.count]);
	} else if a.decimal_point < a.count {
		w += copy(buf[w..], a.digits[0..<a.decimal_point]);
		buf[w] = '.'; w++;
		w += copy(buf[w..], a.digits[a.decimal_point ..< a.count]);
	} else {
		w += copy(buf[w..], a.digits[0..<a.count]);
		w += digit_zero(buf[w ..< w+a.decimal_point-a.count]);
	}

	return string(buf[0..<w]);
}

// trim trailing zeros
proc trim(a: ^Decimal) {
	for a.count > 0 && a.digits[a.count-1] == '0' {
		a.count--;
	}
	if a.count == 0 {
		a.decimal_point = 0;
	}
}


proc assign(a: ^Decimal, i: u64) {
	var buf: [32]u8;
	var n = 0;
	for i > 0 {
		var j = i/10;
		i -= 10*j;
		buf[n] = u8('0'+i);
		n++;
		i = j;
	}

	a.count = 0;
	for n--; n >= 0; n-- {
		a.digits[a.count] = buf[n];
		a.count++;
	}
	a.decimal_point = a.count;
	trim(a);
}

const uint_size = 8*size_of(uint);
const max_shift = uint_size-4;

proc shift_right(a: ^Decimal, k: uint) {
	var r = 0; // read index
	var w = 0; // write index

	var n: uint;
	for ; n>>k == 0; r++ {
		if r >= a.count {
			if n == 0 {
				// Just in case
				a.count = 0;
				return;
			}
			for n>>k == 0 {
				n = n * 10;
				r++;
			}
			break;
		}
		var c = uint(a.digits[r]);
		n = n*10 + c - '0';
	}
	a.decimal_point -= r-1;

	var mask: uint = (1<<k) - 1;

	for ; r < a.count; r++ {
		var c = uint(a.digits[r]);
		var dig = n>>k;
		n &= mask;
		a.digits[w] = u8('0' + dig);
		w++;
		n = n*10 + c - '0';
	}

	for n > 0 {
		var dig = n>>k;
		n &= mask;
		if w < len(a.digits) {
			a.digits[w] = u8('0' + dig);
			w++;
		} else if dig > 0 {
			a.trunc = true;
		}
		n *= 10;
	}


	a.count = w;
	trim(a);
}

proc shift_left(a: ^Decimal, k: uint) {
	var delta = int(k/4);

	var r = a.count;       // read index
	var w = a.count+delta; // write index

	var n: uint;
	for r--; r >= 0; r-- {
		n += (uint(a.digits[r]) - '0') << k;
		var quo = n/10;
		var rem = n - 10*quo;
		w--;
		if w < len(a.digits) {
			a.digits[w] = u8('0' + rem);
		} else if rem != 0 {
			a.trunc = true;
		}
		n = quo;
	}

	for n > 0 {
		var quo = n/10;
		var rem = n - 10*quo;
		w--;
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

proc shift(a: ^Decimal, k: int) {
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

proc can_round_up(a: ^Decimal, nd: int) -> bool {
	if nd < 0 || nd >= a.count { return false ; }
	if a.digits[nd] == '5' && nd+1 == a.count {
		if a.trunc {
			return true;
		}
		return nd > 0 && (a.digits[nd-1]-'0')%2 != 0;
	}

	return a.digits[nd] >= '5';
}

proc round(a: ^Decimal, nd: int) {
	if nd < 0 || nd >= a.count { return; }
	if can_round_up(a, nd) {
		round_up(a, nd);
	} else {
		round_down(a, nd);
	}
}

proc round_up(a: ^Decimal, nd: int) {
	if nd < 0 || nd >= a.count { return; }

	for var i = nd-1; i >= 0; i-- {
		if var c = a.digits[i]; c < '9' {
			a.digits[i]++;
			a.count = i+1;
			return;
		}
	}

	// Number is just 9s
	a.digits[0] = '1';
	a.count = 1;
	a.decimal_point++;
}

proc round_down(a: ^Decimal, nd: int) {
	if nd < 0 || nd >= a.count { return; }
	a.count = nd;
	trim(a);
}


// Extract integer part, rounded appropriately. There are no guarantees about overflow.
proc rounded_integer(a: ^Decimal) -> u64 {
	if a.decimal_point > 20 {
		return 0xffff_ffff_ffff_ffff;
	}
	var i: int;
	var n: u64 = 0;
	var m = min(a.decimal_point, a.count);
	for i = 0; i < m; i++ {
		n = n*10 + u64(a.digits[i]-'0');
	}
	for ; i < a.decimal_point; i++ {
		n *= 10;
	}
	if can_round_up(a, a.decimal_point) {
		n++;
	}
	return n;
}
