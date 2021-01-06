package slice

import "intrinsics"
import "core:runtime"
import "core:mem"

_ :: intrinsics;
_ :: runtime;
_ :: mem;

map_keys :: proc(m: $M/map[$K]$V, allocator := context.allocator) -> (keys: []K) {
	keys = make(type_of(keys), len(m), allocator);
	i := 0;
	for key in m {
		keys[i] = key;
		i += 1;
	}
	return;
}
map_values :: proc(m: $M/map[$K]$V, allocator := context.allocator) -> (values: []V) {
	values = make(type_of(values), len(m), allocator);
	i := 0;
	for _, value in m {
		values[i] = value;
		i += 1;
	}
	return;
}

Map_Entry :: struct(Key, Value: typeid) {
	key:   Key,
	value: Value,
}

Map_Entry_Info :: struct(Key, Value: typeid) {
	hash:  uintptr,
	key:   Key,
	value: Value,
}


map_entries :: proc(m: $M/map[$K]$V, allocator := context.allocator) -> (entries: []Map_Entry(K, V)) {
	entries = make(type_of(entries), len(m), allocator);
	i := 0;
	for key, value in m {
		entries[i].key   = key;
		entries[i].value = value;
		i += 1;
	}
	return;
}

map_entry_infos :: proc(m: $M/map[$K]$V, allocator := context.allocator) -> (entries: []Map_Entry_Info(K, V)) #no_bounds_check {
	m := m;
	rm := (^mem.Raw_Map)(&m);

	info := runtime.type_info_base(type_info_of(M)).variant.(runtime.Type_Info_Map);
	gs := runtime.type_info_base(info.generated_struct).variant.(runtime.Type_Info_Struct);
	ed := runtime.type_info_base(gs.types[1]).variant.(runtime.Type_Info_Dynamic_Array);
	entry_type := ed.elem.variant.(runtime.Type_Info_Struct);
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

	return;
}
