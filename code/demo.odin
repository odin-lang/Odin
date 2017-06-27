import "fmt.odin";

proc general_stuff() {
	// Complex numbers
	var a = 3 + 4i;
	var b: complex64 = 3 + 4i;
	var c: complex128 = 3 + 4i;
	var d = complex(2, 3);

	var e = a / conj(a);
	fmt.println("(3+4i)/(3-4i) =", e);
	fmt.println(real(e), "+", imag(e), "i");


	// C-style variadic procedures
	foreign __llvm_core {
		// The variadic part allows for extra type checking too which C does not provide
		proc c_printf(fmt: ^u8, #c_vararg args: ..any) -> i32 #link_name "printf";
	}


	type Foo struct {
		x: int,
		y: f32,
		z: string,
	}
	var foo = Foo{123, 0.513, "A string"};
	var x, y, z = expand_to_tuple(foo);
	fmt.println(x, y, z);


	// By default, all variables are zeroed
	// This can be overridden with the "uninitialized value"
	// This is similar to `nil` but applied to everything
	var undef_int: int = ---;


	// Context system is now implemented using Implicit Parameter Passing (IPP)
	// The previous implementation was Thread Local Storage (TLS)
	// IPP has the advantage that it works on systems without TLS and that you can
	// link the context to the stack frame and thus look at previous contexts
	//
	// It does mean that a pointer is implicitly passed procedures with the default
	// Odin calling convention (#cc_odin)
	// This can be overridden with something like #cc_contextless or #cc_c if performance
	// is worried about

}

proc foreign_blocks() {
	// See sys/windows.odin
}


proc default_arguments() {
	proc hello(a: int = 9, b: int = 9) {
		fmt.printf("a is %d; b is %d\n", a, b);
	}
	fmt.println("\nTesting default arguments:");
	hello(1, 2);
	hello(1);
	hello();
}

proc named_arguments() {
	type Colour enum {
		Red,
		Orange,
		Yellow,
		Green,
		Blue,
		Octarine,
	};
	using Colour;

	proc make_character(name, catch_phrase: string, favorite_color, least_favorite_color: Colour) {
	    fmt.println();
	    fmt.printf("My name is %v and I like %v.  %v\n", name, favorite_color, catch_phrase);
	}

	make_character("Frank", "¡Ay, caramba!", Blue, Green);


	// As the procedures have more and more parameters, it is very easy
	// to get many of the arguments in the wrong order especialy if the
	// types are the same
	make_character("¡Ay, caramba!", "Frank", Green, Blue);

	// Named arguments help to disambiguate this problem
	make_character(catch_phrase = "¡Ay, caramba!", name = "Frank",
	               least_favorite_color = Green, favorite_color = Blue);


	// The named arguments can be specifed in any order.
	make_character(favorite_color = Octarine, catch_phrase = "U wot m8!",
	               least_favorite_color = Green, name = "Dennis");


	// NOTE: You cannot mix named arguments with normal values
	/*
	make_character("Dennis",
	               favorite_color = Octarine, catch_phrase = "U wot m8!",
	               least_favorite_color = Green);
	*/


	// Named arguments can also aid with default arguments
	proc numerous_things(s : string, a = 1, b = 2, c = 3.14,
	                     d = "The Best String!", e = false, f = 10.3/3.1, g = false) {
		var g_str = g ? "true" : "false";
		fmt.printf("How many?! %s: %v\n", s, g_str);
	}

	numerous_things("First");
	numerous_things(s = "Second", g = true);


	// Default values can be placed anywhere, not just at the end like in other languages
	proc weird(pre: string, mid: int = 0, post: string) {
		fmt.println(pre, mid, post);
	}

	weird("How many things", 42, "huh?");
	weird(pre = "Prefix", post = "Pat");

}


proc default_return_values() {
	proc foo(x: int) -> (first: string = "Hellope", second = "world!") {
		match x {
		case 0: return;
		case 1: return "Goodbye";
		case 2: return "Goodbye", "cruel world...";
		case 3: return second = "cruel world...", first = "Goodbye";
		}

		return second = "my old friend.";
	}

	fmt.printf("%s %s\n", foo(0));
	fmt.printf("%s %s\n", foo(1));
	fmt.printf("%s %s\n", foo(2));
	fmt.printf("%s %s\n", foo(3));
	fmt.printf("%s %s\n", foo(4));
	fmt.println();


	// A more "real" example
	type Error enum {
		None,
		WhyTheNumberThree,
		TenIsTooBig,
	};

	type Entity struct {
		name: string,
		id:   u32,
	}

	proc some_thing(input: int) -> (result: ^Entity = nil, err = Error.None) {
		match {
		case input == 3: return err = Error.WhyTheNumberThree;
		case input >= 10: return err = Error.TenIsTooBig;
		}

		var e = new(Entity);
		e.id = u32(input);

		return result = e;
	}
}

proc call_location() {
	proc amazing(n: int, using loc = #caller_location) {
		fmt.printf("%s(%d:%d) just asked to do something amazing.\n",
		           fully_pathed_filename, line, column);
		fmt.printf("Normal -> %d\n", n);
		fmt.printf("Amazing -> %d\n", n+1);
		fmt.println();
	}

	var loc = #location(main);
	fmt.println("`main` is located at", loc);

	fmt.println("This line is located at", #location());
	fmt.println();

	amazing(3);
	amazing(4, #location(call_location));

	// See _preload.odin for the implementations of `assert` and `panic`

}


proc explicit_parametric_polymorphic_procedures() {
	// This is how `new` is actually implemented, see _preload.odin
	proc alloc_type(T: type) -> ^T {
		return ^T(alloc(size_of(T), align_of(T)));
	}

	var int_ptr = alloc_type(int);
	defer free(int_ptr);
	int_ptr^ = 137;
	fmt.println(int_ptr, int_ptr^);

	// Named arguments work too!
	var another_ptr = alloc_type(T = f32);
	defer free(another_ptr);


	proc add(T: type, args: ..T) -> T {
		var res: T;
		for arg in args {
			res += arg;
		}
		return res;
	}

	fmt.println("add =", add(int, 1, 2, 3, 4, 5, 6));

	proc swap(T: type, a, b: ^T) {
		var tmp = a^;
		a^ = b^;
		b^ = tmp;
	}

	var a, b: int = 3, 4;
	fmt.println("Pre-swap:", a, b);
	swap(int, &a, &b);
	fmt.println("Post-swap:", a, b);
	a, b = b, a; // Or use this syntax for this silly example case






	// A more complicated example using subtyping
	// Something like this could be used in a game
	type Vector2 struct {x, y: f32};

	type Entity struct {
		using position: Vector2,
		flags:          u64,
		id:             u64,
		batch_index:    u32,
		slot_index:     u32,
		portable_id:    u32,
		derived:        any,
	}

	type Rock struct {
		using entity: ^Entity,
		heavy: bool,
	}
	type Door struct {
		using entity: ^Entity,
		open:         bool,
	}
	type Monster struct {
		using entity: ^Entity,
		is_robot:     bool,
		is_zombie:    bool,
	}

	type EntityManager struct {
		batches: [dynamic]^EntityBatch,
		next_portable_id: u32,
	}

	const ENTITIES_PER_BATCH = 16;
	type EntityBatch struct {
		data:        [ENTITIES_PER_BATCH]Entity,
		occupied:    [ENTITIES_PER_BATCH]bool,
		batch_index: u32,
	}

	proc use_empty_slot(manager: ^EntityManager, batch: ^EntityBatch) -> ^Entity {
		for ok, i in batch.occupied {
			if ok -> continue;
			batch.occupied[i] = true;

			var e = &batch.data[i];
			e.batch_index = u32(batch.batch_index);
			e.slot_index  = u32(i);
			e.portable_id = manager.next_portable_id;
			manager.next_portable_id++;
			return e;
		}
		return nil;
	}

	proc gen_new_entity(manager: ^EntityManager) -> ^Entity {
		for b in manager.batches {
			var e = use_empty_slot(manager, b);
			if e != nil -> return e;
		}

		var new_batch = new(EntityBatch);
		append(manager.batches, new_batch);
		new_batch.batch_index = u32(len(manager.batches)-1);

		return use_empty_slot(manager, new_batch);
	}



	proc new_entity(manager: ^EntityManager, Type: type, x, y: int) -> ^Type {
		var result = new(Type);
		result.entity = gen_new_entity(manager);
		result.derived.data = result;
		result.derived.type_info = type_info(Type);

		result.position.x = f32(x);
		result.position.y = f32(y);

		return result;
	}

	var manager: EntityManager;
	var entities: [dynamic]^Entity;

	var rock    = new_entity(&manager, Rock, 3, 5);

	// Named arguments work too!
	var door    = new_entity(manager = &manager, Type = Door, x = 3, y = 6);

	// And named arguments can be any order
	var monster = new_entity(
		y = 1,
		x = 2,
		manager = &manager,
		Type = Monster,
	);

	append(entities, rock, door, monster);

	// An alternative to `union`s
	for entity in entities {
		match e in entity.derived {
		case Rock:    fmt.println("Rock",    e.portable_id);
		case Door:    fmt.println("Door",    e.portable_id);
		case Monster: fmt.println("Monster", e.portable_id);
		}
	}
}

proc main() {
	general_stuff();
	foreign_blocks();
	default_arguments();
	named_arguments();
	default_return_values();
	call_location();
	explicit_parametric_polymorphic_procedures();

	// Command line argument(s)!
	// -opt=0,1,2,3


	/*************/
	/* Questions */
	/*************/

	/*
		I'm questioning if I should change the declaration syntax back to Jai-like
		as I've found solutions to the problems I had with it before.

		Should I change back to Jai-like declarations or keep with the Pascal-like?

		Jai-like

		x: int;
		x: int = 123;
		x := 123;

		foo : int : 123;
		foo :: 123;

		MyInt :: int;
		BarType :: proc();

		bar :: proc() {
		}

		foreign lib {
			foreign_bar :: proc() ---;
		}

		Pascal-like

		var x: int;
		var x: int = 123;
		var x = 123;

		const foo: int = 123;
		const foo = 123;

		type MyInt int;
		type BarType proc();

		proc bar() {
		}

		foreign lib {
			proc foreign_bar();
		}
	 */

}

/*
proc main() {
	var program = "+ + * - /";
	var accumulator = 0;

	for token in program {
		match token {
		case '+': accumulator += 1;
		case '-': accumulator -= 1;
		case '*': accumulator *= 2;
		case '/': accumulator /= 2;
		case: // Ignore everything else
		}
	}

	fmt.printf("The program \"%s\" calculates the value %d\n",
	           program, accumulator);
}
*/

