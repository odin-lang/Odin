package test_issue_7867

// A record's `#align` that took the `offset_of` the record itself recursed without end, as each check of
// the polymorphic `Foo(T)` it names checked that `#align` again, crashing the compiler without a message.
// Taking the `offset_of` a struct within its own declaration passed checking but crashed the backend.
// Each of these must be one error.

Self_Offset :: struct($T: typeid) #align(offset_of(Self_Offset(T), b)) {
	a: T,
	b: int,
}

Self_Offset_By_String :: struct($T: typeid) #align(offset_of_by_string(Self_Offset_By_String(T), "b")) {
	a: T,
	b: int,
}

Self_Offset_Literal :: struct($T: typeid) #align(offset_of(Self_Offset_Literal(T){}.b)) {
	a: T,
	b: int,
}

Self_Offset_Union :: union($T: typeid) #align(offset_of(Self_Offset_Union(T), b)) {
	T,
	int,
}

Self_Offset_Non_Poly :: struct #align(offset_of(Self_Offset_Non_Poly, b)) {
	a: int,
	b: int,
}

Self_Offset_Field :: struct {
	a: u8,
	b: u64,
	c: [offset_of(Self_Offset_Field, b)]u8,
}

Self_Offset_Poly_Field :: struct($T: typeid) {
	a: u8,
	b: T,
	c: [offset_of(Self_Offset_Poly_Field(T), b)]u8,
}

poly_field: Self_Offset_Poly_Field(u32)

// a procedure taking it specializes it with its own parameter again
take_self_offset :: proc(x: Self_Offset($T)) {}
