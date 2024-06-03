package mem

import "base:builtin"
import "base:runtime"

Raw_Any           :: runtime.Raw_Any
Raw_String        :: runtime.Raw_String
Raw_Cstring       :: runtime.Raw_Cstring
Raw_Slice         :: runtime.Raw_Slice
Raw_Dynamic_Array :: runtime.Raw_Dynamic_Array
Raw_Map           :: runtime.Raw_Map
Raw_Soa_Pointer   :: runtime.Raw_Soa_Pointer

make_any :: proc "contextless" (data: rawptr, id: typeid) -> any {
	return transmute(any)Raw_Any{data, id}
}

raw_data :: builtin.raw_data
