import "core:fmt.odin";
import "core:os.odin";
import "core:mem.odin";
// import "http_test.odin" as ht;
// import "game.odin" as game;
// import "punity.odin" as pn;

main :: proc() {
	struct_padding();
	bounds_checking();
	type_introspection();
	any_type();
	crazy_introspection();
	namespaces_and_files();
	miscellany();

	/*
	ht.run();
	game.run();
	{
		init :: proc(c: ^pn.Core) {}
		step :: proc(c: ^pn.Core) {}

		pn.run(init, step);
	}
	*/
}

struct_padding :: proc() {
	{
		A :: struct {
			a: u8,
			b: u32,
			c: u16,
		}

		B :: struct {
			a: [7]u8,
			b: [3]u16,
			c: u8,
			d: u16,
		}

		fmt.println("size_of(A):", size_of(A));
		fmt.println("size_of(B):", size_of(B));

		// n.b. http://cbloomrants.blogspot.co.uk/2012/07/07-23-12-structs-are-not-what-you-want.html
	}
	{
		A :: struct #ordered {
			a: u8,
			b: u32,
			c: u16,
		}

		B :: struct #ordered {
			a: [7]u8,
			b: [3]u16,
			c: u8,
			d: u16,
		}

		fmt.println("size_of(A):", size_of(A));
		fmt.println("size_of(B):", size_of(B));

		// C-style structure layout
	}
	{
		A :: struct #packed {
			a: u8,
			b: u32,
			c: u16,
		}

		B :: struct #packed {
			a: [7]u8,
			b: [3]u16,
			c: u8,
			d: u16,
		}

		fmt.println("size_of(A):", size_of(A));
		fmt.println("size_of(B):", size_of(B));

		// Useful for explicit layout
	}

	// Member sorting by priority
	// Alignment desc.
	// Size desc.
	// source order asc.

	/*
		A :: struct {
			a: u8
			b: u32
			c: u16
		}

		B :: struct {
			a: [7]u8
			b: [3]u16
			c: u8
			d: u16
		}

		Equivalent too

		A :: struct #ordered {
			b: u32
			c: u16
			a: u8
		}

		B :: struct #ordered {
			b: [3]u16
			d: u16
			a: [7]u8
			c: u8
		}
	*/
}

bounds_checking :: proc() {
	x: [4]int;
	// x[-1] = 0; // Compile Time
	// x[4]  = 0; // Compile Time

	{
		a, b := -1, 4;
		// x[a] = 0; // Runtime Time
		// x[b] = 0; // Runtime Time
	}

	// Works for arrays, strings, slices, and related procedures & operations

	{
		base: [10]int;
		s := base[2..6];
		a, b := -1, 6;

		#no_bounds_check {
			s[a] = 0;
			// #bounds_check s[b] = 0;
		}

	#no_bounds_check
		if s[a] == 0 {
			// Do whatever
		}

		// Bounds checking can be toggled explicit
		// on a per statement basis.
		// _any statement_
	}
}

type_introspection :: proc() {
	{
		info: ^Type_Info;
		x: int;

		info = type_info_of(int); // by type
		info = type_info_of(x);   // by value
		// See: runtime.odin

		match i in info.variant {
		case Type_Info_Integer:
			fmt.println("integer!");
		case Type_Info_Float:
			fmt.println("float!");
		case:
			fmt.println("potato!");
		}

		// Unsafe cast
		integer_info := cast(^Type_Info_Integer)cast(rawptr)info;
	}

	{
		Vector2 :: struct { x, y: f32 }
		Vector3 :: struct { x, y, z: f32 }

		v1: Vector2;
		v2: Vector3;
		v3: Vector3;

		t1 := type_info_of(v1);
		t2 := type_info_of(v2);
		t3 := type_info_of(v3);

		fmt.println();
		fmt.print("Type of v1 is:\n\t", t1);

		fmt.println();
		fmt.print("Type of v2 is:\n\t", t2);

		fmt.println("\n");
		fmt.println("t1 == t2:", t1 == t2);
		fmt.println("t2 == t3:", t2 == t3);
	}
}

any_type :: proc() {
	a: any;

	x: int = 123;
	y: f64 = 6.28;
	z: string = "Yo-Yo Ma";
	// All types can be implicit cast to `any`
	a = x;
	a = y;
	a = z;
	a = a; // This the "identity" type, it doesn't get converted

	a = 123; // Literals are copied onto the stack first

	// any has two members
	// data      - rawptr to the data
	// type_info - pointer to the type info

	fmt.println(x, y, z);
	// See: fmt.odin
	// For variadic any procedures in action
}

crazy_introspection :: proc() {
	{
		Fruit :: enum {
			APPLE,
			BANANA,
			GRAPE,
			MELON,
			PEACH,
			TOMATO,
		}

		s: string;
		// s = enum_to_string(Fruit.PEACH);
		fmt.println(s);

		f := Fruit.GRAPE;
		// s = enum_to_string(f);
		fmt.println(s);

		fmt.println(f);
		// See: runtime.odin
	}


	{
		// NOTE(bill): This is not safe code and I would not recommend this at all
		// I'd recommend you use `match type` to get the subtype rather than
		// casting pointers

		Fruit :: enum {
			APPLE,
			BANANA,
			GRAPE,
			MELON,
			PEACH,
			TOMATO,
		}

		fruit_ti := type_info_of(Fruit);
		name := fruit_ti.variant.(Type_Info_Named).name;
		info, _ := type_info_base(fruit_ti).variant.(Type_Info_Enum);

		fmt.printf("%s :: enum %T {\n", name, info.base);
		for _, i in info.values {
			fmt.printf("\t%s\t= %v,\n", info.names[i], info.values[i]);
		}
		fmt.printf("}\n");

		// NOTE(bill): look at that type-safe printf!
	}

	{
		Vector3 :: struct {x, y, z: f32}

		a := Vector3{x = 1, y = 4, z = 9};
		fmt.println(a);
		b := Vector3{x = 9, y = 3, z = 1};
		fmt.println(b);

		// NOTE(bill): See fmt.odin
	}

	// n.b. This pretty much "solves" serialization (to strings)
}

// #import "test.odin"

namespaces_and_files :: proc() {

	// test.thing()
	// test.format.println()
	// test.println()
	/*
		// Non-exporting import
		#import "file.odin"
		#import "file.odin" as file
		#import "file.odin" as .
		#import "file.odin" as _

		// Exporting import
		#include "file.odin"
	*/

	// Talk about scope rules and diagram
}

miscellany :: proc() {
	/*
		win32 `__imp__` prefix
		#dll_import
		#dll_export

		Change exported name/symbol for linking
		#link_name

		Custom calling conventions
		#stdcall
		#fastcall

		Runtime stuff
		#shared_global_scope
	*/

	// assert(false)
	// #assert(false)
	// panic("Panic message goes here")
}




