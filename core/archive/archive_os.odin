#+build !js
package archive

import "core:compress"
import "core:os"

// Opens an archive from a path, a byte slice or a stream, detecting its format
open :: proc{open_from_path, open_from_bytes, open_from_stream}

/*
Opens an archive file, detecting its format

Data `which` doesn't recognize opens as zip when it ends in a zip archive, as a self-extracting
`.exe` does, else as 7z when it is an executable (MZ, ELF or Mach-O) with a 7z archive starting
in its first `sevenz.SFX_SEARCH_MAX` bytes.

*Allocates Using Provided Allocator*

Inputs:
- path: The archive's path
- options: Limits and progress callback for the decoders, see `compress.Options` (default: {})
- allocator: (default: context.allocator)
- read_options: 7z's default password and key-derivation limit; the others ignore them
  (default: {})

Returns:
- a: The archive; `close` it when done
- err: `General_Error.Unknown_Format` if no registered format recognizes it, an OS error, the
  format's error, or `nil`
*/
open_from_path :: proc(path: string, options := compress.Options{}, allocator := context.allocator, read_options := Read_Options{}) -> (a: Archive, err: Error) {
	a.allocator = allocator
	f := os.open(path) or_return
	s := os.to_stream(f)
	head: [DETECT_HEAD_SIZE]u8
	n, head_err := _read_head(s, head[:])
	if head_err != nil {
		os.close(f)
		return a, head_err
	}
	if format := which(head[:n]); format != .Unknown && _procs[format].open_path == nil {
		if err = _open_as(&a, format, s, options, read_options); err != nil {
			os.close(f)
			return
		}
		a.file = s
		return
	}
	os.close(f)
	err = _open_detected(&a, head[:n], path, options, read_options)
	return
}

/*
Converts a member's Unix mode to `os.Permissions`

Inputs:
- fi: The member's info

Returns:
- permissions: The `0o777` bits of `fi.unix_mode`
*/
to_os_permissions :: proc "contextless" (fi: File_Info) -> (permissions: os.Permissions) {
	return transmute(os.Permissions)(fi.unix_mode & 0o777)
}

/*
Converts a member's entry type to `os.File_Type`

Inputs:
- fi: The member's info

Returns:
- type: The matching file type; `.Undetermined` for hard links, anti-items and unknown types
*/
to_os_file_type :: proc "contextless" (fi: File_Info) -> (type: os.File_Type) {
	switch fi.type {
	case .Regular:          return .Regular
	case .Directory:        return .Directory
	case .Symlink:          return .Symlink
	case .Named_Pipe:       return .Named_Pipe
	case .Character_Device: return .Character_Device
	case .Block_Device:     return .Block_Device
	case .Hard_Link, .Anti, .Unknown:
	}
	return .Undetermined
}
