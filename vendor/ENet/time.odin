package ENet

TIME_OVERFLOW :: u32(86400000)

TIME_LESS :: #force_inline proc "contextless" (a, b: u32) -> bool {
	return a - b >= TIME_OVERFLOW
}

TIME_GREATER :: #force_inline proc "contextless" (a, b: u32) -> bool {
	return b - a >= TIME_OVERFLOW
}

TIME_LESS_EQUAL :: #force_inline proc "contextless" (a, b: u32) -> bool {
	return !TIME_GREATER(a, b)
}

TIME_GREATER_EQUAL :: #force_inline proc "contextless" (a, b: u32) -> bool {
	return TIME_LESS(a, b)
}

TIME_DIFFERENCE :: #force_inline proc "contextless" (a, b: u32) -> u32 {
	return a - b >= TIME_OVERFLOW ? b - a : a - b
}