package test_internal

import "base:intrinsics"
import "core:testing"

@(test)
test_intrinsics_enum_is_contiguous :: proc(t: ^testing.T) {
	contiguous :: intrinsics.type_enum_is_contiguous
	testing.expect(t, contiguous(enum { A=0, B=0, C=0 }))
	testing.expect(t, contiguous(enum { A=0, B=1, C=2 }))
	testing.expect(t, contiguous(enum { A=1, B=2, C=2 }))
	testing.expect(t, contiguous(enum { A=-2, B=-1, C=0 }))
	testing.expect(t, contiguous(enum { A=-8, B=-6, C=-7, D=-8 }))
	testing.expect(t, contiguous(enum { C=4, A=3 }))
	testing.expect(t, contiguous(enum { }))
	testing.expect(t, contiguous(enum { A }))
	testing.expect(t, contiguous(enum { Delta=-4 }))
	testing.expect(t, contiguous(enum { X = 2 * len([?]u8{ 0 }) }))
	testing.expect(t, contiguous(enum { Alpha=-2, Beta=-1, Gamma=0, Delta=-3 }))
	
	testing.expect(t, !contiguous(enum { A=1, B=3 }))
	testing.expect(t, !contiguous(enum { B=-5, Beta=-3 }))
	testing.expect(t, !contiguous(enum { A=0, B=-2 }))
}
