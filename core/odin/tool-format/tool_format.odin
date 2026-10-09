/*
The formats of the files `odin` exchanges with editors and other tools.

- `Overlay`:     read by `-overlay:<file>`, to check unsaved buffers in place of the files on disk
- `Semantics`:   written by `-export-semantics:<json|cbor>`, what each identifier refers to
- `Diagnostics`: written by `-json-errors`, the errors and warnings
*/
package odin_tool_format

import "core:encoding/cbor"
import "core:encoding/json"
import "core:slice"

// The same format as Go's `-overlay`.
// Each key is a path the compiler would read, and its value is the path to read instead, or "" to treat it as deleted.
// A key that does not exist on disk adds a file to its directory's package.
// Relative paths are relative to the working directory of `odin`.
Overlay :: struct {
	replace: map[string]string `json:"Replace"`,
}

marshal_overlay :: proc(overlay: Overlay, allocator := context.allocator) -> (data: []byte, err: json.Marshal_Error) {
	return json.marshal(overlay, {sort_maps_by_key = true}, allocator)
}


Semantics_Version :: 1

// `file`, `type` and `entity` fields are indices into `files`, `types` and `entities`, -1 when there is none.
// Offsets are in bytes.
Semantics :: struct {
	version:  int,
	files:    []string, // the exported files come first, in the same order as `exported`
	types:    []string,
	entities: []Entity,
	exported: []Exported_File,
}

Entity_Kind :: enum u8 {
	Invalid,
	Constant,
	Field,
	Parameter,
	Variable,
	Type,
	Procedure,
	Group,
	Builtin,
	Import,
	Library,
	Nil,
	Label,
	Asm,
}

Entity :: struct {
	name:   string,
	kind:   Entity_Kind,
	pkg:    string, // empty for local entities
	file:   int,
	offset: int,
	type:   int,
	value:  string, // constants only

	// concrete types only, `align` is 0 otherwise
	size:   int,
	align:  int,
	fields: []Field,
}

Field :: struct {
	name:   string,
	offset: int,
}

Exported_File :: struct {
	file:        int,
	uses:        []i32, // offset, entity, ... sorted by offset
	definitions: []i32, // offset, entity, ... sorted by offset
	inactive:    []i32, // from, to, ... the `when` branches never taken
}

// One `offset, entity` pair of `uses` or `definitions`
Ident :: struct {
	offset: i32,
	entity: i32,
}

// The pairs of `uses` or `definitions` for the identifier starting at `offset`.
// A call to a procedure group or a generic procedure also records the procedure it picks or instantiates.
find_idents :: proc(pairs: []i32, offset: int) -> []Ident {
	idents := slice.reinterpret([]Ident, pairs)
	i, _ := slice.binary_search_by(idents, offset, proc(x: Ident, offset: int) -> slice.Ordering {
		return slice.cmp(int(x.offset), offset)
	})
	j := i
	for j < len(idents) && int(idents[j].offset) == offset {
		j += 1
	}
	return idents[i:j]
}

Semantics_Error :: enum {
	None,
	Unsupported_Version,
}

Unmarshal_Error :: union #shared_nil {
	Semantics_Error,
	json.Unmarshal_Error,
	cbor.Unmarshal_Error,
}

// Decodes either format, as CBOR starts with a map header and JSON never does.
// Everything is allocated with `allocator`, so an arena suits it.
unmarshal_semantics :: proc(data: []byte, semantics: ^Semantics, allocator := context.allocator) -> Unmarshal_Error {
	if len(data) > 0 && data[0] >> 5 == 5 {
		cbor.unmarshal(data, semantics, allocator=allocator) or_return
	} else {
		json.unmarshal(data, semantics, allocator=allocator) or_return
	}
	if semantics.version != Semantics_Version {
		return .Unsupported_Version
	}
	return nil
}


Diagnostics :: struct {
	error_count: int,
	errors:      []Diagnostic,
}

Diagnostic :: struct {
	type: string,         // "error" or "warning"
	pos:  Diagnostic_Pos, // zero when there is no position
	msgs: []string,       // the message, one string per line
}

// Lines and columns start at 1, and columns count runes
Diagnostic_Pos :: struct {
	file:       string,
	offset:     int, // in bytes
	line:       int,
	column:     int,
	end_column: int, // just past the range, equal to `column` when it is empty
}
