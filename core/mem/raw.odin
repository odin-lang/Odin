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

Raw_Complex64     :: struct {real, imag: f32}
Raw_Complex128    :: struct {real, imag: f64}
Raw_Quaternion128 :: struct {imag, jmag, kmag: f32, real: f32}
Raw_Quaternion256 :: struct {imag, jmag, kmag: f64, real: f64}
Raw_Quaternion128_Vector_Scalar :: struct {vector: [3]f32, scalar: f32}
Raw_Quaternion256_Vector_Scalar :: struct {vector: [3]f64, scalar: f64}

make_any :: proc "contextless" (data: rawptr, id: typeid) -> any {
	return transmute(any)Raw_Any{data, id}
}

raw_data :: builtin.raw_data
