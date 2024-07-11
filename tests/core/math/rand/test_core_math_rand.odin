package test_core_math_rand

import "core:math/rand"
import "core:testing"

@test
test_default_rand_determinism :: proc(t: ^testing.T) {
	rand.reset(13)
	first_value := rand.int127()
	rand.reset(13)
	second_value := rand.int127()

	testing.expect(t, first_value == second_value, "Context default random number generator is non-deterministic.")
}

@test
test_default_rand_determinism_user_set :: proc(t: ^testing.T) {
	rng_state_1 := rand.create(13)
	rng_state_2 := rand.create(13)

	rng_1 := rand.default_random_generator(&rng_state_1)
	rng_2 := rand.default_random_generator(&rng_state_2)

	first_value, second_value: i128
	{
		context.random_generator = rng_1
		first_value = rand.int127()
	}
	{
		context.random_generator = rng_2
		second_value = rand.int127()
	}

	testing.expect(t, first_value == second_value, "User-set default random number generator is non-deterministic.")
}
