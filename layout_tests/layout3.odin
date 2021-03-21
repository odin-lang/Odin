package test

import "core:fmt"

Test :: struct
{
	type: i32,
	serial: i64
};

main :: proc() {
	t : Test;
	fmt.println("type offset", cast(uintptr)&t - cast(uintptr)&t.type );
	fmt.println("serial offset", cast(uintptr)&t.serial - cast(uintptr)&t);

	fmt.println("type   address", cast(uintptr)&t.type - cast(uintptr)&t);
	fmt.println("serial address", cast(uintptr)&t.serial - cast(uintptr)&t);
}