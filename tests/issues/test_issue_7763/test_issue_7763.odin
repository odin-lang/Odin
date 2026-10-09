package test_issue_7763

import "core:log"
import "core:testing"
import "core:encoding/base64"
import "core:slice"
import "core:strings"

@(test)
test_issue_7763__nothing :: proc(t: ^testing.T) {
	input := ""
	decoded, err := base64.decode(input)
	testing.expect(t, err == nil)
	testing.expect(t, decoded == nil)
}

@(test)
test_issue_7763__1eq :: proc(t: ^testing.T) {
	input := "="
	decoded, err := base64.decode(input)
	testing.expect(t, err == nil)
	testing.expect(t, decoded == nil)
}

@(test)
test_issue_7763__2eq :: proc(t: ^testing.T) {
	input := "=="
	decoded, err := base64.decode(input)
	testing.expect(t, err == nil)
	testing.expect(t, decoded == nil)
}

@(test)
test_issue_7763__3eq :: proc(t: ^testing.T) {
	for i in 3 ..= 8 {
		input := strings.repeat("=", i, context.temp_allocator)
		// NOTE: Error behavior is not well-defined at this point, but it should not crash and should return an empty slice.
		decoded, err := base64.decode(input)
		if err != nil {
			log.infof("base64 decode %q yielded: %v", input, err)
		}
		testing.expect(t, decoded == nil)
	}
}

@(test)
test_issue_7763__Aeq :: proc(t: ^testing.T) {
	input := "A="
	decoded, err := base64.decode(input)
	testing.expect(t, err == nil)
	testing.expect(t, decoded == nil)
}

@(test)
test_issue_7763__QQ :: proc(t: ^testing.T) {
	input := "QQ"
	decoded, err := base64.decode(input)
	testing.expect(t, err == nil)
	testing.expect(t, slice.equal(decoded, { 'A' }))
	delete(decoded)
}

@(test)
test_issue_7763__QQ1eq :: proc(t: ^testing.T) {
	input := "QQ="
	decoded, err := base64.decode(input)
	testing.expect(t, err == nil)
	testing.expect(t, slice.equal(decoded, { 'A' }))
	delete(decoded)
}

@(test)
test_issue_7763__QQ2eq :: proc(t: ^testing.T) {
	input := "QQ=="
	decoded, err := base64.decode(input)
	testing.expect(t, err == nil)
	testing.expect(t, slice.equal(decoded, { 'A' }))
	delete(decoded)
}

@(test)
test_issue_7763__QQ3eq :: proc(t: ^testing.T) {
	for i in 3 ..= 8 {
		// QQ====[...]
		input := strings.concatenate({ "QQ", strings.repeat("=", i, context.temp_allocator) }, context.temp_allocator)
		// NOTE: Error behavior is not well-defined at this point, but it should not crash, and in case it's successful, it should give 'A'.
		decoded, err := base64.decode(input)
		if err != nil {
			log.infof("base64 decode %q yielded: %v", input, err)
			testing.expect(t, decoded == nil)
		} else {
			testing.expect(t, decoded != nil)
			delete(decoded)
		}
	}
}

// Strict

@(test)
test_issue_7763__strict_eq :: proc(t: ^testing.T) {
	for i in 1 ..= 8 {
		input := strings.repeat("=", i, context.temp_allocator)
		decoded, err := base64.decode(input, options = { .Strict })
		testing.expect_value(t, err, .Invalid_Padding)
		testing.expect(t, decoded == nil)
	}
}

@(test)
test_issue_7763__strict_Aeq :: proc(t: ^testing.T) {
	input := "A="
	decoded, err := base64.decode(input, options = { .Strict })
	testing.expect_value(t, err, .Invalid_Padding)
	testing.expect(t, decoded == nil)
}

@(test)
test_issue_7763__strict_QQ :: proc(t: ^testing.T) {
	input := "QQ"
	decoded, err := base64.decode(input, options = { .Strict })
	testing.expect_value(t, err, .Invalid_Padding)
	testing.expect(t, decoded == nil)
}

@(test)
test_issue_7763__strict_QQ1eq :: proc(t: ^testing.T) {
	input := "QQ="
	decoded, err := base64.decode(input, options = { .Strict })
	testing.expect_value(t, err, .Invalid_Padding)
	testing.expect(t, decoded == nil)
}

@(test)
test_issue_7763__strict_QQ2eq :: proc(t: ^testing.T) {
	input := "QQ=="
	decoded, err := base64.decode(input, options = { .Strict })
	testing.expect(t, err == nil)
	testing.expect(t, slice.equal(decoded, { 'A' }))
	delete(decoded)
}

@(test)
test_issue_7763__strict_QQ3eq :: proc(t: ^testing.T) {
	for i in 3 ..= 8 {
		input := strings.concatenate({ "QQ", strings.repeat("=", i, context.temp_allocator) }, context.temp_allocator)
		decoded, err := base64.decode(input, options = { .Strict })
		testing.expect_value(t, err, .Invalid_Padding)
		testing.expect(t, decoded == nil)
	}
}
