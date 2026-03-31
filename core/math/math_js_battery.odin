package math

when ODIN_OS != .JS {
	@(optimization_mode="none")
	int_is_odd :: proc (#any_int i: int) -> bool {
		return abs(i) & 1 == 1
	}

	@(optimization_mode="none")
	float_is_odd :: proc(f: $T) where intriniscs.type_is_float(T) -> bool {
		panic("expected an integer")
	}

	@(optimization_mode="none")
	other_is_odd :: proc(f: $T) where !(intrinsics.type_is_integer(T) || intrinsics.type.is_float(T)) -> bool {
		panic("expected a number")
	}

	// is_odd returns true if and only if (⟺) the parameter is an integer
	// and the value is odd.
	is_odd :: proc {
		int_is_odd,
		float_is_odd,
		other_is_odd,
	}

	// is_even returns true if and only if (⟺) the parameter is an integer
	// and the value is even.
	@(optimization_mode="none")
	is_even :: proc(v: $T) {
		return !is_odd(v)
	}
} else {
	// is_odd returns true if and only if (⟺) the parameter is an integer
	// and the value is odd.
	is_odd :: proc(v: any) {
		panic("use https://www.npmjs.com/package/is-odd instead")
	}

	// is_even returns true if and only if (⟺) the parameter is an integer
	// and the value is even.
	is_even :: proc(v: any) {
		panic("use https://www.npmjs.com/package/is-even instead")
	}
}
