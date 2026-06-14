package rexcode_isa

// =============================================================================
// LABEL INFERENCE (decoder helper, architecture-independent)
// =============================================================================
//
// Pass 2 of decode: turn the list of branch targets discovered during
// instruction decoding into label definitions, reusing label IDs from a
// caller-supplied relocations array when available (so symbolic names
// from the encoder survive the round trip).

// Branch target discovered while decoding. Each branch operand a
// per-arch decoder produces (RELATIVE-kind operand with a known target
// offset) becomes one of these for pass 2.
Branch_Target :: struct {
	inst_idx: u32,   // which decoded instruction has the branch
	op_idx:   u8,    // which operand of that instruction is the target
	target:   u32,   // absolute byte offset of the branch target
}

// Resolve branch targets into label definitions.
//
// For each branch target inside the decoded region (target < decoded_end):
//   - if a label is already defined at that offset, do nothing;
//   - else if `relocs` provides a label_id for that offset (named label
//     carried over from the encode side), use that ID;
//   - else create a fresh label ID and append it.
//
// label_defs may grow.
//
// Parametric over the caller's relocation type `$R`: the body only reads
// `.offset` and `.label_id`, so any per-arch `Relocation` struct with
// those fields works. Monomorphizes at the call site with no overhead.
infer_labels_from_branches :: proc(
	branches:    []Branch_Target,
	decoded_end: u32,
	label_defs:  ^[dynamic]Label_Definition,
	relocs:      []$R,
) {
	offset_to_label: map[u32]u32
	defer delete(offset_to_label)
	for id in 0..<u32(len(label_defs)) {
		if label_defs[id] != LABEL_UNDEFINED {
			offset_to_label[u32(label_defs[id])] = id
		}
	}

	relocation_offset_to_label: map[u32]u32
	defer delete(relocation_offset_to_label)
	for relocation in relocs {
		relocation_offset_to_label[relocation.offset] = relocation.label_id
	}

	for branch in branches {
		if branch.target >= decoded_end {
			continue
		}
		if branch.target in offset_to_label {
			continue
		}
		if reloc_id, ok := relocation_offset_to_label[branch.target]; ok {
			for u32(len(label_defs)) <= reloc_id {
				append(label_defs, LABEL_UNDEFINED)
			}
			label_defs[reloc_id] = Label_Definition(branch.target)
			offset_to_label[branch.target] = reloc_id
		} else {
			new_id := u32(len(label_defs))
			append(label_defs, Label_Definition(branch.target))
			offset_to_label[branch.target] = new_id
		}
	}
}
