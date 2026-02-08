#+build darwin, linux, freebsd, openbsd, netbsd
#+private
package timezone

import os "core:os/os2"
import    "core:strings"
import    "core:time/datetime"

local_tz_name :: proc(allocator := context.allocator) -> (name: string, success: bool) {
	local_str, ok := os.lookup_env("TZ", allocator)
	if !ok {
		orig_localtime_path := "/etc/localtime"
		path, err := os.get_absolute_path(orig_localtime_path, allocator)
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
			data, data_err := os.read_entire_file("/var/db/zoneinfo", allocator)
			if data_err != nil {
				return "", false
			}
			return strings.trim_right_space(string(data)), true
		}

		// Looking for tz path (ex fmt: "UTC", "Etc/UTC" or "America/Los_Angeles")
		path_dir, path_file := os.split_path(path)

		if path_dir == "" {
			return
		}
		upper_path_dir, upper_path_chunk := os.split_path(path_dir[:len(path_dir)])
		if upper_path_dir == "" {
			return
		}

		if strings.contains(upper_path_chunk, "zoneinfo") {
			region_str, err := strings.clone(path_file, allocator)
			if err != nil { return }
			return region_str, true
		} else {
			region_str, region_str_err := os.join_path({upper_path_chunk, path_file}, allocator = allocator)
			if region_str_err != nil { return }
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

	tzdir_str, tzdir_ok := os.lookup_env("TZDIR", allocator)
	defer if tzdir_ok { delete(tzdir_str, allocator) }

	if tzdir_ok {
		region_path := filepath.join({tzdir_str, reg_str}, allocator)
		defer delete(region_path, allocator)

		if tz_reg, ok := load_tzif_file(region_path, reg_str, allocator); ok {
			return tz_reg, true
		}
	}

	db_paths := []string{"/usr/share/zoneinfo", "/share/zoneinfo", "/etc/zoneinfo"}
	for db_path in db_paths {
		region_path := filepath.join({db_path, reg_str}, allocator)
		defer delete(region_path, allocator)

		if tz_reg, ok := load_tzif_file(region_path, reg_str, allocator); ok {
			return tz_reg, true
		}
	}

	return nil, false
}