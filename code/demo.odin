import (
	"fmt.odin";
	"atomics.odin";
	"bits.odin";
	"decimal.odin";
	"hash.odin";
	"math.odin";
	"mem.odin";
	"opengl.odin";
	"os.odin";
	"raw.odin";
	"strconv.odin";
	"strings.odin";
	"sync.odin";
	"types.odin";
	"utf8.odin";
	"utf16.odin";
/*
*/
)


general_stuff :: proc() {
	// Complex numbers
	a := 3 + 4i;
	b: complex64 = 3 + 4i;
	c: complex128 = 3 + 4i;
	d := complex(2, 3);

	e := a / conj(a);
	fmt.println("(3+4i)/(3-4i) =", e);
	fmt.println(real(e), "+", imag(e), "i");


	// C-style variadic procedures
	foreign __llvm_core {
		// The variadic part allows for extra type checking too which C does not provide
		c_printf :: proc(fmt: ^u8, #c_vararg args: ..any) -> i32 #link_name "printf" ---;
	}
	str := "%d\n";
	c_printf(&str[0], i32(789456123));


	Foo :: struct {
		x: int,
		y: f32,
		z: string,
	}
	foo := Foo{123, 0.513, "A string"};
	x, y, z := expand_to_tuple(foo);
	fmt.println(x, y, z);
	compile_assert(type_of(x) == int);
	compile_assert(type_of(y) == f32);
	compile_assert(type_of(z) == string);


	// By default, all variables are zeroed
	// This can be overridden with the "uninitialized value"
	// This is similar to `nil` but applied to everything
	undef_int: int = ---;


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

foreign_blocks :: proc() {
	// See sys/windows.odin
}

default_arguments :: proc() {
	hello :: proc(a: int = 9, b: int = 9) do fmt.printf("a is %d; b is %d\n", a, b);
	fmt.println("\nTesting default arguments:");
	hello(1, 2);
	hello(1);
	hello();
}

named_arguments :: proc() {
	Colour :: enum {
		Red,
		Orange,
		Yellow,
		Green,
		Blue,
		Octarine,
	};
	using Colour;

	make_character :: proc(name, catch_phrase: string, favourite_colour, least_favourite_colour: Colour) {
	    fmt.println();
	    fmt.printf("My name is %v and I like %v.  %v\n", name, favourite_colour, catch_phrase);
	}

	make_character("Frank", "¡Ay, caramba!", Blue, Green);


	// As the procedures have more and more parameters, it is very easy
	// to get many of the arguments in the wrong order especialy if the
	// types are the same
	make_character("¡Ay, caramba!", "Frank", Green, Blue);

	// Named arguments help to disambiguate this problem
	make_character(catch_phrase = "¡Ay, caramba!", name = "Frank",
	               least_favourite_colour = Green, favourite_colour = Blue);


	// The named arguments can be specifed in any order.
	make_character(favourite_colour = Octarine, catch_phrase = "U wot m8!",
	               least_favourite_colour = Green, name = "Dennis");


	// NOTE: You cannot mix named arguments with normal values
	/*
	make_character("Dennis",
	               favourite_colour = Octarine, catch_phrase = "U wot m8!",
	               least_favourite_colour = Green);
	*/


	// Named arguments can also aid with default arguments
	numerous_things :: proc(s: string, a := 1, b := 2, c := 3.14,
	                     d := "The Best String!", e := false, f := 10.3/3.1, g := false) {
		g_str := g ? "true" : "false";
		fmt.printf("How many?! %s: %v\n", s, g_str);
	}

	numerous_things("First");
	numerous_things(s = "Second", g = true);


	// Default values can be placed anywhere, not just at the end like in other languages
	weird :: proc(pre: string, mid: int = 0, post: string) {
		fmt.println(pre, mid, post);
	}

	weird("How many things", 42, "huh?");
	weird(pre = "Prefix", post = "Pat");

}


default_return_values :: proc() {
	foo :: proc(x: int) -> (first: string = "Hellope", second := "world!") {
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
	Error :: enum {
		None,
		WhyTheNumberThree,
		TenIsTooBig,
	};

	Entity :: struct {
		name: string,
		id:   u32,
	}

	some_thing :: proc(input: int) -> (result: ^Entity = nil, err := Error.None) {
		match {
		case input == 3:  return err = Error.WhyTheNumberThree;
		case input >= 10: return err = Error.TenIsTooBig;
		}

		e := new(Entity);
		e.id = u32(input);

		return result = e;
	}
}

call_location :: proc() {
	amazing :: proc(n: int, using loc := #caller_location) {
		fmt.printf("%s(%d:%d) just asked to do something amazing.\n",
		           fully_pathed_filename, line, column);
		fmt.printf("Normal -> %d\n", n);
		fmt.printf("Amazing -> %d\n", n+1);
		fmt.println();
	}

	loc := #location(main);
	fmt.println("`main` is located at", loc);

	fmt.println("This line is located at", #location());
	fmt.println();

	amazing(3);
	amazing(4, #location(call_location));

	// See _preload.odin for the implementations of `assert` and `panic`

}


explicit_parametric_polymorphic_procedures :: proc() {
	// This is how `new` is actually implemented, see _preload.odin
	alloc_type :: proc(T: type) -> ^T do return ^T(alloc(size_of(T), align_of(T)));

	int_ptr := alloc_type(int);
	defer free(int_ptr);
	int_ptr^ = 137;
	fmt.println(int_ptr, int_ptr^);

	// Named arguments work too!
	another_ptr := alloc_type(T = f32);
	defer free(another_ptr);


	add :: proc(T: type, args: ..T) -> T {
		res: T;
		for arg in args do res += arg;
		return res;
	}

	fmt.println("add =", add(int, 1, 2, 3, 4, 5, 6));

	swap :: proc(T: type, a, b: ^T) {
		tmp := a^;
		a^ = b^;
		b^ = tmp;
	}

	a, b: int = 3, 4;
	fmt.println("Pre-swap:", a, b);
	swap(int, &a, &b);
	fmt.println("Post-swap:", a, b);
	a, b = b, a; // Or use this syntax for this silly example case






	// A more complicated example using subtyping
	// Something like this could be used in a game
	Vector2 :: struct {x, y: f32};

	Entity :: struct {
		using position: Vector2,
		flags:          u64,
		id:             u64,
		batch_index:    u32,
		slot_index:     u32,
		portable_id:    u32,
		derived:        any,
	}

	Rock :: struct {
		using entity: ^Entity,
		heavy: bool,
	}
	Door :: struct {
		using entity: ^Entity,
		open:         bool,
	}
	Monster :: struct {
		using entity: ^Entity,
		is_robot:     bool,
		is_zombie:    bool,
	}

	EntityManager :: struct {
		batches: [dynamic]^EntityBatch,
		next_portable_id: u32,
	}

	ENTITIES_PER_BATCH :: 16;
	EntityBatch :: struct {
		data:        [ENTITIES_PER_BATCH]Entity,
		occupied:    [ENTITIES_PER_BATCH]bool,
		batch_index: u32,
	}

	use_empty_slot :: proc(manager: ^EntityManager, batch: ^EntityBatch) -> ^Entity {
		for ok, i in batch.occupied {
			if ok do continue;
			batch.occupied[i] = true;

			e := &batch.data[i];
			e.batch_index = u32(batch.batch_index);
			e.slot_index  = u32(i);
			e.portable_id = manager.next_portable_id;
			manager.next_portable_id++;
			return e;
		}
		return nil;
	}

	gen_new_entity :: proc(manager: ^EntityManager) -> ^Entity {
		for b in manager.batches {
			e := use_empty_slot(manager, b);
			if e != nil do return e;
		}

		new_batch := new(EntityBatch);
		append(&manager.batches, new_batch);
		new_batch.batch_index = u32(len(manager.batches)-1);

		return use_empty_slot(manager, new_batch);
	}



	new_entity :: proc(manager: ^EntityManager, T: type, x, y: f32) -> ^T {
		result := new(T);
		result.entity = gen_new_entity(manager);
		result.derived.data = result;
		result.derived.type_info = type_info(T);

		result.position.x = x;
		result.position.y = y;

		return result;
	}

	manager: EntityManager;
	entities: [dynamic]^Entity;

	rock    := new_entity(&manager, Rock, 3, 5);

	// Named arguments work too!
	door    := new_entity(manager = &manager, T = Door, x = 3, y = 6);

	// And named arguments can be any order
	monster := new_entity(
		y = 1,
		x = 2,
		manager = &manager,
		T = Monster,
	);

	append(&entities, rock, door, monster);

	// An alternative to `union`s
	for entity in entities {
		match e in entity.derived {
		case Rock:    fmt.println("Rock",    e.portable_id, e.x, e.y);
		case Door:    fmt.println("Door",    e.portable_id, e.x, e.y);
		case Monster: fmt.println("Monster", e.portable_id, e.x, e.y);
		}
	}
}


pop :: proc(array: ^[]$T) -> T {
	last: T;
	if len(array) == 0 {
		panic("Attempt to pop an empty slice");
		return last;
	}

	last = array[len(array)-1];
	^raw.Slice(array).len -= 1;
	return last;
}
pop :: proc(a: ^[dynamic]$T) -> T {
	last: T;
	if len(a) == 0 {
		panic("Attempt to pop an empty dynamic array");
		return last;
	}

	last = array[len(array)-1];
	^raw.DynamicArray(array).len -= 1;
	return last;
}


main :: proc() {
when true {
	foo :: proc(x: i64,  y: f32) do fmt.println("#1", x, y);
	foo :: proc(x: type, y: f32) do fmt.println("#2", type_info(x), y);
	foo :: proc(x: type)         do fmt.println("#3", type_info(x));

	f :: foo;

	f(y = 3785.1546, x = 123);
	f(x = int, y = 897.513);
	f(x = f32);
	general_stuff();
	foreign_blocks();
	default_arguments();
	named_arguments();
	default_return_values();
	call_location();
	explicit_parametric_polymorphic_procedures();

	// Command line argument(s)!
	// -opt=0,1,2,3

	program := "+ + * - /";
	accumulator := 0;

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
}




