package reflect

import "core:runtime"
import "core:mem"
_ :: runtime;
_ :: mem;

Map_Entry_Info :: struct(Key, Value: typeid) {
	hash:  uintptr,
	key:   Key,
	value: Value,
}

map_entry_info_slice :: proc(m: $M/map[$K]$V, allocator := context.allocator) -> (entries: []Map_Entry_Info(K, V)) #no_bounds_check {
	m := m;
	rm := (^mem.Raw_Map)(&m);

	info := type_info_base(type_info_of(M)).variant.(Type_Info_Map);
	gs := type_info_base(info.generated_struct).variant.(Type_Info_Struct);
	ed := type_info_base(gs.types[1]).variant.(Type_Info_Dynamic_Array);
	entry_type := ed.elem.variant.(Type_Info_Struct);
	key_offset :=  entry_type.offsets[2];
	value_offset :=  entry_type.offsets[3];
	entry_size := uintptr(ed.elem_size);

	entries = make(type_of(entries), rm.entries.len);

	data := uintptr(rm.entries.data);
	for i in 0..<rm.entries.len {
		header := (^runtime.Map_Entry_Header)(data);

		hash  := header.hash;
		key   := (^K)(data + key_offset)^;
		value := (^V)(data + value_offset)^;

		entries[i] = {hash, key, value};

		data += entry_size;
	}

	return entries;
}
