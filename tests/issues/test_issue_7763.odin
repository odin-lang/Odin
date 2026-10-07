package test_issues

import "core:testing"
import "core:encoding/base64"
import "core:slice"

main :: proc() {
	t: testing.T
	test_issue_7763__1eq(&t)
}

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
	input := "==="
	decoded, err := base64.decode(input)
	testing.expect(t, err == nil)
	testing.expect(t, decoded == nil)
}

@(test)
test_issue_7763__4eq :: proc(t: ^testing.T) {
	input := "===="
	decoded, err := base64.decode(input)
	// TODO: Either this should just work, or we should get Invalid_Padding, no? Currently gives Invalid_Character.
	// TODO: Same for 5+ padding chars.
	testing.expect(t, err != nil)
	testing.expect(t, decoded == nil)
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
	input := "QQ==="
	decoded, err := base64.decode(input)
	testing.expect(t, err == nil)
	testing.expect(t, slice.equal(decoded, { 'A' }))
	delete(decoded)
}

@(test)
test_issue_7763__QQ4eq :: proc(t: ^testing.T) {
	input := "QQ===="
	decoded, err := base64.decode(input)
	// TODO: Either this should just work, or we should get Invalid_Padding, no? Currently gives Invalid_Character.
	testing.expect(t, err != nil)
	testing.expect(t, decoded == nil)
}

@(test)
test_issue_7763__QQ6eq :: proc(t: ^testing.T) {
	input := "QQ======"
	decoded, err := base64.decode(input)
	// TODO: Either this should just work, or we should get Invalid_Padding, no? Currently gives Invalid_Character.
	testing.expect(t, err != nil)
	testing.expect(t, decoded == nil)
}

// Strict

@(test)
test_issue_7763__strict_1eq :: proc(t: ^testing.T) {
	input := "="
	decoded, err := base64.decode(input, options = { .Strict })
	testing.expect_value(t, err, .Invalid_Padding)
	testing.expect(t, decoded == nil)
}

@(test)
test_issue_7763__strict_2eq :: proc(t: ^testing.T) {
	input := "=="
	decoded, err := base64.decode(input, options = { .Strict })
	testing.expect_value(t, err, .Invalid_Padding)
	testing.expect(t, decoded == nil)
}

@(test)
test_issue_7763__strict_3eq :: proc(t: ^testing.T) {
	input := "==="
	decoded, err := base64.decode(input, options = { .Strict })
	testing.expect_value(t, err, .Invalid_Padding)
	testing.expect(t, decoded == nil)
}

@(test)
test_issue_7763__strict_4eq :: proc(t: ^testing.T) {
	input := "===="
	decoded, err := base64.decode(input, options = { .Strict })
	testing.expect_value(t, err, .Invalid_Padding)
	testing.expect(t, decoded == nil)
}

@(test)
test_issue_7763__strict_Aeq :: proc(t: ^testing.T) {
	input := "A="
	decoded, err := base64.decode(input, options = { .Strict })
	defer delete(decoded)
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
	delete(decoded)
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
	input := "QQ==="
	decoded, err := base64.decode(input, options = { .Strict })
	testing.expect_value(t, err, .Invalid_Padding)
	testing.expect(t, decoded == nil)
	delete(decoded)
}

@(test)
test_issue_7763__strict_QQ4eq :: proc(t: ^testing.T) {
	input := "QQ===="
	decoded, err := base64.decode(input, options = { .Strict })
	testing.expect_value(t, err, .Invalid_Padding)
	testing.expect(t, decoded == nil)
	delete(decoded)
}

@(test)
test_issue_7763__strict_QQ6eq :: proc(t: ^testing.T) {
	input := "QQ======"
	decoded, err := base64.decode(input, options = { .Strict })
	testing.expect_value(t, err, .Invalid_Padding)
	testing.expect(t, decoded == nil)
	delete(decoded)
}
