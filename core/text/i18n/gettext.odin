package i18n
/*
	A parser for GNU GetText .MO files.

	Copyright 2021-2022 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	A from-scratch implementation based after the specification found here:
		https://www.gnu.org/software/gettext/manual/html_node/MO-Files.html

	Options are ignored as they're not applicable to this format.
	They're part of the signature for consistency with other catalog formats.

	List of contributors:
		Jeroen van Rijn: Initial implementation.
*/
import "core:os"
import "core:strings"
import "core:bytes"

parse_mo_from_slice :: proc(data: []u8, options := DEFAULT_PARSE_OPTIONS, pluralizer: proc(int) -> int = nil, allocator := context.allocator) -> (translation: ^Translation, err: Error) {
	context.allocator = allocator
	/*
		An MO file should have at least a 4-byte magic, 2 x 2 byte version info,
		a 4-byte number of strings value, and 2 x 4-byte offsets.
	*/
	if len(data) < 20 {
		return {}, .MO_File_Invalid
	}

	/*
		Check magic. Should be 0x950412de in native Endianness.
	*/
	native := true
	magic  := read_u32(data, native) or_return

	if magic != 0x950412de {
		native = false
		magic = read_u32(data, native) or_return

		if magic != 0x950412de { return {}, .MO_File_Invalid_Signature }
	}

	/*
		We can ignore version_minor at offset 6.
	*/
	version_major := read_u16(data[4:]) or_return
	if version_major > 1 { return {}, .MO_File_Unsupported_Version }

	count             := read_u32(data[ 8:]) or_return
	original_offset   := read_u32(data[12:]) or_return
	translated_offset := read_u32(data[16:]) or_return

	if count == 0 { return {}, .Empty_Translation_Catalog }

	/*
		Initalize Translation, interner and optional pluralizer.
	*/
	translation = new(Translation)
	translation.pluralize = pluralizer
	strings.intern_init(&translation.intern, allocator, allocator)

	// Gettext MO files only have one section.
	translation.k_v[""] = {}
	section := &translation.k_v[""]

	for n := u32(0); n < count; n += 1 {
		/*
			Grab string's original length and offset.
		*/
		offset := original_offset + 8 * n
		if len(data) < int(offset + 8) { return translation, .MO_File_Invalid }

		o_length := read_u32(data[offset    :], native) or_return
		o_offset := read_u32(data[offset + 4:], native) or_return

		offset = translated_offset + 8 * n
		if len(data) < int(offset + 8) { return translation, .MO_File_Invalid }

		t_length := read_u32(data[offset    :], native) or_return
		t_offset := read_u32(data[offset + 4:], native) or_return

		max_offset := int(max(o_offset + o_length + 1, t_offset + t_length + 1))
		if len(data) < max_offset { return translation, .Premature_EOF }

		key := data[o_offset:][:o_length]
		val := data[t_offset:][:t_length]

		/*
			Could be a pluralized string.
		*/
		zero := []byte{0}

		keys := bytes.split(key, zero)
		vals := bytes.split(val, zero)
	
		if len(keys) != len(vals) || max(len(keys), len(vals)) > MAX_PLURALS {
			return translation, .MO_File_Incorrect_Plural_Count
		}

		for k in keys {
			interned_key := strings.intern_get(&translation.intern, string(k))

			interned_vals := make([]string, len(keys))
			last_val: string

			i := 0
			for v in vals {
				interned_vals[i] = strings.intern_get(&translation.intern, string(v))
				last_val = interned_vals[i]
				i += 1
			}
			section[interned_key] = interned_vals
		}
		delete(vals)
		delete(keys)
	}
	return
}

parse_mo_file :: proc(filename: string, options := DEFAULT_PARSE_OPTIONS, pluralizer: proc(int) -> int = nil, allocator := context.allocator) -> (translation: ^Translation, err: Error) {
	context.allocator = allocator

	data, data_ok := os.read_entire_file(filename)
	defer delete(data)

	if !data_ok { return {}, .File_Error }

	return parse_mo_from_slice(data, options, pluralizer, allocator)
}

parse_mo :: proc { parse_mo_file, parse_mo_from_slice }

/*
	Helpers.
*/
read_u32 :: proc(data: []u8, native_endian := true) -> (res: u32, err: Error) {
	if len(data) < size_of(u32) { return 0, .Premature_EOF }

	val := (^u32)(raw_data(data))^

	if native_endian {
		return val, .None
	} else {
		when ODIN_ENDIAN == .Little {
			return u32(transmute(u32be)val), .None
		} else {
			return u32(transmute(u32le)val), .None
		}
	}
}

read_u16 :: proc(data: []u8, native_endian := true) -> (res: u16, err: Error) {
	if len(data) < size_of(u16) { return 0, .Premature_EOF }

	val := (^u16)(raw_data(data))^

	if native_endian {
		return val, .None
	} else {
		when ODIN_ENDIAN == .Little {
			return u16(transmute(u16be)val), .None
		} else {
			return u16(transmute(u16le)val), .None
		}
	}
}