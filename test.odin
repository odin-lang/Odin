package test

import "core:fmt"
import "core:intrinsics"
import "core:mem"
import "core:reflect"
import "core:runtime"
import "core:slice"

// TODO: extend for loops?

get_tag :: proc(u: $T) -> int where intrinsics.type_is_union(T) {
	u := u
	return int(
		(cast(^intrinsics.type_union_tag_type(T))(uintptr(&u) +
				intrinsics.type_union_tag_offset(T)))^,
	)
}

set_tag :: proc(u: ^$T, tag: int) where intrinsics.type_is_union(T) {
	TAG :: intrinsics.type_union_tag_type(T)
	(cast(^TAG)(uintptr(u) + intrinsics.type_union_tag_offset(T)))^ = TAG(tag)
}

get_variant_index :: proc(u: $T) -> int where intrinsics.type_is_union(T) {
	return min(T) + get_tag(u)
}

main :: proc() {
	Foo :: union {
		f32, // 1
		u16, // 2
		u8, // 3
	}

	fmt.println(typeid_of(Foo))
	fmt.println("size_of:", size_of(Foo))
	fmt.println("len:", len(Foo))
	fmt.println("cap:", cap(Foo))
	fmt.println("min:", min(Foo))
	fmt.println("max:", max(Foo))
	fmt.println("tag:", typeid_of(intrinsics.type_union_tag_type(Foo)))
	fmt.println("tag offset:", intrinsics.type_union_tag_offset(Foo))
	fmt.println("type of 0:", typeid_of(intrinsics.type_variant_type_of(Foo, 0)))
	fmt.println("type of 1:", typeid_of(intrinsics.type_variant_type_of(Foo, 1)))
	fmt.println("type of 2:", typeid_of(intrinsics.type_variant_type_of(Foo, 2)))
	fmt.println("index of f32:", intrinsics.type_variant_index_of(Foo, f32))
	fmt.println("index of u16:", intrinsics.type_variant_index_of(Foo, u16))
	fmt.println("index of u8 :", intrinsics.type_variant_index_of(Foo, u8))
	// Goofy test of unsafe tag manipulation
	foo: Foo = u16(255 + 255 << 8)
	assert(get_tag(foo) == 2)
	fmt.println(foo)
	set_tag(&foo, 3)
	assert(get_tag(foo) == 3)
	fmt.println(foo)
	fmt.println()

	Bar :: union #no_nil {
		i8, // 0
		u8, // 1
		b8, // 2
	}

	fmt.println(typeid_of(Bar))
	fmt.println("size_of:", size_of(Bar))
	fmt.println("len:", len(Bar))
	fmt.println("cap:", cap(Bar))
	fmt.println("min:", min(Bar))
	fmt.println("max:", max(Bar))
	fmt.println("tag:", typeid_of(intrinsics.type_union_tag_type(Bar)))
	fmt.println("tag offset:", intrinsics.type_union_tag_offset(Bar))
	fmt.println("type of 0:", typeid_of(intrinsics.type_variant_type_of(Bar, 0)))
	fmt.println("type of 1:", typeid_of(intrinsics.type_variant_type_of(Bar, 1)))
	fmt.println("type of 2:", typeid_of(intrinsics.type_variant_type_of(Bar, 2)))
	fmt.println("index of f32:", intrinsics.type_variant_index_of(Bar, i8))
	fmt.println("index of u16:", intrinsics.type_variant_index_of(Bar, u8))
	fmt.println("index of u8: ", intrinsics.type_variant_index_of(Bar, b8))
	fmt.println()

	Baz :: union #shared_nil {
		[]u8, // 1
		rawptr, // 2
		^u8, // 3
	}

	fmt.println(typeid_of(Baz))
	fmt.println("size_of:", size_of(Baz))
	fmt.println("len:", len(Baz))
	fmt.println("cap:", cap(Baz))
	fmt.println("min:", min(Baz))
	fmt.println("max:", max(Baz))
	fmt.println("tag:", typeid_of(intrinsics.type_union_tag_type(Baz)))
	fmt.println("tag offset:", intrinsics.type_union_tag_offset(Baz))
	fmt.println("type of 0:", typeid_of(intrinsics.type_variant_type_of(Baz, 0)))
	fmt.println("type of 1:", typeid_of(intrinsics.type_variant_type_of(Baz, 1)))
	fmt.println("type of 2:", typeid_of(intrinsics.type_variant_type_of(Baz, 2)))
	fmt.println("index of []u8:  ", intrinsics.type_variant_index_of(Baz, []u8))
	fmt.println("index of rawptr:", intrinsics.type_variant_index_of(Baz, rawptr))
	fmt.println("index of ^u8:   ", intrinsics.type_variant_index_of(Baz, ^u8))
	fmt.println()

	Mby :: Maybe(f32)

	fmt.println(typeid_of(Mby))
	fmt.println("size_of:", size_of(Mby))
	fmt.println("len:", len(Mby))
	fmt.println("cap:", cap(Mby))
	fmt.println("min:", min(Mby))
	fmt.println("max:", max(Mby))
	fmt.println("tag:", typeid_of(intrinsics.type_union_tag_type(Mby)))
	fmt.println("tag offset:", intrinsics.type_union_tag_offset(Mby))
	fmt.println("type of 1:", typeid_of(intrinsics.type_variant_type_of(Mby, 0)))
	fmt.println("index of f32:", intrinsics.type_variant_index_of(Mby, f32))
	fmt.println()

	// #unroll for i in 0 ..< intrinsics.type_proc_parameter_count(Proc) {
	// 	fmt.println(intrinsics.type_proc_parameter_type(Proc, i))
	// }

	// arr: Packed_Union_Array(Foo)
	// init(&arr)

	// append(&arr, f32(1.23))
	// append(&arr, f32(-1))
	// append(&arr, f32(-2))
	// append(&arr, f32(-3))
	// append(&arr, u8(0))
	// append(&arr, u8(255))
	// append(&arr, u8(255))

	// fmt.println(get_data(arr, f32))
	// fmt.println(get_data(arr, u16))
	// fmt.println(get_data(arr, u8))

	// pool: Packed_Union_Pool(Foo)
	// packed_union_pool_init(&pool)

	// a := packed_union_pool_insert(&pool, f32(1.0))
	// packed_union_pool_insert(&pool, f32(3.0))
	// packed_union_pool_insert(&pool, u8(0))
	// packed_union_pool_remove(&pool, a)
	// packed_union_pool_insert(&pool, f32(1.234))

	// // prints 1.234 since it was overwritten
	// fmt.println(a^)
}


// Packed_Union_Array_Variant :: struct {
// 	data: []u8,
// 	len:  int,
// }

// Packed_Union_Array :: struct($T: typeid) where intrinsics.type_is_union(T) {
// 	variants:  [len(T)]Packed_Union_Array_Variant,
// 	allocator: runtime.Allocator,
// }

// packed_union_array_init :: proc(
// 	a: ^$T/Packed_Union_Array($U),
// 	cap: int = 32,
// 	allocator := context.allocator,
// ) {
// 	a^ = {
// 		allocator = allocator,
// 	}

// 	// RTTI hack since a loop cannot produce compile-time constant
// 	ti := reflect.type_info_base(type_info_of(U)).variant.(reflect.Type_Info_Union)
// 	for &v, i in a.variants {
// 		data, _ := mem.alloc_bytes_non_zeroed(cap * ti.variants[i].size)
// 		v = {
// 			data = data,
// 			len  = 0,
// 		}
// 	}
// }

// packed_union_array_append :: proc(
// 	a: ^$T/Packed_Union_Array($U),
// 	value: $V,
// ) where intrinsics.type_is_variant_of(U, V) {
// 	variants := &a.variants[intrinsics.type_variant_index_of(U, V)]

// 	if variants.len >= len(variants.data) {
// 		// alloc more
// 	}

// 	data := packed_union_array_get_data_buf(a^, V)
// 	data[variants.len / size_of(V)] = value
// 	variants.len += size_of(V)
// }

// packed_union_array_set :: proc(
// 	a: $T/Packed_Union_Array($U),
// 	index: int,
// 	value: $V,
// ) where intrinsics.type_is_variant_of(U, V) {
// 	packed_union_array_get_data(a, V)[index] = value
// }

// packed_union_array_get :: proc(
// 	a: $T/Packed_Union_Array($U),
// 	$V: typeid,
// 	index: int,
// ) -> V where intrinsics.type_is_variant_of(U, V) {
// 	return packed_union_array_get_data(a, V)[index]
// }

// packed_union_array_get_data :: proc(
// 	a: $T/Packed_Union_Array($U),
// 	$V: typeid,
// ) -> []V where intrinsics.type_is_variant_of(U, V) {
// 	vars := a.variants[intrinsics.type_variant_index_of(U, V)]
// 	return slice.reinterpret([]V, vars.data)[:vars.len / size_of(V)]
// }

// packed_union_array_get_data_buf :: proc(
// 	a: $T/Packed_Union_Array($U),
// 	$V: typeid,
// ) -> []V where intrinsics.type_is_variant_of(U, V) {
// 	return slice.reinterpret([]V, a.variants[intrinsics.type_variant_index_of(U, V)].data)
// }

// // Basically like a pool with free list size buckets, but optimized for the specific union type.
// Packed_Union_Pool :: struct($T: typeid) where intrinsics.type_is_union(T) {
// 	// Should be a fast allocator like an arena.
// 	allocator:  runtime.Allocator,
// 	free_lists: [len(T)]rawptr,
// }

// Packed_Union_Pool_Item :: struct($T: typeid) {
// 	data:      T,
// 	next_free: rawptr,
// }

// packed_union_pool_init :: proc(p: ^$T/Packed_Union_Pool($U), allocator := context.allocator) {
// 	p^ = {
// 		allocator = allocator,
// 	}
// }

// packed_union_pool_insert :: proc(
// 	p: ^$T/Packed_Union_Pool($U),
// 	val: $V,
// ) -> (
// 	result: ^V,
// 	err: mem.Allocator_Error,
// ) #optional_allocator_error {
// 	ptr := cast(^Packed_Union_Pool_Item(V))p.free_lists[intrinsics.type_variant_index_of(U, V)]
// 	if ptr == nil {
// 		ptr = new(Packed_Union_Pool_Item(V), p.allocator) or_return
// 	} else {
// 		p.free_lists[intrinsics.type_variant_index_of(U, V)] = ptr.next_free
// 	}

// 	ptr^ = {
// 		data      = val,
// 		next_free = nil,
// 	}

// 	return &ptr.data, nil
// }

// packed_union_pool_remove :: proc(p: ^$T/Packed_Union_Pool($U), ptr: ^$V) {
// 	assert(ptr != nil)

// 	item := cast(^Packed_Union_Pool_Item(V))ptr
// 	item.next_free = p.free_lists[intrinsics.type_variant_index_of(U, V)]
// 	p.free_lists[intrinsics.type_variant_index_of(U, V)] = item
// }
