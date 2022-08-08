package mem

import "core:runtime"

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

raw_array_data         :: runtime.raw_array_data
raw_simd_data          :: runtime.raw_simd_data
raw_string_data        :: runtime.raw_string_data
raw_slice_data         :: runtime.raw_slice_data
raw_dynamic_array_data :: runtime.raw_dynamic_array_data
raw_data               :: runtime.raw_data


Poly_Raw_Map_Entry :: struct($Key, $Value: typeid) {
	hash:  uintptr,
	next:  int,
	key:   Key,
	value: Value,	
}

Poly_Raw_Map :: struct($Key, $Value: typeid) {
	hashes:  []int,
	entries: [dynamic]Poly_Raw_Map_Entry(Key, Value),
}