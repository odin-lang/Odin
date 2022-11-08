package reflect

import "core:runtime"
_ :: runtime

Map_Entry_Info :: struct($Key, $Value: typeid) {
	hash:  uintptr,
	key:   Key,
	value: Value,
}

map_entry_info_slice :: proc(m: $M/map[$K]$V, allocator := context.allocator) -> (entries: []Map_Entry_Info(K, V), err: runtime.Allocator_Error) #no_bounds_check {
	m := m
	rm := (^runtime.Raw_Map)(&m)

	info := type_info_base(type_info_of(M)).variant.(Type_Info_Map)
	if info.map_info != nil {
		entries = make(type_of(entries), len(m), allocator) or_return

		map_cap := uintptr(cap(m))
		ks, vs, hs, _, _ := runtime.map_kvh_data_dynamic(rm^, info.map_info)
		entry_index := 0
		for bucket_index in 0..<map_cap {
			if hash := hs[bucket_index]; runtime.map_hash_is_valid(hash) {
				key   := runtime.map_cell_index_dynamic(ks, &info.map_info.ks, bucket_index)
				value := runtime.map_cell_index_dynamic(vs, &info.map_info.vs, bucket_index)
				entries[entry_index].hash  = hash
				entries[entry_index].key   = (^K)(key)^
				entries[entry_index].value = (^V)(value)^

				entry_index += 1
			}
		}
	}
	return
}
