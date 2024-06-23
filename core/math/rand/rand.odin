
/*
Package core:math/rand implements various random number generators
*/
package rand

import "base:intrinsics"
import "base:runtime"
import "core:math"
import "core:mem"

Default_Random_State :: runtime.Default_Random_State
default_random_generator :: runtime.default_random_generator

create :: proc(seed: u64) -> (state: Default_Random_State) {
	seed := seed
	runtime.default_random_generator(&state)
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
		rand.set_global_seed(1)
		fmt.println(rand.uint64())
	}

Possible Output:

	10
*/
@(deprecated="Prefer `rand.reset`")
set_global_seed :: proc(seed: u64) {
	runtime.random_generator_reset_u64(context.random_generator, seed)
}

/*
Reset the seed used by the context.random_generator.

Inputs:
- seed: The seed value

Example:
	import "core:math/rand"
	import "core:fmt"

	set_global_seed_example :: proc() {
		rand.set_global_seed(1)
		fmt.println(rand.uint64())
	}

Possible Output:

	10
*/
reset :: proc(seed: u64) {
	runtime.random_generator_reset_u64(context.random_generator, seed)
}


@(private)
_random_u64 :: proc() -> (res: u64) {
	ok := runtime.random_generator_read_ptr(context.random_generator, &res, size_of(res))
	assert(ok, "uninitialized context.random_generator")
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
uint32 :: proc() -> (val: u32) { return u32(_random_u64()) }

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
uint64 :: proc() -> (val: u64) { return _random_u64() }

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
uint128 :: proc() -> (val: u128) {
	a := u128(_random_u64())
	b := u128(_random_u64())
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
@(require_results) int31  :: proc() -> (val: i32)  { return i32(uint32() << 1 >> 1) }

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
@(require_results) int63  :: proc() -> (val: i64)  { return i64(uint64() << 1 >> 1) }

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
@(require_results) int127 :: proc() -> (val: i128) { return i128(uint128() << 1 >> 1) }

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
int31_max :: proc(n: i32) -> (val: i32) {
	if n <= 0 {
		panic("Invalid argument to int31_max")
	}
	if n&(n-1) == 0 {
		return int31() & (n-1)
	}
	max := i32((1<<31) - 1 - (1<<31)%u32(n))
	v := int31()
	for v > max {
		v = int31()
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
int63_max :: proc(n: i64) -> (val: i64) {
	if n <= 0 {
		panic("Invalid argument to int63_max")
	}
	if n&(n-1) == 0 {
		return int63() & (n-1)
	}
	max := i64((1<<63) - 1 - (1<<63)%u64(n))
	v := int63()
	for v > max {
		v = int63()
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
int127_max :: proc(n: i128) -> (val: i128) {
	if n <= 0 {
		panic("Invalid argument to int127_max")
	}
	if n&(n-1) == 0 {
		return int127() & (n-1)
	}
	max := i128((1<<127) - 1 - (1<<127)%u128(n))
	v := int127()
	for v > max {
		v = int127()
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
int_max :: proc(n: int) -> (val: int) {
	if n <= 0 {
		panic("Invalid argument to int_max")
	}
	when size_of(int) == 4 {
		return int(int31_max(i32(n)))
	} else {
		return int(int63_max(i64(n)))
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
@(require_results) float64 :: proc() -> (val: f64) { return f64(int63_max(1<<53)) / (1 << 53) }

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
@(require_results) float32 :: proc() -> (val: f32) { return f32(int31_max(1<<24)) / (1 << 24) }

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
@(require_results) float64_range :: proc(low, high: f64) -> (val: f64) {
	assert(low <= high, "low must be lower than or equal to high")
	val = (high-low)*float64() + low
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
	673.130

*/
@(require_results) float32_range :: proc(low, high: f32) -> (val: f32) {
	assert(low <= high, "low must be lower than or equal to high")
	val = (high-low)*float32() + low
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
read :: proc(p: []byte) -> (n: int) {
	pos := i8(0)
	val := i64(0)
	for n = 0; n < len(p); n += 1 {
		if pos == 0 {
			val = int63()
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
perm :: proc(n: int, allocator := context.allocator) -> (res: []int, err: mem.Allocator_Error) #optional_allocator_error {
	m := make([]int, n, allocator) or_return
	for i := 0; i < n; i += 1 {
		j := int_max(i+1)
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
shuffle :: proc(array: $T/[]$E) {
	n := i64(len(array))
	if n < 2 {
		return
	}

	for i := i64(n - 1); i > 0; i -= 1 {
		j := int63_max(i + 1)
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
choice :: proc(array: $T/[]$E) -> (res: E) {
	n := i64(len(array))
	if n < 1 {
		return E{}
	}
	return array[int63_max(n)]
}


@(require_results)
choice_enum :: proc($T: typeid) -> T
	where
		intrinsics.type_is_enum(T),
		size_of(T) <= 8,
		len(T) == cap(T) /* Only allow contiguous enum types */
{
	when intrinsics.type_is_unsigned(intrinsics.type_core_type(T)) &&
	     u64(max(T)) > u64(max(i64)) {
		i := uint64() % u64(len(T))
		i += u64(min(T))
		return T(i)
	} else {
		i := int63_max(i64(len(T)))
		i += i64(min(T))
		return T(i)
	}
}