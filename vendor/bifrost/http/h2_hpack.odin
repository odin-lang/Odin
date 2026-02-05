package bifrost_http

import "base:runtime"

H2_Hpack_Field :: struct {
	Name: string,
	Value: string,
}

H2_HPACK_STATIC_LEN :: 61

H2_Hpack_Table :: struct {
	entries: [dynamic]H2_Hpack_Field,
	size: int,
	max_size: int,
}

H2_Hpack_Huffman_Node :: struct {
	children: ^[256]^H2_Hpack_Huffman_Node,
	code_len: u8,
	sym: u8,
}

h2_hpack_huffman_root: ^H2_Hpack_Huffman_Node
h2_hpack_huffman_ready: bool
h2_hpack_huffman_leaves: ^[256]H2_Hpack_Huffman_Node

H2_Hpack_Error :: enum {
	None,
	Buffer_Underflow,
	Invalid_Index,
	Invalid_Table_Size,
	Huffman_Unsupported,
	Invalid_Encoding,
}

H2_Hpack_Decoder :: struct {
	table: H2_Hpack_Table,
	max_header_list_size: int,
}

H2_Hpack_Encoder :: struct {
	table: H2_Hpack_Table,
}

H2_HPACK_ENTRY_OVERHEAD :: 32

h2_hpack_huffman_codes : [256]u32 = {
	0x1ff8,
	0x7fffd8,
	0xfffffe2,
	0xfffffe3,
	0xfffffe4,
	0xfffffe5,
	0xfffffe6,
	0xfffffe7,
	0xfffffe8,
	0xffffea,
	0x3ffffffc,
	0xfffffe9,
	0xfffffea,
	0x3ffffffd,
	0xfffffeb,
	0xfffffec,
	0xfffffed,
	0xfffffee,
	0xfffffef,
	0xffffff0,
	0xffffff1,
	0xffffff2,
	0x3ffffffe,
	0xffffff3,
	0xffffff4,
	0xffffff5,
	0xffffff6,
	0xffffff7,
	0xffffff8,
	0xffffff9,
	0xffffffa,
	0xffffffb,
	0x14,
	0x3f8,
	0x3f9,
	0xffa,
	0x1ff9,
	0x15,
	0xf8,
	0x7fa,
	0x3fa,
	0x3fb,
	0xf9,
	0x7fb,
	0xfa,
	0x16,
	0x17,
	0x18,
	0x0,
	0x1,
	0x2,
	0x19,
	0x1a,
	0x1b,
	0x1c,
	0x1d,
	0x1e,
	0x1f,
	0x5c,
	0xfb,
	0x7ffc,
	0x20,
	0xffb,
	0x3fc,
	0x1ffa,
	0x21,
	0x5d,
	0x5e,
	0x5f,
	0x60,
	0x61,
	0x62,
	0x63,
	0x64,
	0x65,
	0x66,
	0x67,
	0x68,
	0x69,
	0x6a,
	0x6b,
	0x6c,
	0x6d,
	0x6e,
	0x6f,
	0x70,
	0x71,
	0x72,
	0xfc,
	0x73,
	0xfd,
	0x1ffb,
	0x7fff0,
	0x1ffc,
	0x3ffc,
	0x22,
	0x7ffd,
	0x3,
	0x23,
	0x4,
	0x24,
	0x5,
	0x25,
	0x26,
	0x27,
	0x6,
	0x74,
	0x75,
	0x28,
	0x29,
	0x2a,
	0x7,
	0x2b,
	0x76,
	0x2c,
	0x8,
	0x9,
	0x2d,
	0x77,
	0x78,
	0x79,
	0x7a,
	0x7b,
	0x7ffe,
	0x7fc,
	0x3ffd,
	0x1ffd,
	0xffffffc,
	0xfffe6,
	0x3fffd2,
	0xfffe7,
	0xfffe8,
	0x3fffd3,
	0x3fffd4,
	0x3fffd5,
	0x7fffd9,
	0x3fffd6,
	0x7fffda,
	0x7fffdb,
	0x7fffdc,
	0x7fffdd,
	0x7fffde,
	0xffffeb,
	0x7fffdf,
	0xffffec,
	0xffffed,
	0x3fffd7,
	0x7fffe0,
	0xffffee,
	0x7fffe1,
	0x7fffe2,
	0x7fffe3,
	0x7fffe4,
	0x1fffdc,
	0x3fffd8,
	0x7fffe5,
	0x3fffd9,
	0x7fffe6,
	0x7fffe7,
	0xffffef,
	0x3fffda,
	0x1fffdd,
	0xfffe9,
	0x3fffdb,
	0x3fffdc,
	0x7fffe8,
	0x7fffe9,
	0x1fffde,
	0x7fffea,
	0x3fffdd,
	0x3fffde,
	0xfffff0,
	0x1fffdf,
	0x3fffdf,
	0x7fffeb,
	0x7fffec,
	0x1fffe0,
	0x1fffe1,
	0x3fffe0,
	0x1fffe2,
	0x7fffed,
	0x3fffe1,
	0x7fffee,
	0x7fffef,
	0xfffea,
	0x3fffe2,
	0x3fffe3,
	0x3fffe4,
	0x7ffff0,
	0x3fffe5,
	0x3fffe6,
	0x7ffff1,
	0x3ffffe0,
	0x3ffffe1,
	0xfffeb,
	0x7fff1,
	0x3fffe7,
	0x7ffff2,
	0x3fffe8,
	0x1ffffec,
	0x3ffffe2,
	0x3ffffe3,
	0x3ffffe4,
	0x7ffffde,
	0x7ffffdf,
	0x3ffffe5,
	0xfffff1,
	0x1ffffed,
	0x7fff2,
	0x1fffe3,
	0x3ffffe6,
	0x7ffffe0,
	0x7ffffe1,
	0x3ffffe7,
	0x7ffffe2,
	0xfffff2,
	0x1fffe4,
	0x1fffe5,
	0x3ffffe8,
	0x3ffffe9,
	0xffffffd,
	0x7ffffe3,
	0x7ffffe4,
	0x7ffffe5,
	0xfffec,
	0xfffff3,
	0xfffed,
	0x1fffe6,
	0x3fffe9,
	0x1fffe7,
	0x1fffe8,
	0x7ffff3,
	0x3fffea,
	0x3fffeb,
	0x1ffffee,
	0x1ffffef,
	0xfffff4,
	0xfffff5,
	0x3ffffea,
	0x7ffff4,
	0x3ffffeb,
	0x7ffffe6,
	0x3ffffec,
	0x3ffffed,
	0x7ffffe7,
	0x7ffffe8,
	0x7ffffe9,
	0x7ffffea,
	0x7ffffeb,
	0xffffffe,
	0x7ffffec,
	0x7ffffed,
	0x7ffffee,
	0x7ffffef,
	0x7fffff0,
	0x3ffffee,
}

h2_hpack_huffman_code_len : [256]u8 = {
	13, 23, 28, 28, 28, 28, 28, 28, 28, 24, 30, 28, 28, 30, 28, 28,
	28, 28, 28, 28, 28, 28, 30, 28, 28, 28, 28, 28, 28, 28, 28, 28,
	6, 10, 10, 12, 13, 6, 8, 11, 10, 10, 8, 11, 8, 6, 6, 6,
	5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 7, 8, 15, 6, 12, 10,
	13, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7,
	7, 7, 7, 7, 7, 7, 7, 7, 8, 7, 8, 13, 19, 13, 14, 6,
	15, 5, 6, 5, 6, 5, 6, 6, 6, 5, 7, 7, 6, 6, 6, 5,
	6, 7, 6, 5, 5, 6, 7, 7, 7, 7, 7, 15, 11, 14, 13, 28,
	20, 22, 20, 20, 22, 22, 22, 23, 22, 23, 23, 23, 23, 23, 24, 23,
	24, 24, 22, 23, 24, 23, 23, 23, 23, 21, 22, 23, 22, 23, 23, 24,
	22, 21, 20, 22, 22, 23, 23, 21, 23, 22, 22, 24, 21, 22, 23, 23,
	21, 21, 22, 21, 23, 22, 23, 23, 20, 22, 22, 22, 23, 22, 22, 23,
	26, 26, 20, 19, 22, 23, 22, 25, 26, 26, 26, 27, 27, 26, 24, 25,
	19, 21, 26, 27, 27, 26, 27, 24, 21, 21, 26, 26, 28, 27, 27, 27,
	20, 24, 20, 21, 22, 21, 21, 23, 22, 22, 25, 25, 24, 24, 26, 23,
	26, 27, 26, 26, 27, 27, 27, 27, 27, 28, 27, 27, 27, 27, 27, 26,
}

h2_hpack_static_table : [H2_HPACK_STATIC_LEN]H2_Hpack_Field = {
	{":authority", ""},
	{":method", "GET"},
	{":method", "POST"},
	{":path", "/"},
	{":path", "/index.html"},
	{":scheme", "http"},
	{":scheme", "https"},
	{":status", "200"},
	{":status", "204"},
	{":status", "206"},
	{":status", "304"},
	{":status", "400"},
	{":status", "404"},
	{":status", "500"},
	{"accept-charset", ""},
	{"accept-encoding", "gzip, deflate"},
	{"accept-language", ""},
	{"accept-ranges", ""},
	{"accept", ""},
	{"access-control-allow-origin", ""},
	{"age", ""},
	{"allow", ""},
	{"authorization", ""},
	{"cache-control", ""},
	{"content-disposition", ""},
	{"content-encoding", ""},
	{"content-language", ""},
	{"content-length", ""},
	{"content-location", ""},
	{"content-range", ""},
	{"content-type", ""},
	{"cookie", ""},
	{"date", ""},
	{"etag", ""},
	{"expect", ""},
	{"expires", ""},
	{"from", ""},
	{"host", ""},
	{"if-match", ""},
	{"if-modified-since", ""},
	{"if-none-match", ""},
	{"if-range", ""},
	{"if-unmodified-since", ""},
	{"last-modified", ""},
	{"link", ""},
	{"location", ""},
	{"max-forwards", ""},
	{"proxy-authenticate", ""},
	{"proxy-authorization", ""},
	{"range", ""},
	{"referer", ""},
	{"refresh", ""},
	{"retry-after", ""},
	{"server", ""},
	{"set-cookie", ""},
	{"strict-transport-security", ""},
	{"transfer-encoding", ""},
	{"user-agent", ""},
	{"vary", ""},
	{"via", ""},
	{"www-authenticate", ""},
}

h2_hpack_new_internal_node :: proc() -> ^H2_Hpack_Huffman_Node {
	node := new(H2_Hpack_Huffman_Node)
	node.children = new([256]^H2_Hpack_Huffman_Node)
	return node
}

h2_hpack_build_huffman_tree :: proc() {
	if h2_hpack_huffman_ready {
		return
	}
	if len(h2_hpack_huffman_codes) != 256 || len(h2_hpack_huffman_code_len) != 256 {
		return
	}

	root := h2_hpack_new_internal_node()
	leaves := new([256]H2_Hpack_Huffman_Node)

	for sym := 0; sym < 256; sym += 1 {
		code := h2_hpack_huffman_codes[sym]
		code_len := int(h2_hpack_huffman_code_len[sym])
		cur := root

		for code_len > 8 {
			code_len -= 8
			idx := u8(code >> u32(code_len))
			if cur.children[idx] == nil {
				cur.children[idx] = h2_hpack_new_internal_node()
			}
			cur = cur.children[idx]
		}

		shift := 8 - code_len
		start := int(u8(code << u32(shift)))
		end := int(1 << u32(shift))

		leaves[sym].sym = u8(sym)
		leaves[sym].code_len = u8(code_len)
		for i := start; i < start+end; i += 1 {
			cur.children[i] = &leaves[sym]
		}
	}

	h2_hpack_huffman_root = root
	h2_hpack_huffman_leaves = leaves
	h2_hpack_huffman_ready = true
}

h2_hpack_get_huffman_root :: proc() -> ^H2_Hpack_Huffman_Node {
	if !h2_hpack_huffman_ready {
		h2_hpack_build_huffman_tree()
	}
	return h2_hpack_huffman_root
}

h2_hpack_huffman_decode :: proc(buf: []u8) -> (value: string, err: H2_Hpack_Error) {
	root := h2_hpack_get_huffman_root()
	if root == nil {
		return "", .Invalid_Encoding
	}

	out := make([dynamic]u8, 0, len(buf))
	node := root
	cur: u64 = 0
	cbits: u8 = 0
	sbits: u8 = 0

	for _, b in buf {
		cur = (cur << 8) | u64(b)
		cbits += 8
		sbits += 8
		for cbits >= 8 {
			idx := u8(cur >> u64(cbits-8))
			node = node.children[idx]
			if node == nil {
				delete(out)
				return "", .Invalid_Encoding
			}
			if node.children == nil {
				append(&out, node.sym)
				cbits -= node.code_len
				node = root
				sbits = cbits
			} else {
				cbits -= 8
			}
		}
	}

	for cbits > 0 {
		idx := u8(cur << u64(8-cbits))
		node = node.children[idx]
		if node == nil {
			delete(out)
			return "", .Invalid_Encoding
		}
		if node.children != nil || node.code_len > cbits {
			break
		}
		append(&out, node.sym)
		cbits -= node.code_len
		node = root
		sbits = cbits
	}

	if sbits > 7 {
		delete(out)
		return "", .Invalid_Encoding
	}
	if cbits > 0 {
		mask := (u64(1) << u64(cbits)) - 1
		if (cur & mask) != mask {
			delete(out)
			return "", .Invalid_Encoding
		}
	}

	str := header_clone_string(string(out[:]))
	delete(out)
	return str, .None
}

h2_hpack_table_init :: proc(t: ^H2_Hpack_Table, max_size: int = 4096) {
	if t == nil {
		return
	}
	t.entries = make([dynamic]H2_Hpack_Field, 0)
	t.size = 0
	t.max_size = max_size
}

h2_hpack_table_free :: proc(t: ^H2_Hpack_Table) {
	if t == nil {
		return
	}
	for i := 0; i < len(t.entries); i += 1 {
		header_free_string(t.entries[i].Name)
		header_free_string(t.entries[i].Value)
	}
	delete(t.entries)
	t.size = 0
	t.max_size = 0
}

h2_hpack_table_evict :: proc(t: ^H2_Hpack_Table, count: int = 1) {
	if t == nil || count <= 0 {
		return
	}
	remaining := count
	for remaining > 0 && len(t.entries) > 0 {
		last := len(t.entries) - 1
		entry := t.entries[last]
		t.size -= H2_HPACK_ENTRY_OVERHEAD + len(entry.Name) + len(entry.Value)
		header_free_string(entry.Name)
		header_free_string(entry.Value)
		(^runtime.Raw_Dynamic_Array)(&t.entries).len = last
		remaining -= 1
	}
}

h2_hpack_table_set_max_size :: proc(t: ^H2_Hpack_Table, max_size: int) -> bool {
	if t == nil || max_size < 0 {
		return false
	}
	t.max_size = max_size
	for t.size > t.max_size && len(t.entries) > 0 {
		h2_hpack_table_evict(t, 1)
	}
	return true
}

h2_hpack_table_add :: proc(t: ^H2_Hpack_Table, name: string, value: string) {
	if t == nil {
		return
	}
	entry_size := H2_HPACK_ENTRY_OVERHEAD + len(name) + len(value)
	if entry_size > t.max_size {
		h2_hpack_table_evict(t, len(t.entries))
		return
	}
	for t.size+entry_size > t.max_size && len(t.entries) > 0 {
		h2_hpack_table_evict(t, 1)
	}
	new_entry := H2_Hpack_Field{
		Name = header_clone_string(name),
		Value = header_clone_string(value),
	}
	append(&t.entries, H2_Hpack_Field{})
	for i := len(t.entries) - 1; i > 0; i -= 1 {
		t.entries[i] = t.entries[i-1]
	}
	t.entries[0] = new_entry
	t.size += entry_size
}

h2_hpack_table_get :: proc(t: ^H2_Hpack_Table, index: int) -> (field: H2_Hpack_Field, ok: bool) {
	if index <= 0 {
		return field, false
	}
	if index <= H2_HPACK_STATIC_LEN {
		return h2_hpack_static_table[index-1], true
	}
	dyn_index := index - H2_HPACK_STATIC_LEN
	if t == nil || dyn_index <= 0 || dyn_index > len(t.entries) {
		return field, false
	}
	return t.entries[dyn_index-1], true
}

h2_hpack_decoder_init :: proc(dec: ^H2_Hpack_Decoder, table_size: int = 4096, max_header_list_size: int = 0) {
	if dec == nil {
		return
	}
	h2_hpack_table_init(&dec.table, table_size)
	dec.max_header_list_size = max_header_list_size
}

h2_hpack_decoder_free :: proc(dec: ^H2_Hpack_Decoder) {
	if dec == nil {
		return
	}
	h2_hpack_table_free(&dec.table)
	dec.max_header_list_size = 0
}

h2_hpack_encoder_init :: proc(enc: ^H2_Hpack_Encoder, table_size: int = 4096) {
	if enc == nil {
		return
	}
	h2_hpack_table_init(&enc.table, table_size)
}

h2_hpack_encoder_free :: proc(enc: ^H2_Hpack_Encoder) {
	if enc == nil {
		return
	}
	h2_hpack_table_free(&enc.table)
}

h2_hpack_fields_free :: proc(fields: []H2_Hpack_Field) {
	for f in fields {
		header_free_string(f.Name)
		header_free_string(f.Value)
	}
}

h2_hpack_decode_int :: proc(buf: []u8, prefix_bits: int) -> (value: int, consumed: int, ok: bool) {
	if len(buf) == 0 || prefix_bits <= 0 || prefix_bits > 8 {
		return 0, 0, false
	}
	mask := (1 << u32(prefix_bits)) - 1
	value = int(buf[0] & u8(mask))
	if value < mask {
		return value, 1, true
	}

	shift: u32 = 0
	consumed = 1
	for {
		if consumed >= len(buf) {
			return 0, 0, false
		}
		b := buf[consumed]
		consumed += 1
		value += int(b & 0x7f) << shift
		if (b & 0x80) == 0 {
			break
		}
		shift += 7
		if shift > 28 {
			return 0, 0, false
		}
	}
	return value, consumed, true
}

h2_hpack_encode_int :: proc(out: ^[dynamic]u8, prefix_bits: int, value: int, prefix: u8) -> bool {
	if out == nil || prefix_bits <= 0 || prefix_bits > 8 || value < 0 {
		return false
	}
	max := (1 << u32(prefix_bits)) - 1
	v := value
	if v < max {
		append(out, prefix | u8(v))
		return true
	}

	append(out, prefix | u8(max))
	v -= max
	for v >= 128 {
		append(out, u8(v & 0x7f) | 0x80)
		v >>= 7
	}
	append(out, u8(v))
	return true
}

h2_hpack_decode_string :: proc(buf: []u8) -> (value: string, consumed: int, err: H2_Hpack_Error) {
	if len(buf) == 0 {
		return "", 0, .Buffer_Underflow
	}

	huffman := (buf[0] & 0x80) != 0
	length, n, ok := h2_hpack_decode_int(buf, 7)
	if !ok {
		return "", 0, .Invalid_Encoding
	}
	if length < 0 || n+length > len(buf) {
		return "", 0, .Buffer_Underflow
	}
	if huffman {
		decoded, derr := h2_hpack_huffman_decode(buf[n : n+length])
		if derr != .None {
			return "", 0, derr
		}
		return decoded, n + length, .None
	}

	raw := buf[n : n+length]
	return header_clone_string(string(raw)), n + length, .None
}

h2_hpack_encode_string :: proc(out: ^[dynamic]u8, value: string) -> bool {
	if out == nil {
		return false
	}
	if !h2_hpack_encode_int(out, 7, len(value), 0) {
		return false
	}
	append(out, ..transmute([]u8)string(value))
	return true
}

h2_hpack_decode :: proc(dec: ^H2_Hpack_Decoder, buf: []u8) -> (fields: [dynamic]H2_Hpack_Field, err: H2_Hpack_Error) {
	if dec == nil {
		return fields, .Invalid_Encoding
	}
	fields = make([dynamic]H2_Hpack_Field, 0)

	pos := 0
	for pos < len(buf) {
		b := buf[pos]

		if (b & 0x80) != 0 {
			index, n, ok := h2_hpack_decode_int(buf[pos:], 7)
			if !ok {
				h2_hpack_fields_free(fields[:])
				return nil, .Invalid_Encoding
			}
			field, ok2 := h2_hpack_table_get(&dec.table, index)
			if !ok2 {
				h2_hpack_fields_free(fields[:])
				return nil, .Invalid_Index
			}
			append(&fields, H2_Hpack_Field{
				Name = header_clone_string(field.Name),
				Value = header_clone_string(field.Value),
			})
			pos += n
			continue
		}

		if (b & 0x40) != 0 {
			index, n, ok := h2_hpack_decode_int(buf[pos:], 6)
			if !ok {
				h2_hpack_fields_free(fields[:])
				return nil, .Invalid_Encoding
			}
			pos += n
			name := ""
			name_owned := false
			if index > 0 {
				field, ok2 := h2_hpack_table_get(&dec.table, index)
				if !ok2 {
					h2_hpack_fields_free(fields[:])
					return nil, .Invalid_Index
				}
				name = field.Name
			} else {
				str, used, serr := h2_hpack_decode_string(buf[pos:])
				if serr != .None {
					h2_hpack_fields_free(fields[:])
					return nil, serr
				}
				pos += used
				name = str
				name_owned = true
			}
			value, used, verr := h2_hpack_decode_string(buf[pos:])
			if verr != .None {
				if name_owned {
					header_free_string(name)
				}
				h2_hpack_fields_free(fields[:])
				return nil, verr
			}
			pos += used

			field_name := name
			if !name_owned {
				field_name = header_clone_string(name)
			}
			append(&fields, H2_Hpack_Field{
				Name = field_name,
				Value = value,
			})
			h2_hpack_table_add(&dec.table, name, value)
			continue
		}

		if (b & 0x20) != 0 {
			size, n, ok := h2_hpack_decode_int(buf[pos:], 5)
			if !ok {
				h2_hpack_fields_free(fields[:])
				return nil, .Invalid_Encoding
			}
			if !h2_hpack_table_set_max_size(&dec.table, size) {
				h2_hpack_fields_free(fields[:])
				return nil, .Invalid_Table_Size
			}
			pos += n
			continue
		}

		index, n, ok := h2_hpack_decode_int(buf[pos:], 4)
		if !ok {
			h2_hpack_fields_free(fields[:])
			return nil, .Invalid_Encoding
		}
		pos += n

		name := ""
		name_owned := false
		if index > 0 {
			field, ok2 := h2_hpack_table_get(&dec.table, index)
			if !ok2 {
				h2_hpack_fields_free(fields[:])
				return nil, .Invalid_Index
			}
			name = field.Name
		} else {
			str, used, serr := h2_hpack_decode_string(buf[pos:])
			if serr != .None {
				h2_hpack_fields_free(fields[:])
				return nil, serr
			}
			pos += used
			name = str
			name_owned = true
		}

		value, used, verr := h2_hpack_decode_string(buf[pos:])
		if verr != .None {
			if name_owned {
				header_free_string(name)
			}
			h2_hpack_fields_free(fields[:])
			return nil, verr
		}
		pos += used

		field_name := name
		if !name_owned {
			field_name = header_clone_string(name)
		}
		append(&fields, H2_Hpack_Field{
			Name = field_name,
			Value = value,
		})
	}

	return fields, .None
}

h2_hpack_encode_literal :: proc(headers: []H2_Hpack_Field) -> []u8 {
	out := make([dynamic]u8, 0, 128)
	for h in headers {
		_ = h2_hpack_encode_int(&out, 4, 0, 0x0)
		_ = h2_hpack_encode_string(&out, h.Name)
		_ = h2_hpack_encode_string(&out, h.Value)
	}
	return out[:]
}
