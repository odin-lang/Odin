#+build js
#+private
package timezone

import "core:time/datetime"

local_tz_name :: proc(check_env: bool, allocator := context.allocator) -> (name: string, success: bool) {
	return
}

_region_load :: proc(_reg_str: string, allocator := context.allocator) -> (out_reg: ^datetime.TZ_Region, success: bool) {
	return nil, true
}
