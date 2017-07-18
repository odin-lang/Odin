REPLACEMENT_CHAR :: '\uFFFD';
MAX_RUNE         :: '\U0010FFFF';

_surr1           :: 0xd800;
_surr2           :: 0xdc00;
_surr3           :: 0xe000;
_surr_self       :: 0x10000;


is_surrogate :: proc(r: rune) -> bool {
	return _surr1 <= r && r < _surr3;
}

decode_surrogate_pair :: proc(r1, r2: rune) -> rune {
	if _surr1 <= r1 && r1 < _surr2 && _surr2 <= r2 && r2 < _surr3 {
		return (r1-_surr1)<<10 | (r2 - _surr2) + _surr_self;
	}
	return REPLACEMENT_CHAR;
}


encode_surrogate_pair :: proc(r: rune) -> (r1, r2: rune) {
	if r < _surr_self || r > MAX_RUNE {
		return REPLACEMENT_CHAR, REPLACEMENT_CHAR;
	}
	r -= _surr_self;
	return _surr1 + (r>>10)&0x3ff, _surr2 + r&0x3ff;
}

encode :: proc(d: []u16, s: []rune) {
	n := len(s);
	for r in s do if r >= _surr_self do n += 1;

	max_n := min(len(d), n);
	n = 0;

	for r in s {
		match r {
		case 0.._surr1, _surr3.._surr_self:
			d[n] = u16(r);
			n += 1;

		case _surr_self..MAX_RUNE:
			r1, r2 := encode_surrogate_pair(r);
			d[n]    = u16(r1);
			d[n+1]  = u16(r2);
			n += 2;

		case:
			d[n] = u16(REPLACEMENT_CHAR);
			n += 1;
		}
	}
}
