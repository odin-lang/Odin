package app

foreign import tp "../lib/libtpneeded.so"

foreign tp {
	tp_value :: proc "c" () -> i32 ---
}

main :: proc() {
	assert(tp_value() == 7)
}
