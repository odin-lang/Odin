package test_issues

Value :: union {
    int,
    f32,
    string,
}

Inner :: struct {
    value:    Value,
    padding0: int,
    padding1: int,
}

Outer :: struct {
    using inner: Inner,
}

consume :: proc(value: Outer) {
    _ = value
}

main :: proc() {
    consume({value = Value(int(1))})
}
