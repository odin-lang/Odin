
/*
Package core:math/rand implements various random number generators
*/
package rand

import "base:intrinsics"
import "core:crypto"
import "core:math"
import "core:mem"

Rand :: struct {
	state: u64,
	inc:   u64,
	is_system: bool,
}


@(private)
global_rand := create(u64(intrinsics.read_cycle_counter()))

/*
Sets the seed used by the global random number generator.

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
set_global_seed :: proc(seed: u64) {
	init(&global_rand, seed)
}

/*
Creates a new random number generator.

Inputs:
- seed: The seed value to create the random number generator with

Returns:
- res: The created random number generator

Example:
	import "core:math/rand"
	import "core:fmt"

	create_example :: proc() {
		my_rand := rand.create(1)
		fmt.println(rand.uint64(&my_rand))
	}

Possible Output:

	10

*/
@(require_results)
create :: proc(seed: u64) -> (res: Rand) {
	r: Rand
	init(&r, seed)
	return r
}


/*
Initialises a random number generator.

Inputs:
- r: The random number generator to initialise
- seed: The seed value to initialise this random number generator

Example:
	import "core:math/rand"
	import "core:fmt"

	init_example :: proc() {
		my_rand: rand.Rand
		rand.init(&my_rand, 1)
		fmt.println(rand.uint64(&my_rand))
	}

Possible Output:

	10

*/
init :: proc(r: ^Rand, seed: u64) {
	r.state = 0
	r.inc = (seed << 1) | 1
	_random_u64(r)
	r.state += seed
	_random_u64(r)
}

/*
Initialises a random number generator to use the system random number generator.
The system random number generator is platform specific, and not supported
on all targets.

Inputs:
- r: The random number generator to use the system random number generator

WARNING: Panics if the system random number generator is not supported.
Support can be determined via the `core:crypto.HAS_RAND_BYTES` constant.

Example:
	import "core:crypto"
	import "core:math/rand"
	import "core:fmt"

	init_as_system_example :: proc() {
		my_rand: rand.Rand
		switch crypto.HAS_RAND_BYTES {
		case true:
			rand.init_as_system(&my_rand)
			fmt.println(rand.uint64(&my_rand))
		case false:
			fmt.println("system random not supported!")
		}
	}

Possible Output:

	10

*/
init_as_system :: proc(r: ^Rand) {
	if !crypto.HAS_RAND_BYTES {
		panic(#procedure + " is not supported on this platform yet")
	}
	r.state = 0
	r.inc   = 0
	r.is_system = true
}

@(private)
_random_u64 :: proc(r: ^Rand) -> u64 {
	r := r
	switch {
	case r == nil:
		r = &global_rand
	case r.is_system:
		value: u64
		crypto.rand_bytes((cast([^]u8)&value)[:size_of(u64)])
		return value
	}

	old_state := r.state
	r.state = old_state * 6364136223846793005 + (r.inc|1)
	xor_shifted := (((old_state >> 59) + 5) ~ old_state) * 12605985483714917081
	rot := (old_state >> 59)
	return (xor_shifted >> rot) | (xor_shifted << ((-rot) & 63))
}

/*
Generates a random 32 bit value using the provided random number generator. If no generator is provided the global random number generator will be used.

Inputs:
- r: The random number generator to use, or nil for the global generator

Returns:
- val: A random unsigned 32 bit value

Example:
	import "core:math/rand"
	import "core:fmt"

	uint32_example :: proc() {
		// Using the global random number generator
		fmt.println(rand.uint32())
		// Using local random number generator
		my_rand := rand.create(1)
		fmt.println(rand.uint32(&my_rand))
	}

Possible Output:

	10
	389

*/
@(require_results)
uint32 :: proc(r: ^Rand = nil) -> (val: u32) { return u32(_random_u64(r)) }

/*
Generates a random 64 bit value using the provided random number generator. If no generator is provided the global random number generator will be used.

Inputs:
- r: The random number generator to use, or nil for the global generator

Returns:
- val: A random unsigned 64 bit value

Example:
	import "core:math/rand"
	import "core:fmt"

	uint64_example :: proc() {
		// Using the global random number generator
		fmt.println(rand.uint64())
		// Using local random number generator
		my_rand := rand.create(1)
		fmt.println(rand.uint64(&my_rand))
	}

Possible Output:

	10
	389

*/
@(require_results)
uint64 :: proc(r: ^Rand = nil) -> (val: u64) { return _random_u64(r) }

/*
Generates a random 128 bit value using the provided random number generator. If no generator is provided the global random number generator will be used.

Inputs:
- r: The random number generator to use, or nil for the global generator

Returns:
- val: A random unsigned 128 bit value

Example:
	import "core:math/rand"
	import "core:fmt"

	uint128_example :: proc() {
		// Using the global random number generator
		fmt.println(rand.uint128())
		// Using local random number generator
		my_rand := rand.create(1)
		fmt.println(rand.uint128(&my_rand))
	}

Possible Output:

	10
	389

*/
@(require_results)
uint128 :: proc(r: ^Rand = nil) -> (val: u128) {
	a := u128(_random_u64(r))
	b := u128(_random_u64(r))
	return (a<<64) | b
}

/*
Generates a random 31 bit value using the provided random number generator. If no generator is provided the global random number generator will be used.  
The sign bit will always be set to 0, thus all generated numbers will be positive.

Inputs:
- r: The random number generator to use, or nil for the global generator

Returns:
- val: A random 31 bit value

Example:
	import "core:math/rand"
	import "core:fmt"

	int31_example :: proc() {
		// Using the global random number generator
		fmt.println(rand.int31())
		// Using local random number generator
		my_rand := rand.create(1)
		fmt.println(rand.int31(&my_rand))
	}

Possible Output:

	10
	389

*/
@(require_results) int31  :: proc(r: ^Rand = nil) -> (val: i32)  { return i32(uint32(r) << 1 >> 1) }

/*
Generates a random 63 bit value using the provided random number generator. If no generator is provided the global random number generator will be used.  
The sign bit will always be set to 0, thus all generated numbers will be positive.

Inputs:
- r: The random number generator to use, or nil for the global generator

Returns:
- val: A random 63 bit value

Example:
	import "core:math/rand"
	import "core:fmt"

	int63_example :: proc() {
		// Using the global random number generator
		fmt.println(rand.int63())
		// Using local random number generator
		my_rand := rand.create(1)
		fmt.println(rand.int63(&my_rand))
	}

Possible Output:

	10
	389

*/
@(require_results) int63  :: proc(r: ^Rand = nil) -> (val: i64)  { return i64(uint64(r) << 1 >> 1) }

/*
Generates a random 127 bit value using the provided random number generator. If no generator is provided the global random number generator will be used.  
The sign bit will always be set to 0, thus all generated numbers will be positive.

Inputs:
- r: The random number generator to use, or nil for the global generator

Returns:
- val: A random 127 bit value

Example:
	import "core:math/rand"
	import "core:fmt"

	int127_example :: proc() {
		// Using the global random number generator
		fmt.println(rand.int127())
		// Using local random number generator
		my_rand := rand.create(1)
		fmt.println(rand.int127(&my_rand))
	}

Possible Output:

	10
	389

*/
@(require_results) int127 :: proc(r: ^Rand = nil) -> (val: i128) { return i128(uint128(r) << 1 >> 1) }

/*
Generates a random 31 bit value in the range `[0, n)` using the provided random number generator. If no generator is provided the global random number generator will be used.

Inputs:
- n: The upper bound of the generated number, this value is exclusive
- r: The random number generator to use, or nil for the global generator

Returns:
- val: A random 31 bit value in the range `[0, n)`

WARNING: Panics if n is less than 0

Example:
	import "core:math/rand"
	import "core:fmt"

	int31_max_example :: proc() {
		// Using the global random number generator
		fmt.println(rand.int31_max(16))
		// Using local random number generator
		my_rand := rand.create(1)
		fmt.println(rand.int31_max(1024, &my_rand))
	}

Possible Output:

	6
	500

*/
@(require_results)
int31_max :: proc(n: i32, r: ^Rand = nil) -> (val: i32) {
	if n <= 0 {
		panic("Invalid argument to int31_max")
	}
	if n&(n-1) == 0 {
		return int31(r) & (n-1)
	}
	max := i32((1<<31) - 1 - (1<<31)%u32(n))
	v := int31(r)
	for v > max {
		v = int31(r)
	}
	return v % n
}

/*
Generates a random 63 bit value in the range `[0, n)` using the provided random number generator. If no generator is provided the global random number generator will be used.

Inputs:
- n: The upper bound of the generated number, this value is exclusive
- r: The random number generator to use, or nil for the global generator

Returns:
- val: A random 63 bit value in the range `[0, n)`

WARNING: Panics if n is less than 0

Example:
	import "core:math/rand"
	import "core:fmt"

	int63_max_example :: proc() {
		// Using the global random number generator
		fmt.println(rand.int63_max(16))
		// Using local random number generator
		my_rand := rand.create(1)
		fmt.println(rand.int63_max(1024, &my_rand))
	}

Possible Output:

	6
	500

*/
@(require_results)
int63_max :: proc(n: i64, r: ^Rand = nil) -> (val: i64) {
	if n <= 0 {
		panic("Invalid argument to int63_max")
	}
	if n&(n-1) == 0 {
		return int63(r) & (n-1)
	}
	max := i64((1<<63) - 1 - (1<<63)%u64(n))
	v := int63(r)
	for v > max {
		v = int63(r)
	}
	return v % n
}

/*
Generates a random 127 bit value in the range `[0, n)` using the provided random number generator. If no generator is provided the global random number generator will be used.

Inputs:
- n: The upper bound of the generated number, this value is exclusive
- r: The random number generator to use, or nil for the global generator

Returns:
- val: A random 127 bit value in the range `[0, n)`

WARNING: Panics if n is less than 0

Example:
	import "core:math/rand"
	import "core:fmt"

	int127_max_example :: proc() {
		// Using the global random number generator
		fmt.println(rand.int127_max(16))
		// Using local random number generator
		my_rand := rand.create(1)
		fmt.println(rand.int127_max(1024, &my_rand))
	}

Possible Output:

	6
	500

*/
@(require_results)
int127_max :: proc(n: i128, r: ^Rand = nil) -> (val: i128) {
	if n <= 0 {
		panic("Invalid argument to int127_max")
	}
	if n&(n-1) == 0 {
		return int127(r) & (n-1)
	}
	max := i128((1<<127) - 1 - (1<<127)%u128(n))
	v := int127(r)
	for v > max {
		v = int127(r)
	}
	return v % n
}

/*
Generates a random integer value in the range `[0, n)` using the provided random number generator. If no generator is provided the global random number generator will be used.

Inputs:
- n: The upper bound of the generated number, this value is exclusive
- r: The random number generator to use, or nil for the global generator

Returns:
- val: A random integer value in the range `[0, n)`

WARNING: Panics if n is less than 0

Example:
	import "core:math/rand"
	import "core:fmt"

	int_max_example :: proc() {
		// Using the global random number generator
		fmt.println(rand.int_max(16))
		// Using local random number generator
		my_rand := rand.create(1)
		fmt.println(rand.int_max(1024, &my_rand))
	}

Possible Output:

	6
	500

*/
@(require_results)
int_max :: proc(n: int, r: ^Rand = nil) -> (val: int) {
	if n <= 0 {
		panic("Invalid argument to int_max")
	}
	when size_of(int) == 4 {
		return int(int31_max(i32(n), r))
	} else {
		return int(int63_max(i64(n), r))
	}
}

/*
Generates a random double floating point value in the range `[0, 1)` using the provided random number generator. If no generator is provided the global random number generator will be used.

Inputs:
- r: The random number generator to use, or nil for the global generator

Returns:
- val: A random double floating point value in the range `[0, 1)`

Example:
	import "core:math/rand"
	import "core:fmt"

	float64_example :: proc() {
		// Using the global random number generator
		fmt.println(rand.float64())
		// Using local random number generator
		my_rand := rand.create(1)
		fmt.println(rand.float64(&my_rand))
	}

Possible Output:

	0.043
	0.511

*/
@(require_results) float64 :: proc(r: ^Rand = nil) -> (val: f64) { return f64(int63_max(1<<53, r)) / (1 << 53) }

/*
Generates a random single floating point value in the range `[0, 1)` using the provided random number generator. If no generator is provided the global random number generator will be used.

Inputs:
- r: The random number generator to use, or nil for the global generator

Returns:
- val: A random single floating point value in the range `[0, 1)`

Example:
	import "core:math/rand"
	import "core:fmt"

	float32_example :: proc() {
		// Using the global random number generator
		fmt.println(rand.float32())
		// Using local random number generator
		my_rand := rand.create(1)
		fmt.println(rand.float32(&my_rand))
	}

Possible Output:

	0.043
	0.511

*/
@(require_results) float32 :: proc(r: ^Rand = nil) -> (val: f32) { return f32(int31_max(1<<24, r)) / (1 << 24) }

/*
Generates a random double floating point value in the range `[low, high)` using the provided random number generator. If no generator is provided the global random number generator will be used.

WARNING: Panics if `high < low`

Inputs:
- low: The lower bounds of the value, this value is inclusive
- high: The upper bounds of the value, this value is exclusive
- r: The random number generator to use, or nil for the global generator

Returns:
- val: A random double floating point value in the range [low, high)

Example:
	import "core:math/rand"
	import "core:fmt"

	float64_range_example :: proc() {
		// Using the global random number generator
		fmt.println(rand.float64_range(-10, 300))
		// Using local random number generator
		my_rand := rand.create(1)
		fmt.println(rand.float64_range(600, 900, &my_rand))
	}

Possible Output:

	15.312
	673.130

*/
@(require_results) float64_range :: proc(low, high: f64, r: ^Rand = nil) -> (val: f64) {
	assert(low <= high, "low must be lower than or equal to high")
	val = (high-low)*float64(r) + low
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
- r: The random number generator to use, or nil for the global generator

Returns:
- val: A random single floating point value in the range [low, high)

WARNING: Panics if `high < low`

Example:
	import "core:math/rand"
	import "core:fmt"

	float32_range_example :: proc() {
		// Using the global random number generator
		fmt.println(rand.float32_range(-10, 300))
		// Using local random number generator
		my_rand := rand.create(1)
		fmt.println(rand.float32_range(600, 900, &my_rand))
	}

Possible Output:

	15.312
	673.130

*/
@(require_results) float32_range :: proc(low, high: f32, r: ^Rand = nil) -> (val: f32) {
	assert(low <= high, "low must be lower than or equal to high")
	val = (high-low)*float32(r) + low
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
- r: The random number generator to use, or nil for the global generator

Returns:
- n: The number of bytes generated

Example:
	import "core:math/rand"
	import "core:fmt"

	read_example :: proc() {
		// Using the global random number generator
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
read :: proc(p: []byte, r: ^Rand = nil) -> (n: int) {
	pos := i8(0)
	val := i64(0)
	for n = 0; n < len(p); n += 1 {
		if pos == 0 {
			val = int63(r)
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
- r: The random number generator to use, or nil for the global generator
- allocator: (default: context.allocator)

Returns:
- res: A slice filled with random values
- err: An allocator error if one occured, `nil` otherwise

Example:
	import "core:math/rand"
	import "core:mem"
	import "core:fmt"

	perm_example :: proc() -> (err: mem.Allocator_Error) {
		// Using the global random number generator and using the context allocator
		data := rand.perm(4) or_return
		fmt.println(data)
		defer delete(data, context.allocator)

		// Using local random number generator and temp allocator
		my_rand := rand.create(1)
		data_tmp := rand.perm(4, &my_rand, context.temp_allocator) or_return
		fmt.println(data_tmp)

		return
	}

Possible Output:

	[7201011, 3, 9123, 231131]
	[19578, 910081, 131, 7]

*/
@(require_results)
perm :: proc(n: int, r: ^Rand = nil, allocator := context.allocator) -> (res: []int, err: mem.Allocator_Error) #optional_allocator_error {
	m := make([]int, n, allocator) or_return
	for i := 0; i < n; i += 1 {
		j := int_max(i+1, r)
		m[i] = m[j]
		m[j] = i
	}
	return m, {}
}

/*
Randomizes the ordering of elements for the provided slice. If no generator is provided the global random number generator will be used.  

Inputs:
- array: The slice to randomize
- r: The random number generator to use, or nil for the global generator

Example:
	import "core:math/rand"
	import "core:fmt"

	shuffle_example :: proc() {
		// Using the global random number generator
		data: [4]int = { 1, 2, 3, 4 }
		fmt.println(data) // the contents are in order
		rand.shuffle(data[:])
		fmt.println(data) // the contents have been shuffled
	}

Possible Output:

	[1, 2, 3, 4]
	[2, 4, 3, 1]

*/
shuffle :: proc(array: $T/[]$E, r: ^Rand = nil) {
	n := i64(len(array))
	if n < 2 {
		return
	}

	for i := i64(n - 1); i > 0; i -= 1 {
		j := int63_max(i + 1, r)
		array[i], array[j] = array[j], array[i]
	}
}

/*
Returns a random element from the provided slice. If no generator is provided the global random number generator will be used.  

Inputs:
- array: The slice to choose an element from
- r: The random number generator to use, or nil for the global generator

Returns:
- res: A random element from `array`

Example:
	import "core:math/rand"
	import "core:fmt"

	choice_example :: proc() {
		// Using the global random number generator
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
choice :: proc(array: $T/[]$E, r: ^Rand = nil) -> (res: E) {
	n := i64(len(array))
	if n < 1 {
		return E{}
	}
	return array[int63_max(n, r)]
}


@(require_results)
choice_enum :: proc($T: typeid, r: ^Rand = nil) -> T
	where
		intrinsics.type_is_enum(T),
		size_of(T) <= 8,
		len(T) == cap(T) /* Only allow contiguous enum types */
{
	when intrinsics.type_is_unsigned(intrinsics.type_core_type(T)) &&
	     u64(max(T)) > u64(max(i64)) {
		i := uint64(r) % u64(len(T))
		i += u64(min(T))
		return T(i)
	} else {
		i := int63_max(i64(len(T)), r)
		i += i64(min(T))
		return T(i)
	}
}