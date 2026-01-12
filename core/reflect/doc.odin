// Utility procedures and types to perform runtime type introspection/reflection (`RTTI`).
//
// WARNING! THIS IS ADVANCED BEHAVIOUR FOR ODIN! THIS SHOULD NOT BE USED BY BEGINNERS TO ODIN!
//
// This package is only to be used by individuals who know exactly how the RTTI works as well as EXACTLY how `any` works.
// Especially since `any` can be unintuitive in its use to many, it can be dangerous to use. It is highly recommend that you **do not**
// use `any` unless you know exactly what you are doing.
//
// RTTI is an extremely powerful tool which should only be used when absolutely necessary (such runtime-type-safe formatted printing).
//
// ## The Type System of Odin
//
// It is important to understand how the type systems works in Odin before using any RTTI. A good example of this is Odin's `distinct` type system.
// In Odin, `distinct` types are represented by `Type_Info_Named`. A named struct is a `Type_Info_Named` which then points to a `Type_Info_Struct`.
// This means you must use something like `type_info_base` to restrict the `Type_Info_Named` aspect and get the base-type directly. Doing a type-assertion
// on the variant will not work as (incorrectly) expected without doing this.
//
// ## Advanced Information of How `any` Works
//
// An overview of how `any` works:
//
// An `any` type can reference any data type. It is functionally equivalent to `struct {data: rawptr, id: typeid}` with extra semantics on
// how assignment and type assertion works.
//
// This is commonly used to construct runtime-type-safe printing, such as in `core:fmt`.
// The use of `any` outside of this is heavily discourage and should be only used by people who FULLY understand its semantics.
//
// The `any` value is only valid as long as the underlying data is still valid. Passing a literal to an `any` will allocate the literal in
// the current stack frame.
//
// Example:
// 	x: int = 123
// 	a: any = x
// 	// equivalent to
// 	a: any
// 	a.data = &x
// 	a.id   = typeid_of(type_of(x))
// 	// With literals
// 	v: any = 123
// 	// equivalent to
// 	v: any
// 	_tmp: int = 123
// 	v.data = &_tmp
// 	v.id   = typeid_of(type_of(_tmp))
//
//
// `any` is a topologically-dual to a `union` in terms of its usage. Both support assignments of differing types
// (`any` being open to any type, `union` being closed to a specific set of types), type assertions (`x.(T)`), and `switch in`.
// The main internal difference is how the memory is stored. `any` being open is a pointer+typeid, a `union`
// is a blob+tag. A `union` does not need to store a `typeid` because it is a closed ABI-consistent set of variant types.
package reflect