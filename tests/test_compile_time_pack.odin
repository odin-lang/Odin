package test_compile_time_pack

import "core:fmt"

write_value :: proc(val: $T) {
	when T == int {
		fmt.println("Integer:", val)
	} else when T == f32 {
		fmt.println("Float32:", val)
	} else when T == string {
		fmt.println("String:", val)
	} else when T == bool {
		fmt.println("Boolean:", val)
	} else {
		fmt.println("Other:", val)
	}
}

print_pack :: proc(prefix: string, args: ..#type) {
	fmt.println("--- prefix:", prefix, "len:", len(args), "---")
	#unroll for arg in args {
		write_value(arg)
	}
}

print_pack_with_idx :: proc(prefix: string, args: ..#type) {
	fmt.println("--- indexed prefix:", prefix, "---")
	#unroll for arg, idx in args {
		fmt.print("[", idx, "] = ")
		write_value(arg)
	}
}

test_indexing :: proc(args: ..#type) {
	when len(args) >= 2 {
		fmt.println("args[0] =", args[0])
		fmt.println("args[1] =", args[1])
	}
}

write_static_verify :: proc(val: $T) {
	when T == int {
		fmt.println("Statically verified int * 2:", val * 2)
	} else when T == string {
		fmt.println("Statically verified string len:", len(val))
	} else {
		fmt.println("Statically verified other:", val)
	}
}

verify_static_types :: proc(args: ..#type) {
	#unroll for arg in args {
		write_static_verify(arg)
	}
}

main :: proc() {
	print_pack("heterogeneous test", 123, f32(3.14), "hello world", true)
	print_pack_with_idx("indexed test", "first", 999, false)
	print_pack("empty pack test")
	test_indexing("direct index", 42)
	verify_static_types(100, "testing static types", 250)
}
