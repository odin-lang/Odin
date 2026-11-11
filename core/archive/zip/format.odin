#+private
package archive_zip

import "base:runtime"
import "core:archive"
import "core:encoding/endian"
import "core:hash"
import "core:time"
import "core:time/datetime"
import "core:time/timezone"
import "core:unicode/utf8"

find_extra :: proc "contextless" (extra: []u8, want: Extra_ID) -> (data: []u8, ok: bool) {
	extra := extra
	for id, found in next_extra(&extra) {
		if id == want {
			return found, true
		}
	}
	return
}

find_end :: proc "contextless" (tail: []u8) -> (pos: int, ok: bool) {
	if len(tail) < size_of(End_Record) {
		return
	}
	for i := len(tail) - size_of(End_Record); i >= 0; i -= 1 {
		if _signature(tail, i) == .End && i + size_of(End_Record) + int(_u16(tail, i + 20)) == len(tail) {
			return i, true
		}
	}
	for i := len(tail) - size_of(End_Record); i >= 0; i -= 1 {
		if _signature(tail, i) == .End && i + size_of(End_Record) + int(_u16(tail, i + 20)) <= len(tail) {
			return i, true
		}
	}
	return
}

parse_end :: proc "contextless" (b: []u8) -> (end: End_Record, ok: bool) {
	if len(b) < size_of(End_Record) || _signature(b, 0) != .End {
		return
	}
	return (^End_Record)(raw_data(b))^, true
}

parse_zip64_locator :: proc "contextless" (b: []u8) -> (locator: Zip64_Locator, ok: bool) {
	if len(b) < size_of(Zip64_Locator) || _signature(b, 0) != .Zip64_Locator {
		return
	}
	return (^Zip64_Locator)(raw_data(b))^, true
}

parse_zip64_end :: proc "contextless" (b: []u8) -> (end: Zip64_End_Record, ok: bool) {
	if len(b) < size_of(Zip64_End_Record) || _signature(b, 0) != .Zip64_End {
		return
	}
	return (^Zip64_End_Record)(raw_data(b))^, true
}

parse_central :: proc "contextless" (directory: []u8, offset: int) -> (header: Central_Header, name, extra, comment: []u8, next: int, err: Zip_Error) {
	if offset < 0 || len(directory) - offset < size_of(Central_Header) || _signature(directory, offset) != .Central {
		err = .Invalid_Central_Directory
		return
	}
	header = (^Central_Header)(&directory[offset])^
	n := int(header.name_length)
	m := int(header.extra_length)
	k := int(header.comment_length)
	start := offset + size_of(Central_Header)
	next = start + n + m + k
	if next > len(directory) {
		err = .Invalid_Central_Directory
		return
	}
	name    = directory[start:][:n]
	extra   = directory[start + n:][:m]
	comment = directory[start + n + m:][:k]
	return
}

parse_local :: proc "contextless" (b: []u8) -> (header: Local_Header, ok: bool) {
	if len(b) < size_of(Local_Header) || _signature(b, 0) != .Local {
		return
	}
	return (^Local_Header)(raw_data(b))^, true
}

apply_zip64 :: proc "contextless" (data: []u8, size, compressed_size, offset: ^i64, disk: ^u32) -> (ok: bool) {
	pos := 0
	for field in ([3]^i64{size, compressed_size, offset}) {
		if field^ != 0xFFFF_FFFF {
			continue
		}
		if pos + 8 > len(data) {
			return false
		}
		value := _u64(data, pos)
		if value > u64(max(i64)) {
			return false
		}
		field^ = i64(value)
		pos += 8
	}
	if disk^ == 0xFFFF {
		if pos + 4 > len(data) {
			return false
		}
		disk^ = _u32(data, pos)
	}
	return true
}

zip_method :: proc "contextless" (method: Method) -> (m: archive.Method) {
	#partial switch method {
	case .Store:                                    return .Store
	case .Shrink:                                   return .Shrink
	case .Reduce_1, .Reduce_2, .Reduce_3, .Reduce_4: return .Reduce
	case .Implode:                                  return .Implode
	case .Deflate:                                  return .Deflate
	case .Deflate64:                                return .Deflate64
	case .BZip2:                                    return .BZip2
	case .LZMA:                                     return .LZMA
	case .XZ:                                       return .XZ
	case .PPMd:                                     return .PPMd_I
	}
	return .Unknown
}

method_supported :: proc "contextless" (method: Method) -> bool {
	#partial switch method {
	case .Store, .Shrink, .Reduce_1, .Reduce_2, .Reduce_3, .Reduce_4, .Implode, .Deflate, .Deflate64, .BZip2, .LZMA, .PPMd:
		return true
	}
	return false
}

name_is_utf8 :: proc "contextless" (raw: []u8, flags: Flags, host: Host) -> bool {
	if .UTF8 in flags {
		return true
	}
	return (host == .Unix || host == .Darwin) && utf8.valid_string(string(raw))
}

decode_name :: proc(dst: ^[dynamic]u8, raw: []u8, flags: Flags, host: Host, extra: []u8) -> (err: runtime.Allocator_Error) {
	start := len(dst)
	if .UTF8 not_in flags {
		if data, found := find_extra(extra, .Unicode_Path); found && len(data) >= 5 && data[0] == 1 && _u32(data, 1) == hash.crc32(raw) {
			append_text(dst, data[5:], true) or_return
			_dos_separators(dst[start:], host)
			return
		}
	}
	append_text(dst, raw, name_is_utf8(raw, flags, host)) or_return
	_dos_separators(dst[start:], host)
	return
}

append_text :: proc(dst: ^[dynamic]u8, raw: []u8, is_utf8: bool) -> (err: runtime.Allocator_Error) {
	if is_utf8 {
		_, err = append(dst, ..raw)
		return
	}
	for c in raw {
		if c < 0x80 {
			append(dst, c) or_return
			continue
		}
		encoded, n := utf8.encode_rune(rune(CP437_HIGH[c - 0x80]))
		append(dst, ..encoded[:n]) or_return
	}
	return
}

fill_info :: proc(fi: ^archive.File_Info, header: Central_Header, name, central_extra, local_extra: []u8, zone: ^datetime.TZ_Region) {
	method      := header.method
	aes_version := u16(0)
	if header.method == .AES {
		if data, found := find_extra(central_extra, .AES); found && len(data) >= 7 {
			aes_version = _u16(data, 0)
			method      = Method(_u16(data, 5))
		}
	}
	fi.method    = zip_method(method)
	fi.method_id = u64(method)
	fi.encrypted = header.flags & ENCRYPTED_FLAGS != {} || header.method == .AES
	fi.supported = method_supported(method) && !fi.encrypted
	if aes_version != 2 {
		fi.crc32 = u32(header.crc32)
	}

	host     := header.made_by_host
	external := u32(header.external_attributes)
	mode     := external >> 16
	unix     := host == .Unix || host == .Darwin
	last     := name[len(name) - 1] if len(name) > 0 else 0
	fi.type = .Regular
	switch {
	case last == '/' || (_dos_host(host) && last == '\\'):
		fi.type = .Directory
	case unix && mode & archive.UNIX_TYPE_MASK != 0:
		fi.type = _unix_type(mode)
	case external & archive.DOS_DIRECTORY != 0:
		fi.type = .Directory
	}
	fi.dos_attributes = external & 0xFFFF
	if unix && mode != 0 {
		fi.unix_mode = mode
		if mode & archive.UNIX_TYPE_MASK == 0 {
			fi.unix_mode |= archive.unix_type_bits(fi.type)
		}
		if fi.dos_attributes == 0 {
			fi.dos_attributes = archive.dos_attributes_from_unix(fi.unix_mode, fi.type)
		}
	} else {
		attributes := external & 0xFF
		if fi.type == .Directory {
			attributes |= archive.DOS_DIRECTORY
		}
		fi.unix_mode = archive.unix_mode_from_dos(attributes)
	}

	_fill_times(fi, header, central_extra, local_extra, zone)
	_fill_owner(fi, central_extra, local_extra)
}

dos_time :: proc(dos_time, dos_date: u16, zone: ^datetime.TZ_Region = nil) -> (t: time.Time) {
	if dos_date == 0 {
		return
	}
	year   := 1980 + int(dos_date >> 9)
	month  := int(dos_date >> 5 & 15)
	day    := int(dos_date & 31)
	hour   := int(dos_time >> 11)
	minute := int(dos_time >> 5 & 63)
	second := int(dos_time & 31) * 2
	ok: bool
	t, ok = time.components_to_time(year, month, day, hour, minute, min(second, 59))
	if !ok || zone == nil {
		return
	}
	wall, wall_ok := time.time_to_datetime(t)
	if !wall_ok {
		return
	}
	wall.tz = zone
	utc, utc_ok := timezone.datetime_to_utc(wall)
	if !utc_ok {
		return
	}
	if converted, converted_ok := time.datetime_to_time(utc); converted_ok {
		t = converted
	}
	return
}

Time_Field :: enum u8 {
	Modification,
	Access,
	Creation,
}

Time_Fields :: bit_set[Time_Field; u8]

_fill_times :: proc(fi: ^archive.File_Info, header: Central_Header, central_extra, local_extra: []u8, zone: ^datetime.TZ_Region) {
	targets := [Time_Field]^time.Time{
		.Modification = &fi.modification_time,
		.Access       = &fi.access_time,
		.Creation     = &fi.creation_time,
	}
	set: Time_Fields
	for id in ([3]Extra_ID{.NTFS, .Timestamp, .Infozip_Unix}) {
		for extra in ([2][]u8{central_extra, local_extra}) {
			data := find_extra(extra, id) or_continue
			times: [Time_Field]time.Time
			found: Time_Fields
			#partial switch id {
			case .NTFS:         found = _ntfs_times(data, &times)
			case .Timestamp:    found = _timestamp_times(data, &times)
			case .Infozip_Unix: found = _infozip_unix_times(data, &times)
			}
			for field in Time_Field {
				if field in found && field not_in set {
					targets[field]^ = times[field]
					set += {field}
				}
			}
		}
	}
	if .Modification not_in set {
		fi.modification_time = dos_time(u16(header.dos_time), u16(header.dos_date), zone)
	}
}

_ntfs_times :: proc "contextless" (data: []u8, times: ^[Time_Field]time.Time) -> (found: Time_Fields) {
	pos := 4
	for pos + 4 <= len(data) {
		tag  := _u16(data, pos)
		size := int(_u16(data, pos + 2))
		pos += 4
		if pos + size > len(data) {
			break
		}
		if tag == 1 && size >= 24 {
			for field in Time_Field {
				if t, ok := _ntfs_time(_u64(data, pos + 8 * int(field))); ok {
					times[field] = t
					found += {field}
				}
			}
		}
		pos += size
	}
	return
}

_ntfs_time :: proc "contextless" (filetime: u64) -> (t: time.Time, ok: bool) {
	if filetime == 0 || filetime > u64(max(i64)) {
		return
	}
	delta := i64(filetime) - NTFS_EPOCH_DELTA
	if delta > max(i64) / 100 || delta < min(i64) / 100 {
		return
	}
	return time.Time{_nsec = delta * 100}, true
}

_timestamp_times :: proc "contextless" (data: []u8, times: ^[Time_Field]time.Time) -> (found: Time_Fields) {
	if len(data) < 1 {
		return
	}
	flags := transmute(Time_Fields)data[0]
	pos   := 1
	for field in Time_Field {
		if field not_in flags {
			continue
		}
		if pos + 4 > len(data) {
			break
		}
		times[field] = time.unix(i64(i32(_u32(data, pos))), 0)
		found += {field}
		pos += 4
	}
	return
}

_infozip_unix_times :: proc "contextless" (data: []u8, times: ^[Time_Field]time.Time) -> (found: Time_Fields) {
	if len(data) < 8 {
		return
	}
	times[.Access]       = time.unix(i64(i32(_u32(data, 0))), 0)
	times[.Modification] = time.unix(i64(i32(_u32(data, 4))), 0)
	return {.Access, .Modification}
}

_fill_owner :: proc "contextless" (fi: ^archive.File_Info, central_extra, local_extra: []u8) {
	for extra in ([2][]u8{central_extra, local_extra}) {
		data := find_extra(extra, .Unix) or_continue
		if len(data) < 3 || data[0] != 1 {
			continue
		}
		n := int(data[1])
		if n > 8 || 3 + n > len(data) {
			continue
		}
		m := int(data[2 + n])
		if m > 8 || 3 + n + m > len(data) {
			continue
		}
		fi.uid = _var_le(data[2:][:n])
		fi.gid = _var_le(data[3 + n:][:m])
		return
	}
	if data, found := find_extra(local_extra, .Infozip_Unix); found && len(data) >= 12 {
		fi.uid = i64(_u16(data, 8))
		fi.gid = i64(_u16(data, 10))
	}
}

_unix_type :: proc "contextless" (mode: u32) -> (type: archive.Entry_Type) {
	switch mode & archive.UNIX_TYPE_MASK {
	case archive.UNIX_REGULAR:          return .Regular
	case archive.UNIX_DIRECTORY:        return .Directory
	case archive.UNIX_SYMLINK:          return .Symlink
	case archive.UNIX_NAMED_PIPE:       return .Named_Pipe
	case archive.UNIX_CHARACTER_DEVICE: return .Character_Device
	case archive.UNIX_BLOCK_DEVICE:     return .Block_Device
	}
	return .Unknown
}

_dos_host :: #force_inline proc "contextless" (host: Host) -> bool {
	return host == .MS_DOS || host == .OS2_HPFS || host == .NTFS || host == .VFAT
}

_dos_separators :: proc "contextless" (name: []u8, host: Host) {
	if !_dos_host(host) {
		return
	}
	for &c in name {
		if c == '\\' {
			c = '/'
		}
	}
}

_var_le :: proc "contextless" (b: []u8) -> (value: i64) {
	v: u64
	for c, i in b {
		v |= u64(c) << (8 * uint(i))
	}
	return i64(v)
}

_signature :: #force_inline proc "contextless" (b: []u8, i: int) -> Signature {
	return Signature(_u32(b, i))
}

_u16 :: #force_inline proc "contextless" (b: []u8, i: int) -> u16 {
	return endian.unchecked_get_u16le(b[i:][:2])
}

_u32 :: #force_inline proc "contextless" (b: []u8, i: int) -> u32 {
	return endian.unchecked_get_u32le(b[i:][:4])
}

_u64 :: #force_inline proc "contextless" (b: []u8, i: int) -> u64 {
	return endian.unchecked_get_u64le(b[i:][:8])
}
