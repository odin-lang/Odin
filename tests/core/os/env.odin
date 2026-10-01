package tests_core_os

import "base:runtime"
import "core:os"
import "core:testing"
import "core:fmt"

@(test)
test_env_alloc :: proc(t: ^testing.T) {
	// Choose a name that is unlikely to collide with any existing env var on the system.
	TEST_ENV_VAR_NAME :: "ODIN_CORE_TEST_ENVVAR_5464791054"

	{
		val, err := os.lookup_env(TEST_ENV_VAR_NAME, context.temp_allocator)
		testing.expect_value(t, err, os.General_Error.Env_Var_Not_Found)
		testing.expect_value(t, val, "")
	}

	{
		err := os.set_env(TEST_ENV_VAR_NAME, "EnvVarTestValue")
		testing.expect_value(t, err, nil)
	}

	{
		val, err := os.lookup_env(TEST_ENV_VAR_NAME, context.temp_allocator)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, val, "EnvVarTestValue")
	}

	{
		err := os.set_env(TEST_ENV_VAR_NAME, "EnvVarDifferentTestValue")
		testing.expect_value(t, err, nil)
	}

	{
		val, err := os.lookup_env(TEST_ENV_VAR_NAME, context.temp_allocator)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, val, "EnvVarDifferentTestValue")
	}

	{
		success := os.unset_env(TEST_ENV_VAR_NAME)
		testing.expect_value(t, success, true)
	}

	{
		val, err := os.lookup_env(TEST_ENV_VAR_NAME, context.temp_allocator)
		testing.expect_value(t, err, os.General_Error.Env_Var_Not_Found)
		testing.expect_value(t, val, "")
	}
}

@(test)
test_env_buf :: proc(t: ^testing.T) {
	// Choose a name that is unlikely to collide with any existing env var on the system.
	TEST_ENV_VAR_NAME :: "ODIN_CORE_TEST_ENVVAR_5464791055"
	buf: [500]u8

	{
		val, err := os.lookup_env(buf[:], TEST_ENV_VAR_NAME)
		testing.expect_value(t, err, os.General_Error.Env_Var_Not_Found)
		testing.expect_value(t, val, "")
	}

	{
		err := os.set_env(TEST_ENV_VAR_NAME, "EnvVarTestValue")
		testing.expect_value(t, err, nil)
	}

	{
		val, err := os.lookup_env(buf[:], TEST_ENV_VAR_NAME)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, val, "EnvVarTestValue")
	}

	{
		err := os.set_env(TEST_ENV_VAR_NAME, "EnvVarDifferentTestValue")
		testing.expect_value(t, err, nil)
	}

	{
		val, err := os.lookup_env(buf[:], TEST_ENV_VAR_NAME)
		testing.expect_value(t, err, nil)
		testing.expect_value(t, val, "EnvVarDifferentTestValue")
	}

	{
		success := os.unset_env(TEST_ENV_VAR_NAME)
		testing.expect_value(t, success, true)
	}

	{
		val, err := os.lookup_env(buf[:], TEST_ENV_VAR_NAME)
		testing.expect_value(t, err, os.General_Error.Env_Var_Not_Found)
		testing.expect_value(t, val, "")
	}
}

@(test)
test_env_empty_alloc :: proc(t: ^testing.T) {
	val, err := os.lookup_env("", context.temp_allocator)
	testing.expect_value(t, err, os.General_Error.Env_Var_Not_Found)
	testing.expect_value(t, val, "")
}

@(test)
test_env_empty_buf :: proc(t: ^testing.T) {
	buf: [500]u8
	val, err := os.lookup_env(buf[:], "")
	testing.expect_value(t, err, os.General_Error.Env_Var_Not_Found)
	testing.expect_value(t, val, "")
}

@(test)
test_env_allocator_error :: proc(t: ^testing.T) {
	TEST_ENV_VAR_NAME :: "ODIN_CORE_TEST_ENVVAR_5464791056"

	{
		err := os.set_env(TEST_ENV_VAR_NAME, "EnvVarTestValue")
		testing.expect_value(t, err, nil)
	}

	{
		context.allocator = runtime.nil_allocator()
		val, err := os.lookup_env(TEST_ENV_VAR_NAME, context.allocator)
		fmt.printfln("ERR: %v", err)
		testing.expect(t, err != nil)
		testing.expect_value(t, val, "")
	}
}
