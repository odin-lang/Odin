package test_issue_inferred_default_overflow

BIG :: 1 << 64
HUGE :: 1.5e400
WIDE :: 'a' + 0x7fffffff

param :: proc(n := BIG) {}
float_param :: proc(x := HUGE) {}
rune_param :: proc(r := WIDE) {}
poly_param :: proc(x: $T, n := BIG) {}
result :: proc() -> (n := BIG) { return }
Record :: struct($N := BIG) {}
