#import "fmt.odin";
#import "utf8.odin";

main :: proc() {
	syntax();
}

syntax :: proc() {
	// Cyclic type checking
	// Uncomment to see the error
	// A :: struct { b: B };
	// B :: struct { a: A };

	x: int;
	y := cast(f32)x;
	z := transmute(u32)y;
	// down_cast, union_cast as similar too



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

	// Slice interals are not just a `ptr+count`
	slice: []int; compile_assert(size_of_val(slice) == 2*size_of(int));

	// Helper type - Help the reader understand that it is quicker
	My_Int  :: type int;
	My_Proc :: type proc(int) -> f32;


	// All declarations with : are either variable or constant
	// To make these declarations syntactically consistent
	v_variable := 123;
	c_constant :: 123;
	c_type1    :: int;
	c_type2    :: []int;
	c_proc     :: proc() { /* code here */ };


	x += 1;
	x -= 1;
	// ++ and -- have been removed
	// x++;
	// x--;


	// You can now build files as a `.dll`
	// `odin build_dll demo.odin`


	// Next part
	prefixes();
}


Prefix_Type :: struct {x: int, y: f32, z: rawptr};

thread_local my_tls: Prefix_Type;

prefixes :: proc() {
	using var: Prefix_Type;
	immutable const := Prefix_Type{1, 2, nil};
	var.x = 123;
	x = 123;
	// const.x = 123; // const is immutable



	foo :: proc(using immutable pt: Prefix_Type, immutable int_ptr: ^int) {
		// int_ptr = nil; // Not valid
		int_ptr^ = 123; // Is valid
	}



	// Same as C99's `restrict`
	bar :: proc(no_alias a, b: ^int) {
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

#import "atomic.odin" when ODIN_OS == "windows";
#foreign_system_library win32_user "user32.lib" when ODIN_OS == "windows";
// NOTE: This is done on purpose for two reasons:
// * Makes it clear where the platform specific stuff is
// * Removes the need to solve the travelling salesman problem when importing files :P

foreign_procedures :: proc() {
	ShowWindow  :: proc(hwnd: rawptr, cmd_show: i32) -> i32 #foreign win32_user;
	show_window :: proc(hwnd: rawptr, cmd_show: i32) -> i32 #foreign win32_user "ShowWindow";
	// NOTE: If that library doesn't get used, it doesn't get linked with
	// NOTE: There is not link checking yet to see if that procedure does come from that library

	special_expressions();
}

special_expressions :: proc() {
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
		// E.g. this constant "number" should be able to be cast to a `f32` automatically
		give cast(f32)123;
	}; // semicolon is required as it's an expression


	// This is allows for inline blocks of code and will be a useful feature to have when
	// macros will be implemented into the language

	loops();
}

loops :: proc() {

	// while loops
	while true {
		break;
	}
	while x := 123; x < 124 {
		x += 2;
	}


/*
	This only C-style for loop has now been removed

	for i := 0; i < 123; i += 1 {
	}
*/
	for i : 0..<123 {
	}

	for i : 0...122 {
	}

	for val, idx : 12..<16 {
		fmt.println(val, idx);
	}

	primes := [...]int{2, 3, 5, 7, 11, 13, 17, 19};

	for p : primes {
		fmt.println(p);
	}

	// Pointers to arrays, slices, or strings are allowed
	for _ : ^primes {
		// ignore the value and just iterate across it
	}



	name := "你好，世界";
	fmt.println(name);
	for r : name {
		compile_assert(type_of_val(r) == rune);
		fmt.printf("%r\n", r);
	}

	when false {
		while i := 0; i < name.count {
			r, size := utf8.decode_rune(name[i:]);
			i += size;
			fmt.printf("%c\n", r);
		}
	}





	// Emulate a C-style loop (not exactly the same though)
	while x := 0; x < 10 {
		defer x += 2;

		/* rest of the code */
		// If `break` is used, the `defer` is still called so it's not the same
		// as a C-style for loop
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
	// foo(THINGI);
	foo(cast(int)THINGI);
	fmt.println(THINGF);
	fmt.println(THINGI);




	foo :: proc(x: ^i32) -> (int, int) {
		fmt.println("^int");
		return 123, cast(int)(x^);
	}
	foo :: proc(x: rawptr) {
		fmt.println("rawptr");
	}


	a: i32 = #line;
	b: f32;
	c: rawptr;
	fmt.println(foo(^a));
	foo(^b);
	foo(c);
	// foo(nil);
	atomic.store(^a, 1);


	f: proc();
	f = foo;
	f();
}
