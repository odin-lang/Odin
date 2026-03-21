package odin_libc

import "core:time"

clock_t :: i64

@(require, linkage="strong", link_name="clock")
clock :: proc "c" () -> clock_t {
	return time.tick_now()._nsec
}
