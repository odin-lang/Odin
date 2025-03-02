
/*
Package core:math/rand implements various random number generators
*/
package rand

import "base:intrinsics"
import "base:runtime"
import "core:math"
import "core:mem"

Generator :: runtime.Random_Generator

Generator_Query_Info :: runtime.Random_Generator_Query_Info

Default_Random_State :: runtime.Default_Random_State
default_random_generator :: runtime.default_random_generator

@(require_results)
create :: proc(seed: u64) -> (state: Default_Random_State) {
	seed := seed
	runtime.default_random_generator_proc(&state, .Reset, ([^]byte)(&seed)[:size_of(seed)])
	return
}

/*
Reset the seed used by the context.random_generator.

Inputs:
- seed: The seed value

Example:
	import "core:math/rand"
	import "core:fmt"

	set_global_seed_example :: proc() {
		rand.reset(1)
		fmt.println(rand.uint64())
	}

Possible Output:

	10
*/
reset :: proc(seed: u64, gen := context.random_generator) {
	runtime.random_generator_reset_u64(gen, seed)
}


reset_bytes :: proc(bytes: []byte, gen := context.random_generator) {
	runtime.random_generator_reset_bytes(gen, bytes)
}

query_info :: proc(gen := context.random_generator) -> Generator_Query_Info {
	return runtime.random_generator_query_info(gen)
}


@(private)
_random_u64 :: proc(gen := context.random_generator) -> (res: u64) {
	ok := runtime.random_generator_read_ptr(gen, &res, size_of(res))
	assert(ok, "uninitialized gen/context.random_generator")
	return
}

/*
Generates a random 32 bit value using the provided random number generator. If no generator is provided the global random number generator will be used.

Returns:
- val: A random unsigned 32 bit value

Example:
	import "core:math/rand"
	import "core:fmt"

	uint32_example :: proc() {
		fmt.println(rand.uint32())
	}

Possible Output:

	10
	389

*/
@(require_results)
uint32 :: proc(gen := context.random_generator) -> (val: u32) { return u32(_random_u64(gen)) }

/*
Generates a random 64 bit value using the provided random number generator. If no generator is provided the global random number generator will be used.

Returns:
- val: A random unsigned 64 bit value

Example:
	import "core:math/rand"
	import "core:fmt"

	uint64_example :: proc() {
		fmt.println(rand.uint64())
	}

Possible Output:

	10
	389

*/
@(require_results)
uint64 :: proc(gen := context.random_generator) -> (val: u64) { return _random_u64(gen) }

/*
Generates a random 128 bit value using the provided random number generator. If no generator is provided the global random number generator will be used.

Returns:
- val: A random unsigned 128 bit value

Example:
	import "core:math/rand"
	import "core:fmt"

	uint128_example :: proc() {
		fmt.println(rand.uint128())
	}

Possible Output:

	10
	389

*/
@(require_results)
uint128 :: proc(gen := context.random_generator) -> (val: u128) {
	a := u128(_random_u64(gen))
	b := u128(_random_u64(gen))
	return (a<<64) | b
}

/*
Generates a random 31 bit value using the provided random number generator. If no generator is provided the global random number generator will be used.  
The sign bit will always be set to 0, thus all generated numbers will be positive.

Returns:
- val: A random 31 bit value

Example:
	import "core:math/rand"
	import "core:fmt"

	int31_example :: proc() {
		fmt.println(rand.int31())
	}

Possible Output:

	10
	389

*/
@(require_results) int31  :: proc(gen := context.random_generator) -> (val: i32)  { return i32(uint32(gen) << 1 >> 1) }

/*
Generates a random 63 bit value using the provided random number generator. If no generator is provided the global random number generator will be used.  
The sign bit will always be set to 0, thus all generated numbers will be positive.

Returns:
- val: A random 63 bit value

Example:
	import "core:math/rand"
	import "core:fmt"

	int63_example :: proc() {
		fmt.println(rand.int63())
	}

Possible Output:

	10
	389

*/
@(require_results) int63  :: proc(gen := context.random_generator) -> (val: i64)  { return i64(uint64(gen) << 1 >> 1) }

/*
Generates a random 127 bit value using the provided random number generator. If no generator is provided the global random number generator will be used.  
The sign bit will always be set to 0, thus all generated numbers will be positive.

Returns:
- val: A random 127 bit value

Example:
	import "core:math/rand"
	import "core:fmt"

	int127_example :: proc() {
		fmt.println(rand.int127())
	}

Possible Output:

	10
	389

*/
@(require_results) int127 :: proc(gen := context.random_generator) -> (val: i128) { return i128(uint128(gen) << 1 >> 1) }

/*
Generates a random 31 bit value in the range `[0, n)` using the provided random number generator. If no generator is provided the global random number generator will be used.

Inputs:
- n: The upper bound of the generated number, this value is exclusive

Returns:
- val: A random 31 bit value in the range `[0, n)`

WARNING: Panics if n is less than 0

Example:
	import "core:math/rand"
	import "core:fmt"

	int31_max_example :: proc() {
		fmt.println(rand.int31_max(16))
	}

Possible Output:

	6
	500

*/
@(require_results)
int31_max :: proc(n: i32, gen := context.random_generator) -> (val: i32) {
	if n <= 0 {
		panic("Invalid argument to int31_max")
	}
	if n&(n-1) == 0 {
		return int31(gen) & (n-1)
	}
	max := i32((1<<31) - 1 - (1<<31)%u32(n))
	v := int31(gen)
	for v > max {
		v = int31(gen)
	}
	return v % n
}

/*
Generates a random 63 bit value in the range `[0, n)` using the provided random number generator. If no generator is provided the global random number generator will be used.

Inputs:
- n: The upper bound of the generated number, this value is exclusive

Returns:
- val: A random 63 bit value in the range `[0, n)`

WARNING: Panics if n is less than 0

Example:
	import "core:math/rand"
	import "core:fmt"

	int63_max_example :: proc() {
		fmt.println(rand.int63_max(16))
	}

Possible Output:

	6
	500

*/
@(require_results)
int63_max :: proc(n: i64, gen := context.random_generator) -> (val: i64) {
	if n <= 0 {
		panic("Invalid argument to int63_max")
	}
	if n&(n-1) == 0 {
		return int63(gen) & (n-1)
	}
	max := i64((1<<63) - 1 - (1<<63)%u64(n))
	v := int63(gen)
	for v > max {
		v = int63(gen)
	}
	return v % n
}

/*
Generates a random 127 bit value in the range `[0, n)` using the provided random number generator. If no generator is provided the global random number generator will be used.

Inputs:
- n: The upper bound of the generated number, this value is exclusive

Returns:
- val: A random 127 bit value in the range `[0, n)`

WARNING: Panics if n is less than 0

Example:
	import "core:math/rand"
	import "core:fmt"

	int127_max_example :: proc() {
		fmt.println(rand.int127_max(16))
	}

Possible Output:

	6
	500

*/
@(require_results)
int127_max :: proc(n: i128, gen := context.random_generator) -> (val: i128) {
	if n <= 0 {
		panic("Invalid argument to int127_max")
	}
	if n&(n-1) == 0 {
		return int127(gen) & (n-1)
	}
	max := i128((1<<127) - 1 - (1<<127)%u128(n))
	v := int127(gen)
	for v > max {
		v = int127(gen)
	}
	return v % n
}

/*
Generates a random integer value in the range `[0, n)` using the provided random number generator. If no generator is provided the global random number generator will be used.

Inputs:
- n: The upper bound of the generated number, this value is exclusive

Returns:
- val: A random integer value in the range `[0, n)`

WARNING: Panics if n is less than 0

Example:
	import "core:math/rand"
	import "core:fmt"

	int_max_example :: proc() {
		fmt.println(rand.int_max(16))
	}

Possible Output:

	6
	500

*/
@(require_results)
int_max :: proc(n: int, gen := context.random_generator) -> (val: int) {
	if n <= 0 {
		panic("Invalid argument to int_max")
	}
	when size_of(int) == 4 {
		return int(int31_max(i32(n), gen))
	} else {
		return int(int63_max(i64(n), gen))
	}
}

/*
Generates a random double floating point value in the range `[0, 1)` using the provided random number generator. If no generator is provided the global random number generator will be used.

Returns:
- val: A random double floating point value in the range `[0, 1)`

Example:
	import "core:math/rand"
	import "core:fmt"

	float64_example :: proc() {
		fmt.println(rand.float64())
	}

Possible Output:

	0.043
	0.511

*/
@(require_results) float64 :: proc(gen := context.random_generator) -> (val: f64) { return f64(int63_max(1<<53, gen)) / (1 << 53) }

/*
Generates a random single floating point value in the range `[0, 1)` using the provided random number generator. If no generator is provided the global random number generator will be used.

Returns:
- val: A random single floating point value in the range `[0, 1)`

Example:
	import "core:math/rand"
	import "core:fmt"

	float32_example :: proc() {
		fmt.println(rand.float32())
	}

Possible Output:

	0.043
	0.511

*/
@(require_results) float32 :: proc(gen := context.random_generator) -> (val: f32) { return f32(int31_max(1<<24, gen)) / (1 << 24) }

/*
Generates a random double floating point value in the range `[low, high)` using the provided random number generator. If no generator is provided the global random number generator will be used.

WARNING: Panics if `high < low`

Inputs:
- low: The lower bounds of the value, this value is inclusive
- high: The upper bounds of the value, this value is exclusive

Returns:
- val: A random double floating point value in the range [low, high)

Example:
	import "core:math/rand"
	import "core:fmt"

	float64_range_example :: proc() {
		fmt.println(rand.float64_range(-10, 300))
	}

Possible Output:

	15.312
	673.130

*/
@(require_results) float64_range :: proc(low, high: f64, gen := context.random_generator) -> (val: f64) {
	assert(low <= high, "low must be lower than or equal to high")
	val = (high-low)*float64(gen) + low
	if val >= high {
		val = max(low, high * (1 - math.F64_EPSILON))
	}
	return
}

/*
Generates a random single floating point value in the range `[low, high)` using the provided random number generator. If no generator is provided the global random number generator will be used.

Inputs:
- low: The lower bounds of the value, this value is inclusive
- high: The upper bounds of the value, this value is exclusive

Returns:
- val: A random single floating point value in the range [low, high)

WARNING: Panics if `high < low`

Example:
	import "core:math/rand"
	import "core:fmt"

	float32_range_example :: proc() {
		fmt.println(rand.float32_range(-10, 300))
	}

Possible Output:

	15.312
	273.130

*/
@(require_results) float32_range :: proc(low, high: f32, gen := context.random_generator) -> (val: f32) {
	assert(low <= high, "low must be lower than or equal to high")
	val = (high-low)*float32(gen) + low
	if val >= high {
		val = max(low, high * (1 - math.F32_EPSILON))
	}
	return
}

/*
Fills a byte slice with random values using the provided random number generator. If no generator is provided the global random number generator will be used.  
Due to floating point precision there is no guarantee if the upper and lower bounds are inclusive/exclusive with the exact floating point value.  

Inputs:
- p: The byte slice to fill

Returns:
- n: The number of bytes generated

Example:
	import "core:math/rand"
	import "core:fmt"

	read_example :: proc() {
		data: [8]byte
		n := rand.read(data[:])
		fmt.println(n)
		fmt.println(data)
	}

Possible Output:

	8
	[32, 4, 59, 7, 1, 2, 2, 119]

*/
@(require_results)
read :: proc(p: []byte, gen := context.random_generator) -> (n: int) {
	pos := i8(0)
	val := i64(0)
	for n = 0; n < len(p); n += 1 {
		if pos == 0 {
			val = int63(gen)
			pos = 7
		}
		p[n] = byte(val)
		val >>= 8
		pos -= 1
	}
	return
}

/*
Creates a slice of `int` filled with random values using the provided random number generator. If no generator is provided the global random number generator will be used.  

*Allocates Using Provided Allocator*

Inputs:
- n: The size of the created slice
- allocator: (default: context.allocator)

Returns:
- res: A slice filled with random values
- err: An allocator error if one occured, `nil` otherwise

Example:
	import "core:math/rand"
	import "core:mem"
	import "core:fmt"

	perm_example :: proc() -> (err: mem.Allocator_Error) {
		data := rand.perm(4) or_return
		fmt.println(data)
		defer delete(data, context.allocator)

		return
	}

Possible Output:

	[7201011, 3, 9123, 231131]
	[19578, 910081, 131, 7]

*/
@(require_results)
perm :: proc(n: int, allocator := context.allocator, gen := context.random_generator) -> (res: []int, err: mem.Allocator_Error) #optional_allocator_error {
	m := make([]int, n, allocator) or_return
	for i := 0; i < n; i += 1 {
		j := int_max(i+1, gen)
		m[i] = m[j]
		m[j] = i
	}
	return m, {}
}

/*
Randomizes the ordering of elements for the provided slice. If no generator is provided the global random number generator will be used.  

Inputs:
- array: The slice to randomize

Example:
	import "core:math/rand"
	import "core:fmt"

	shuffle_example :: proc() {
		data: [4]int = { 1, 2, 3, 4 }
		fmt.println(data) // the contents are in order
		rand.shuffle(data[:])
		fmt.println(data) // the contents have been shuffled
	}

Possible Output:

	[1, 2, 3, 4]
	[2, 4, 3, 1]

*/
shuffle :: proc(array: $T/[]$E, gen := context.random_generator) {
	n := i64(len(array))
	if n < 2 {
		return
	}

	i := n - 1
	for ; i > (1<<31 - 2); i -= 1 {
		j := int63_max(i + 1, gen)
		array[i], array[j] = array[j], array[i]
	}

	for ; i > 0; i -= 1 {
		j := int31_max(i32(i + 1), gen)
		array[i], array[j] = array[j], array[i]
	}
}

/*
Returns a random element from the provided slice. If no generator is provided the global random number generator will be used.  

Inputs:
- array: The slice to choose an element from

Returns:
- res: A random element from `array`

Example:
	import "core:math/rand"
	import "core:fmt"

	choice_example :: proc() {
		data: [4]int = { 1, 2, 3, 4 }
		fmt.println(rand.choice(data[:]))
		fmt.println(rand.choice(data[:]))
		fmt.println(rand.choice(data[:]))
		fmt.println(rand.choice(data[:]))
	}

Possible Output:

	3
	2
	2
	4

*/
@(require_results)
choice :: proc(array: $T/[]$E, gen := context.random_generator) -> (res: E) {
	n := i64(len(array))
	if n < 1 {
		return E{}
	}
	return array[int63_max(n, gen)]
}


@(require_results)
choice_enum :: proc($T: typeid, gen := context.random_generator) -> T where intrinsics.type_is_enum(T) {
	when size_of(T) <= 8 && len(T) == cap(T) {
		when intrinsics.type_is_unsigned(intrinsics.type_core_type(T)) &&
			 u64(max(T)) > u64(max(i64)) {
			i := uint64(gen) % u64(len(T))
			i += u64(min(T))
			return T(i)
		} else {
			i := int63_max(i64(len(T)), gen)
			i += i64(min(T))
			return T(i)
		}
	} else {
		values := runtime.type_info_base(type_info_of(T)).variant.(runtime.Type_Info_Enum).values
		return T(choice(values))
	}
}

/*
Returns a random *set* bit from the provided `bit_set`.

Inputs:
- set: The `bit_set` to choose a random set bit from

Returns:
- res: The randomly selected bit, or the zero value if `ok` is `false`
- ok:  Whether the bit_set was not empty and thus `res` is actually a random set bit

Example:
	import "core:math/rand"
	import "core:fmt"

	choice_bit_set_example :: proc() {
		Flags :: enum {
			A,
			B = 10,
			C,
		}

		fmt.println(rand.choice_bit_set(bit_set[Flags]{}))
		fmt.println(rand.choice_bit_set(bit_set[Flags]{.B}))
		fmt.println(rand.choice_bit_set(bit_set[Flags]{.B, .C}))
		fmt.println(rand.choice_bit_set(bit_set[0..<15]{5, 1, 4}))
	}

Possible Output:
	A false
	B true
	C true
	5 true
*/
@(require_results)
choice_bit_set :: proc(set: $T/bit_set[$E], gen := context.random_generator) -> (res: E, ok: bool) {
	total_set := card(set)
	if total_set == 0 {
		return {}, false
	}

	core_set := transmute(intrinsics.type_bit_set_underlying_type(T))set

	for target := int_max(total_set, gen); target > 0; target -= 1 {
		core_set &= core_set - 1
	}

	return E(intrinsics.count_trailing_zeros(core_set)), true
}
