package main

import "core:fmt"

Foo :: struct {
	call0: proc(f: ^Foo, x: int) -> bool,
	call1: proc(f: Foo,  x: int) -> bool,

	bar: int,
}

test0 :: proc(f: ^Foo, x: int) -> bool {
	fmt.println(#procedure, x);
	return true;
}

test1 :: proc(f: Foo, x: int) -> bool {
	fmt.println(#procedure, x);
	return false;
}

main :: proc() {
	f := &Foo{
		call0 = test0,
		call1 = test1,
	};

	f->call0(123); // f.call0(f,  123);
	f->call1(456); // f.call1(f^, 456);
	f->call0(x=456); // f.call0(f=f, x=456);

	v := Foo{
		call0 = test0,
		call1 = test1,
	};

	v->call0(123); // v.call0(&v, 123);
	v->call1(456); // v.call1(v,  456);
	v->call1(x=456); // f.call1(f=v, x=456);
}
