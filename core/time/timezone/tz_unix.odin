#+build darwin, linux, freebsd, openbsd, netbsd
#+private
package timezone

import "core:os"
import "core:strings"
import "core:path/filepath"
import "core:time/datetime"

local_tz_name :: proc(allocator := context.allocator) -> (name: string, success: bool) {
	local_str, ok := os.lookup_env("TZ", allocator)
	if !ok {
		orig_localtime_path := "/etc/localtime"
		path, err := os.absolute_path_from_relative(orig_localtime_path, allocator)
		if err != nil {
			// If we can't find /etc/localtime, fallback to UTC
			if err == .ENOENT {
				str, err2 := strings.clone("UTC", allocator)
				if err2 != nil { return }
				return str, true
			}

			return
		}
		defer delete(path, allocator)

		// FreeBSD makes me sad.
		// This is a hackaround, because FreeBSD copies rather than softlinks their local timezone file,
		// *sometimes* and then stores the original name of the timezone in /var/db/zoneinfo instead
		if path == orig_localtime_path {
			data := os.read_entire_file("/var/db/zoneinfo", allocator) or_return
			return strings.trim_right_space(string(data)), true
		}

		// Looking for tz path (ex fmt: "UTC", "Etc/UTC" or "America/Los_Angeles")
		path_dir, path_file := filepath.split(path)
		if path_dir == "" {
			return
		}
		upper_path_dir, upper_path_chunk := filepath.split(path_dir[:len(path_dir)-1])
		if upper_path_dir == "" {
			return
		}

		if strings.contains(upper_path_chunk, "zoneinfo") {
			region_str, err := strings.clone(path_file, allocator)
			if err != nil { return }
			return region_str, true
		} else {
			region_str, err := filepath.join({upper_path_chunk, path_file}, allocator = allocator)
			if err != nil { return }
			return region_str, true
		}
	}

	if local_str == "" {
		delete(local_str, allocator)

		str, err := strings.clone("UTC", allocator)
		if err != nil { return }
		return str, true
	}

	return local_str, true
}

_region_load :: proc(_reg_str: string, allocator := context.allocator) -> (out_reg: ^datetime.TZ_Region, success: bool) {
	reg_str := _reg_str
	if reg_str == "UTC" {
		return nil, true
	}

	if reg_str == "local" {
		local_name := local_tz_name(allocator) or_return
		if local_name == "UTC" {
			delete(local_name, allocator)
			return nil, true
		}

		reg_str = local_name
	}
	defer if _reg_str == "local" { delete(reg_str, allocator) }

	db_path := "/usr/share/zoneinfo"
	region_path := filepath.join({db_path, reg_str}, allocator)
	defer delete(region_path, allocator)

	return load_tzif_file(region_path, reg_str, allocator)
}
