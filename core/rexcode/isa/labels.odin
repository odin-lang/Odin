// rexcode  ·  Brendan Punsky (dotbmp@github), original author

package rexcode_isa

// =============================================================================
// LABELS (architecture-independent bookkeeping)
// =============================================================================
//
// The *array-index* label model lives here -- it's genuinely universal:
// every arch's `encode()` consumes a `[]Label_Definition` and `decode()`
// populates one identically. The procedures are parametric over the
// Instruction type (`$T`), so each arch calls them as `isa.label(...)`
// without per-arch re-exports.

// -----------------------------------------------------------------------------
// Array-index model (used by every arch's encode/decode hot path)
// -----------------------------------------------------------------------------
//
// Label_Definition maps a label ID to:
//   - the instruction index where it's defined (input to encode), then
//   - the byte offset of that instruction (rewritten in place by encode).
Label_Definition :: distinct u32

LABEL_UNDEFINED :: Label_Definition(0xFFFFFFFF)

// Define a label at the current instruction position. Parametric on $T so
// any arch's Instruction type works.
@(require_results)
label :: #force_inline proc(labels: ^[dynamic]Label_Definition, instructions: ^[dynamic]$T) -> u32 {
	id := u32(len(labels))
	append(labels, Label_Definition(len(instructions)))
	return id
}

// Reserve a label slot for forward references.
@(require_results)
label_forward :: #force_inline proc(labels: ^[dynamic]Label_Definition) -> u32 {
	id := u32(len(labels))
	append(labels, LABEL_UNDEFINED)
	return id
}

// Define a previously reserved (anonymous) label's position. Pairs with
// `label_forward` to support `1: ... jlt <1` / `... jlt 1> ... 1:` style
// forward and backward local labels:
//
//   fwd := label_forward(&labels)
//   ... encode body that references fwd ...
//   label_set_at(&labels, fwd, &instructions)
label_set_at :: #force_inline proc(labels: ^[dynamic]Label_Definition, id: u32, instructions: ^[dynamic]$T) {
	labels[id] = Label_Definition(len(instructions))
}

// Label_Map: named labels.
Label_Map :: struct {
	labels: [dynamic]Label_Definition,
	names:  map[string]u32,
}

label_map_init :: #force_inline proc(lm: ^Label_Map, allocator := context.allocator) {
	lm.labels = make([dynamic]Label_Definition, allocator)
	lm.names  = make(map[string]u32, allocator = allocator)
}

label_map_destroy :: #force_inline proc(lm: ^Label_Map) {
	delete(lm.labels)
	delete(lm.names)
}

// Define a named label at the current instruction position.
@(require_results)
label_named :: #force_inline proc(lm: ^Label_Map, name: string, instructions: ^[dynamic]$T) -> u32 {
	id := u32(len(lm.labels))
	append(&lm.labels, Label_Definition(len(instructions)))
	lm.names[name] = id
	return id
}

// Reserve a named label for forward reference.
@(require_results)
label_reserve :: #force_inline proc(lm: ^Label_Map, name: string) -> u32 {
	id := u32(len(lm.labels))
	append(&lm.labels, LABEL_UNDEFINED)
	lm.names[name] = id
	return id
}

// Define a previously reserved named label's position.
label_set :: #force_inline proc(lm: ^Label_Map, name: string, instructions: ^[dynamic]$T) {
	lm.labels[lm.names[name]] = Label_Definition(len(instructions))
}

// -----------------------------------------------------------------------------
// Encoder helper: rewrite label_defs from instruction indices to byte
// offsets in place. Called between pass 1 (encoding) and pass 2
// (relocation resolution). Pure bookkeeping, arch-independent.
// -----------------------------------------------------------------------------

rewrite_label_defs_to_offsets :: #force_inline proc(label_defs: []Label_Definition, inst_offsets: []u32) {
	for &label in label_defs {
		if label != LABEL_UNDEFINED {
			inst_idx := u32(label)
			if inst_idx < u32(len(inst_offsets)) {
				label = Label_Definition(inst_offsets[inst_idx])
			} else {
				label = LABEL_UNDEFINED
			}
		}
	}
}
