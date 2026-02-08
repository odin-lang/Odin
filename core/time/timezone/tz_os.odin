#+build !freestanding
#+build !js
package timezone

import os "core:os/os2"
import "core:time/datetime"

load_tzif_file :: proc(filename: string, region_name: string, allocator := context.allocator) -> (out: ^datetime.TZ_Region, ok: bool) {
	tzif_data, tzif_err := os.read_entire_file(filename, allocator)
	if tzif_err != nil {
		return nil, false
	}
	defer delete(tzif_data, allocator)
	return parse_tzif(tzif_data, region_name, allocator)
}

region_load_from_file :: proc(file_path, reg: string, allocator := context.allocator) ->  (out_reg: ^datetime.TZ_Region, ok: bool) {
	return load_tzif_file(file_path, reg, allocator)
}