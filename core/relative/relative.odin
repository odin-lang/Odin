package relative_types

import "base:intrinsics"

Pointer :: struct($Type: typeid, $Backing: typeid)
	where
		intrinsics.type_is_pointer(Type) || intrinsics.type_is_multi_pointer(Type),
		intrinsics.type_is_integer(Backing) {
	offset: Backing,
}

Slice :: struct($Type: typeid, $Backing: typeid)
	where
		intrinsics.type_is_slice(Type),
		intrinsics.type_is_integer(Backing) {
	offset: Backing,
	len:    Backing,
}



@(require_results)
pointer_get :: proc "contextless" (p: ^$P/Pointer($T, $B)) -> T {
	if p.offset == 0 {
		return nil
	}
	ptr := ([^]byte)(p)[p.offset:]
	return (T)(ptr)
}

pointer_set :: proc "contextless" (p: ^$P/Pointer($T, $B), ptr: T) {
	if ptr == nil {
		p.offset = 0
	} else {
		p.offset = B(int(uintptr(ptr)) - int(uintptr(p)))
	}
}

@(require_results)
slice_get :: proc "contextless" (p: ^$S/Slice($T/[]$E, $B)) -> (slice: T) {
	if p.offset == 0 {
		when size_of(E) == 0 {
			slice = T(([^]E)(nil)[:p.len])
		}
	} else {
		ptr := ([^]E)(([^]byte)(p)[p.offset:])
		slice = T(ptr[:p.len])
	}
	return
}

slice_set :: proc "contextless" (p: ^$S/Slice($T, $B), slice: T) {
	if slice == nil {
		p.offset, p.len = 0, 0
	} else {
		ptr := raw_data(slice)
		p.offset = B(int(uintptr(ptr)) - int(uintptr(p)))
		p.len    = B(len(slice))
	}
}

get :: proc{
	pointer_get,
	slice_get,
}

set :: proc{
	pointer_set,
	slice_set,
}



Set_Safe_Error :: enum {
	None,
	Memory_Too_Far_Apart,
	Length_Out_Of_Bounds,
}


@(require_results)
pointer_set_safe :: proc "contextless" (p: ^$P/Pointer($T, $B), ptr: T) -> Set_Safe_Error {
	if ptr == nil {
		p.offset = 0
	} else {
		when intrinsics.type_is_unsigned(B) {
			diff := uint(uintptr(ptr) - uintptr(p))
			when size_of(B) < size_of(uint) {
				if diff > uint(max(B)) {
					return .Memory_Too_Far_Apart
				}
			} else {
				if B(diff) > max(B) {
					return .Memory_Too_Far_Apart
				}
			}
		} else {
			diff := int(uintptr(ptr)) - int(uintptr(p))
			when size_of(B) < size_of(int) {
				if diff > int(max(B)) {
					return .Memory_Too_Far_Apart
				}
			} else {
				if B(diff) > max(B) {
					return .Memory_Too_Far_Apart
				}
			}
		}
		p.offset = B(diff)
	}
	return .None
}

@(require_results)
slice_set_safe :: proc "contextless" (p: ^$S/Slice($T, $B), slice: T) -> Set_Safe_Error {
	if slice == nil {
		p.offset, p.len = 0, 0
	} else {
		ptr := raw_data(slice)
		when intrinsics.type_is_unsigned(B) {
			diff := uint(uintptr(ptr) - uintptr(p))
			when size_of(B) < size_of(uint) {
				if diff > uint(max(B)) {
					return .Memory_Too_Far_Apart
				}

				if uint(len(slice)) > uint(max(B)) {
					return .Length_Out_Of_Bounds
				}
			} else {
				if B(diff) > max(B) {
					return .Memory_Too_Far_Apart
				}
				if B(len(slice)) > max(B) {
					return .Length_Out_Of_Bounds
				}
			}
			p.offset = B(diff)
			p.len = B(len(slice))
		} else {
			diff := int(uintptr(ptr)) - int(uintptr(p))
			when size_of(B) < size_of(int) {
				if diff > int(max(B)) {
					return .Memory_Too_Far_Apart
				}
				if len(slice) > int(max(B)) || len(slice) < int(min(B)) {
					return .Length_Out_Of_Bounds
				}
			} else {
				if B(diff) > max(B) {
					return .Memory_Too_Far_Apart
				}
				if B(len(slice)) > max(B) {
					return .Length_Out_Of_Bounds
				}
				if B(len(slice)) > max(B) || B(len(slice)) < min(B) {
					return .Length_Out_Of_Bounds
				}
			}
		}
		p.offset = B(diff)
		p.len = B(len(slice))
	}
	return .None
}


set_safe :: proc{
	pointer_set_safe,
	slice_set_safe,
}