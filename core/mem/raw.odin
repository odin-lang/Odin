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

Raw_Complex32     :: runtime.Raw_Complex32
Raw_Complex64     :: runtime.Raw_Complex64
Raw_Complex128    :: runtime.Raw_Complex128
Raw_Quaternion64  :: runtime.Raw_Quaternion64
Raw_Quaternion128 :: runtime.Raw_Quaternion128
Raw_Quaternion256 :: runtime.Raw_Quaternion256
Raw_Quaternion64_Vector_Scalar  :: runtime.Raw_Quaternion64_Vector_Scalar
Raw_Quaternion128_Vector_Scalar :: runtime.Raw_Quaternion128_Vector_Scalar
Raw_Quaternion256_Vector_Scalar :: runtime.Raw_Quaternion256_Vector_Scalar

make_any :: proc "contextless" (data: rawptr, id: typeid) -> any {
	return transmute(any)Raw_Any{data, id}
}

raw_data :: builtin.raw_data
