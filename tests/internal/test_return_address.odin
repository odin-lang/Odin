package test_internal

import "base:intrinsics"
import "core:testing"

@(private="file") HAS_RETURN_ADDRESS            :: ODIN_ARCH != .wasm32 && ODIN_ARCH != .wasm64p32
@(private="file") HAS_LEVELS                    :: HAS_RETURN_ADDRESS && !(ODIN_ARCH == .amd64 && ODIN_OS == .Windows)
@(private="file") HAS_ADDRESS_OF_RETURN_ADDRESS :: ODIN_ARCH == .amd64 || ODIN_ARCH == .i386 || ODIN_ARCH == .arm64

@(private="file")
within :: proc(addr: rawptr, procedure: rawptr) -> bool {
	return uintptr(procedure) < uintptr(addr) && uintptr(addr) < uintptr(procedure) + 4096
}

@(private="file")
leaf_return_address :: #force_no_inline proc() -> rawptr {
	when HAS_RETURN_ADDRESS {
		return intrinsics.return_address()
	} else {
		return nil
	}
}

// the check comes after the call, so it cannot become a tail call
@(private="file")
return_address_is_in_caller :: #force_no_inline proc() -> bool {
	ra := leaf_return_address()
	return within(ra, rawptr(return_address_is_in_caller))
}

// level 1 from here is `mid`'s return address and frame
@(private="file")
leaf_level1 :: #force_no_inline proc() -> (ra, fa: rawptr) {
	when HAS_LEVELS {
		return intrinsics.return_address(1), intrinsics.frame_address(1)
	} else {
		return nil, nil
	}
}

@(private="file")
mid :: #force_no_inline proc() -> (ra, fa, own_fa: rawptr) {
	own_fa = intrinsics.frame_address() // also keeps a frame pointer in `mid`
	ra, fa = leaf_level1()
	return
}

@(private="file")
calls_mid :: #force_no_inline proc() -> (ra_ok, fa_ok: bool) {
	ra, fa, own_fa := mid()
	return within(ra, rawptr(calls_mid)), fa == own_fa
}

@(private="file")
address_of_return_address_holds_it :: #force_no_inline proc() -> bool {
	when HAS_ADDRESS_OF_RETURN_ADDRESS {
		slot := intrinsics.address_of_return_address()
		return slot^ == intrinsics.return_address()
	} else {
		return true
	}
}

@test
test_return_address :: proc(t: ^testing.T) {
	sp := intrinsics.stack_pointer()
	fa := intrinsics.frame_address()
	testing.expect(t, uintptr(sp) <= uintptr(fa) && uintptr(fa) - uintptr(sp) < 1 << 16)

	when HAS_RETURN_ADDRESS {
		testing.expect(t, return_address_is_in_caller())
	}
	when HAS_LEVELS {
		ra_ok, fa_ok := calls_mid()
		testing.expect(t, ra_ok)
		testing.expect(t, fa_ok)
	}
	testing.expect(t, address_of_return_address_holds_it())
}
