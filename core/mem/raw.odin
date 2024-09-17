package mem

import "base:builtin"
import "base:runtime"

/*
Memory layout of the `any` type.
*/
Raw_Any :: runtime.Raw_Any

/*
Memory layout of the `string` type.
*/
Raw_String :: runtime.Raw_String

/*
Memory layout of the `cstring` type.
*/
Raw_Cstring :: runtime.Raw_Cstring

/*
Memory layout of `[]T` types.
*/
Raw_Slice :: runtime.Raw_Slice

/*
Memory layout of `[dynamic]T` types.
*/
Raw_Dynamic_Array :: runtime.Raw_Dynamic_Array

/*
Memory layout of `map[K]V` types.
*/
Raw_Map :: runtime.Raw_Map

/*
Memory layout of `#soa []T` types.
*/
Raw_Soa_Pointer :: runtime.Raw_Soa_Pointer

/*
Memory layout of the `complex32` type.
*/
Raw_Complex32 :: runtime.Raw_Complex32

/*
Memory layout of the `complex64` type.
*/
Raw_Complex64 :: runtime.Raw_Complex64

/*
Memory layout of the `complex128` type.
*/
Raw_Complex128 :: runtime.Raw_Complex128

/*
Memory layout of the `quaternion64` type.
*/
Raw_Quaternion64 :: runtime.Raw_Quaternion64

/*
Memory layout of the `quaternion128` type.
*/
Raw_Quaternion128 :: runtime.Raw_Quaternion128

/*
Memory layout of the `quaternion256` type.
*/
Raw_Quaternion256 :: runtime.Raw_Quaternion256

/*
Memory layout of the `quaternion64` type.
*/
Raw_Quaternion64_Vector_Scalar :: runtime.Raw_Quaternion64_Vector_Scalar

/*
Memory layout of the `quaternion128` type.
*/
Raw_Quaternion128_Vector_Scalar :: runtime.Raw_Quaternion128_Vector_Scalar

/*
Memory layout of the `quaternion256` type.
*/
Raw_Quaternion256_Vector_Scalar :: runtime.Raw_Quaternion256_Vector_Scalar

/*
Create a value of the any type.

This procedure creates a value with type `any` that points to an object with
typeid `id` located at an address specified by `data`.
*/
make_any :: proc "contextless" (data: rawptr, id: typeid) -> any {
	return transmute(any)Raw_Any{data, id}
}

/*
Obtain pointer to the data.

This procedure returns the pointer to the data of a slice, string, or a dynamic
array.
*/
raw_data :: builtin.raw_data
