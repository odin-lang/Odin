// The facts a call's results gather here double with each call to 2^20, so without a limit on them the time and
// memory of `odin check` double with each call
package test_issues

Pair :: struct($T: typeid) {
	a, b: T,
}

pair :: proc(x: $T) -> Pair(T) {
	return {a = x, b = x}
}

nest :: proc(s: string) {
	_ = pair(pair(pair(pair(pair(pair(pair(pair(pair(pair(pair(pair(pair(pair(pair(pair(pair(pair(pair(pair(s))))))))))))))))))))
}
