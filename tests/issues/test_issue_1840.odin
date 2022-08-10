// Tests issue #1840 https://github.com/odin-lang/Odin/issues/1840
package test_issues

import "core:fmt"
import "core:testing"
import tc "tests:common"

main :: proc() {
    t := testing.T{}

	test_orig()

    test_f32(&t)
    test_f64(&t)

	tc.report(&t)
}

/* Original issue #1840 example */

// Compilation fails with invalid LLVM code gen.
@test
test_orig :: proc() {
    r := u32(3)
    a := f32(1.0)
    x := a * (1>>r)
}

@test
test_f32 :: proc(t: ^testing.T) {
    r := u32(2)
    a := f32(1.0)

    // Unsigned const should result in unsigned shift
    xs := a * ((-1)>>r)
    xe_expect := f32(i32(-1)>>r)
    tc.expect(t, xs == xe_expect, fmt.tprintf("%s: %f != %f \n", #procedure, xs, xe_expect))

    // Signed const should result in signed shift
    xu := a * (0xffffffff>>r)
    xu_expect := f32(u32(0xffffffff)>>r)
    tc.expect(t, xu == xu_expect, fmt.tprintf("%s: %f != %f \n", #procedure, xu, xu_expect))
}

@test
test_f64 :: proc(t: ^testing.T) {
    r := u64(2)
    a := f64(1.0)

    // Unsigned const should result in unsigned shift
    xs := a * ((-1)>>r)
    xe_expect := f64(i64(-1)>>r)
    tc.expect(t, xs == xe_expect, fmt.tprintf("%s: %f != %f \n", #procedure, xs, xe_expect))

    // Signed const should result in signed shift
    xu := a * (0xffffffffffffffff>>r)
    xu_expect := f64(u64(0xffffffffffffffff)>>r)
    tc.expect(t, xu == xu_expect, fmt.tprintf("%s: %f != %f \n", #procedure, xu, xu_expect))
}