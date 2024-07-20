/*
	Copyright 2022 Jeroen van Rijn <nom@duclavier.com>.
	Made available under Odin's BSD-3 license.

	List of contributors:
		Jeroen van Rijn: Initial implementation.

	An implementation of [shoco](https://github.com/Ed-von-Schleck/shoco) by Christian Schramm.
*/

// package shoco is an implementation of the shoco short string compressor
package compress_shoco

import "base:intrinsics"
import "core:compress"

Shoco_Pack :: struct {
	word:           u32,
	bytes_packed:   i8,
	bytes_unpacked: i8,
	offsets:        [8]u16,
	masks:          [8]i16,
	header_mask:    u8,
	header:         u8,
}

Shoco_Model :: struct {
	min_char:             u8,
	max_char:             u8,
	characters_by_id:     []u8,
	ids_by_character:     [256]i16,
	successors_by_bigram: []i8,
	successors_reversed:  []u8,

	character_count:      u8,
	successor_count:      u8,
	max_successor_n:      i8,
	packs:                []Shoco_Pack,
}

compress_bound :: proc(uncompressed_size: int) -> (worst_case_compressed_size: int) {
	// Worst case compression happens when input is non-ASCII (128-255)
	// Encoded as 0x00 + the byte in question.
	return uncompressed_size * 2
}

decompress_bound :: proc(compressed_size: int, model := DEFAULT_MODEL) -> (maximum_decompressed_size: int) {
	// Best case compression is 2:1
	most: f64
	for pack in model.packs {
		val := f64(compressed_size) / f64(pack.bytes_packed) * f64(pack.bytes_unpacked)
		most = max(most, val)
	}
	return int(most)
}

find_best_encoding :: proc(indices: []i16, n_consecutive: i8, model := DEFAULT_MODEL) -> (res: int) {
	for p := len(model.packs); p > 0; p -= 1 {
		pack := model.packs[p - 1]
		if n_consecutive >= pack.bytes_unpacked {
			have_index := true
			for i := 0; i < int(pack.bytes_unpacked); i += 1 {
				if indices[i] > pack.masks[i] {
					have_index = false
					break
				}
			}
			if have_index {
				return p - 1
			}
		}
	}
	return -1
}

validate_model :: proc(model: Shoco_Model) -> (int, compress.Error) {
	if len(model.characters_by_id) != int(model.character_count) {
		return 0, .Unknown_Compression_Method
	}

	if len(model.successors_by_bigram) != int(model.character_count) * int(model.character_count) {
		return 0, .Unknown_Compression_Method
	}

	if len(model.successors_reversed) != int(model.successor_count) * int(model.max_char - model.min_char) {
		return 0, .Unknown_Compression_Method
	}

	// Model seems legit.
	return 0, nil
}

// Decompresses into provided buffer.
decompress_slice_to_output_buffer :: proc(input: []u8, output: []u8, model := DEFAULT_MODEL) -> (size: int, err: compress.Error) {
	inp, inp_end := 0, len(input)
	out, out_end := 0, len(output)

	validate_model(model) or_return

	for inp < inp_end {
		val  := i8(input[inp])
		mark := int(-1)

		for val < 0 {
			val <<= 1
			mark += 1
		}

		if mark > len(model.packs) {
			return out, .Unknown_Compression_Method
		}

		if mark < 0 {
			if out >= out_end {
				return out, .Output_Too_Short
			}

			// Ignore the sentinel value for non-ASCII chars
			if input[inp] == 0x00 {
				inp += 1
				if inp >= inp_end {
					return out, .Stream_Too_Short
				}
			}
			output[out] = input[inp]
			inp, out = inp + 1, out + 1

		} else {
			pack := model.packs[mark]

			if out + int(pack.bytes_unpacked) > out_end {
				return out, .Output_Too_Short
			} else if inp + int(pack.bytes_packed) > inp_end {
				return out, .Stream_Too_Short
			}

			code := intrinsics.unaligned_load((^u32)(&input[inp]))
			when ODIN_ENDIAN == .Little {
				code = intrinsics.byte_swap(code)
			}

			// Unpack the leading char
			offset := pack.offsets[0]
			mask   := pack.masks[0]

			last_chr := model.characters_by_id[(code >> offset) & u32(mask)]
			output[out] = last_chr

			// Unpack the successor chars
			for i := 1; i < int(pack.bytes_unpacked); i += 1 {
				offset = pack.offsets[i]
				mask   = pack.masks[i]

				index_major := u32(last_chr - model.min_char) * u32(model.successor_count)
				index_minor := (code >> offset) & u32(mask)

				last_chr = model.successors_reversed[index_major + index_minor]

				output[out + i] = last_chr
			}

			out += int(pack.bytes_unpacked)
			inp += int(pack.bytes_packed)
		}
	}

	return out, nil
}

decompress_slice_to_string :: proc(input: []u8, model := DEFAULT_MODEL, allocator := context.allocator) -> (res: string, err: compress.Error) {
	context.allocator = allocator

	if len(input) == 0 {
		return "", .Stream_Too_Short
	}

	max_output_size := decompress_bound(len(input), model)

	buf: [dynamic]u8
	resize(&buf, max_output_size) or_return

	length, result := decompress_slice_to_output_buffer(input, buf[:])
	resize(&buf, length) or_return
	return string(buf[:]), result
}
decompress :: proc{decompress_slice_to_output_buffer, decompress_slice_to_string}

compress_string_to_buffer :: proc(input: string, output: []u8, model := DEFAULT_MODEL, allocator := context.allocator) -> (size: int, err: compress.Error) {
	inp, inp_end := 0, len(input)
	out, out_end := 0, len(output)
	output := output

	validate_model(model) or_return

	indices := make([]i16, model.max_successor_n + 1)
	defer delete(indices)

	last_resort := false

	encode: for inp < inp_end {
		if last_resort {
			last_resort = false

			if input[inp] & 0x80 == 0x80 {
				// Non-ASCII case
				if out + 2 > out_end {
					return out, .Output_Too_Short
				}

				// Put in a sentinel byte
				output[out] = 0x00
				out += 1
			} else {
				// An ASCII byte
				if out + 1 > out_end {
					return out, .Output_Too_Short
				}
			}
			output[out] = input[inp]
			out, inp = out + 1, inp + 1
		} else {
			// Find the longest string of known successors
			indices[0] = model.ids_by_character[input[inp]]
			last_chr_index := indices[0]

			if last_chr_index < 0 {
				last_resort = true
				continue encode
			}

			rest := inp_end - inp
			n_consecutive: i8 = 1
			for ; n_consecutive <= model.max_successor_n; n_consecutive += 1 {
				if inp_end > 0 && int(n_consecutive) == rest {
					break
				}

				current_index := model.ids_by_character[input[inp + int(n_consecutive)]]
				if current_index < 0 { // '\0' is always -1
					break
				}

				successor_index := model.successors_by_bigram[last_chr_index * i16(model.character_count) + current_index]
				if successor_index < 0 {
					break
				}

				indices[n_consecutive] = i16(successor_index)
				last_chr_index = current_index
			}

			if n_consecutive < 2 {
				last_resort = true
				continue encode
			}

			pack_n := find_best_encoding(indices, n_consecutive)
			if pack_n >= 0 {
				if out + int(model.packs[pack_n].bytes_packed) > out_end {
					return out, .Output_Too_Short
				}

				pack := model.packs[pack_n]
				code := pack.word

				for i := 0; i < int(pack.bytes_unpacked); i += 1 {
					code |= u32(indices[i]) << pack.offsets[i]
				}

				// In the little-endian world, we need to swap what's in the register to match the memory representation.
				when ODIN_ENDIAN == .Little {
					code = intrinsics.byte_swap(code)
				}
				out_ptr := raw_data(output[out:])

				switch pack.bytes_packed {
				case 4: intrinsics.unaligned_store((^u32)(out_ptr), code)
				case 2: intrinsics.unaligned_store((^u16)(out_ptr), u16(code))
				case 1: intrinsics.unaligned_store( (^u8)(out_ptr),  u8(code))
				case:
					return out, .Unknown_Compression_Method
				}

				out += int(pack.bytes_packed)
				inp += int(pack.bytes_unpacked)
			} else {
				last_resort = true
				continue encode
			}
		}
	}
	return out, nil
}

compress_string :: proc(input: string, model := DEFAULT_MODEL, allocator := context.allocator) -> (output: []u8, err: compress.Error) {
	context.allocator = allocator

	if len(input) == 0 {
		return {}, .Stream_Too_Short
	}

	max_output_size := compress_bound(len(input))

	buf: [dynamic]u8
	resize(&buf, max_output_size) or_return

	length, result := compress_string_to_buffer(input, buf[:])
	resize(&buf, length) or_return
	return buf[:length], result
}
compress :: proc{compress_string_to_buffer, compress_string}