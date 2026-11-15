package test_issue_poly_record_unspecialized_field

import "base:intrinsics"

Handle :: struct($T: typeid) {
	id: u32,
}

Slot :: struct {
	handle: Handle,
}

Slot_Pointer :: struct {
	handle: ^Handle,
}

Slot_Slice :: struct {
	handles: []Handle,
}

Slot_Union :: union {
	^Handle,
	int,
}

Map :: struct($T: typeid) {
	items: [dynamic]T,
}

Checked_Map :: struct($T: typeid) where intrinsics.type_field_type(T, "handle") == u32 {
	items: [dynamic]T,
}

Store :: struct {
	slots:    Map(Slot),
	pointers: Map(Slot_Pointer),
	slices:   Map(Slot_Slice),
	unions:   Map(Slot_Union),
	checked:  Checked_Map(Slot),
}

accepts_anonymous :: proc(s: struct { handle: ^Handle }) {
	_ = s
}

main :: proc() {}
