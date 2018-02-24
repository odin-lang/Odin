import "core:fmt.odin";
import "core:utf8.odin";
// import "core:atomic.odin";
// import "core:hash.odin";
// import "core:math.odin";
// import "core:mem.odin";
// import "core:opengl.odin";
// import "core:os.odin";
// import "core:sync.odin";
// import win32 "core:sys/windows.odin";

main :: proc() {
	// syntax();
	procedure_overloading();
}

syntax :: proc() {
	// Cyclic type checking
	// Uncomment to see the error
	// A :: struct {b: B};
	// B :: struct {a: A};

	x: int;
	y := cast(f32)x;
	z := transmute(u32)y;
	// down_cast, union_cast are similar too



	// Basic directives
	fmt.printf("Basic directives = %s(%d): %s\n", #file, #line, #procedure);
	// NOTE: new and improved `printf`
	// TODO: It does need accurate float printing



	// record fields use the same syntax a procedure signatures
	Thing1 :: struct {
		x: f32,
		y: int,
		z: ^[]int,
	};
	Thing2 :: struct {x: f32, y: int, z: ^[]int};

	// Slice interals are now just a `ptr+len+cap`
	slice: []int; #assert(size_of(slice) == 3*size_of(int));

	// Helper type - Help the reader understand what it is quicker
	My_Int  :: #type int;
	My_Proc :: #type proc(int) -> f32;


	// All declarations with : are either variable or constant
	// To make these declarations syntactically consistent
	v_variable := 123;
	c_constant :: 123;
	c_type1    :: int;
	c_type2    :: []int;
	c_proc     :: proc() { /* code here */ };


/*
	x += 1;
	x -= 1;
	// ++ and -- have been removed
	// x++;
	// x--;
	// Question: Should they be added again?
	// They were removed as they are redundant and statements, not expressions
	// like in C/C++
*/

	// You can now build files as a `.dll`
	// `odin build_dll demo.odin`


	// New vector syntax
	u, v: [vector 3]f32;
	v[0] = 123;
	v.x  = 123; // valid for all vectors with count 1 to 4

	// Next part
	prefixes();
}


Prefix_Type :: struct {x: int, y: f32, z: rawptr};

#thread_local my_tls: Prefix_Type;

prefixes :: proc() {
	using var: Prefix_Type;
	var.x = 123;
	x = 123;


	foo :: proc(using pt: Prefix_Type) {
	}



	// Same as C99's `restrict`
	bar :: proc(#no_alias a, b: ^int) {
		// Assumes a never equals b so it can perform optimizations with that fact
	}


	when_statements();
}





when_statements :: proc() {
	X :: 123 + 12;
	Y :: X/5;
	COND :: Y > 0;

	when COND {
		fmt.println("Y > 0");
	} else {
		fmt.println("Y <= 0");
	}


	when false {
		this_code_does_not_exist(123, 321);
		but_its_syntax_is_valid();
		x :: ^^^^int;
	}

	foreign_procedures();
}

when ODIN_OS == "windows" {
	foreign_system_library win32_user "user32.lib";
}
// NOTE: This is done on purpose for two reasons:
// * Makes it clear where the platform specific stuff is
// * Removes the need to solve the travelling salesman problem when importing files :P

foreign_procedures :: proc() {
	foreign win32_user {
		ShowWindow  :: proc(hwnd: rawptr, cmd_show: i32) -> i32 ---;
		show_window :: proc(hwnd: rawptr, cmd_show: i32) -> i32 #link_name "ShowWindow" ---;
	}
	// NOTE: If that library doesn't get used, it doesn't get linked with
	// NOTE: There is not link checking yet to see if that procedure does come from that library

	// See sys/windows.odin for more examples

	special_expressions();
}

special_expressions :: proc() {
/*
	// Block expression
	x := {
		a: f32 = 123;
		b := a-123;
		c := b/a;
		give c;
	}; // semicolon is required as it's an expression

	y := if x < 50 {
		give x;
	} else {
		// TODO: Type cohesion is not yet finished
		give 123;
	}; // semicolon is required as it's an expression
*/

	// This is allows for inline blocks of code and will be a useful feature to have when
	// macros will be implemented into the language

	loops();
}

loops :: proc() {
	// The C-style for loop
	for i := 0; i < 123; i += 1 {
		break;
	}
	for i := 0; i < 123; {
		break;
	}
	for false {
		break;
	}
	for {
		break;
	}

	for i in 0..123 { // 123 exclusive
	}

	for i in 0..123-1 { // 122 inclusive
	}

	for val, idx in 12..16 {
		fmt.println(val, idx);
	}

	primes := [?]int{2, 3, 5, 7, 11, 13, 17, 19};

	for p in primes {
		fmt.println(p);
	}

	// Pointers to arrays, slices, or strings are allowed
	for _ in &primes {
		// ignore the value and just iterate across it
	}



	name := "你好，世界";
	fmt.println(name);
	for r in name {
		#assert(type_of(r) == rune);
		fmt.printf("%r\n", r);
	}

	when false {
		for i, size := 0; i < name.count; i += size {
			r: rune;
			r, size = utf8.decode_rune(name[i..]);
			fmt.printf("%r\n", r);
		}
	}

	procedure_overloading();
}


procedure_overloading :: proc() {
	THINGF :: 14451.1;
	THINGI :: 14451;

	foo :: proc() {
		fmt.printf("Zero args\n");
	}
	foo :: proc(i: int) {
		fmt.printf("int arg, i=%d\n", i);
	}
	foo :: proc(f: f64) {
		i := cast(int)f;
		fmt.printf("f64 arg, f=%d\n", i);
	}

	foo();
	foo(THINGF);
	// foo(THINGI); // 14451 is just a number so it could go to either procedures
	foo(cast(int)THINGI);




	foo :: proc(x: ^i32) -> (int, int) {
		fmt.println("^int");
		return 123, cast(int)(x^);
	}
	foo :: proc(x: rawptr) {
		fmt.println("rawptr");
	}


	a: i32 = 123;
	b: f32;
	c: rawptr;
	fmt.println(foo(&a));
	foo(&b);
	foo(c);
	// foo(nil); // nil could go to numerous types thus the ambiguity

	f: proc();
	f = foo; // The correct `foo` to chosen
	f();


	// See math.odin and atomic.odin for more examples
}
