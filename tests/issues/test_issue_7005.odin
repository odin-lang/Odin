package test_issues

Inner_Left :: enum {
    a,
    b,
}

Inner_Right :: enum {
    c,
    d,
}

Inner :: union {
    Inner_Left,
    Inner_Right,
}

Outer :: union {
    Inner,
    int,
}

Atom :: struct {
    token: Outer,
}

Promoted_Value :: union {
    int,
    f32,
    string,
}

Promoted_Inner :: struct {
    value:    Promoted_Value,
    padding0: int,
    padding1: int,
}

Promoted_Outer :: struct {
    using inner: Promoted_Inner,
}

NAMED_INNER :: Inner(Inner_Left.a)

DIRECT_ATOMS :: [?]Atom{{token = Inner(Inner_Left.a)}}

NAMED_ATOMS :: [?]Atom{{token = NAMED_INNER}}

INDEXED_OUTERS :: [1]Outer {
    0 = Inner(Inner_Left.a),
}

RANGED_OUTERS :: [1]Outer {
    0..=0 = Inner(Inner_Left.a),
}

Outer_Index :: enum {first}

ENUMERATED_OUTERS :: [Outer_Index]Outer {
    .first = Inner(Inner_Left.a),
}

RANGED_ENUMERATED_OUTERS :: [Outer_Index]Outer {
    .first..=.first = Inner(Inner_Left.a),
}

FIXED_CAPACITY_OUTERS :: [dynamic; 1]Outer{
    0 = Inner(Inner_Left.a),
}

RANGED_FIXED_CAPACITY_OUTERS :: [dynamic; 1]Outer{
    0..=0 = Inner(Inner_Left.a),
}

POSITIONAL_FIXED_CAPACITY_OUTERS :: [dynamic; 1]Outer{
    Inner(Inner_Left.a),
}

main :: proc() {
    _ = DIRECT_ATOMS
    _ = NAMED_ATOMS
    _ = INDEXED_OUTERS
    _ = RANGED_OUTERS
    _ = ENUMERATED_OUTERS
    _ = RANGED_ENUMERATED_OUTERS
    _ = FIXED_CAPACITY_OUTERS
    _ = RANGED_FIXED_CAPACITY_OUTERS
    _ = POSITIONAL_FIXED_CAPACITY_OUTERS
    _ = Promoted_Outer {
        value = Promoted_Value(int(1)),
    }
}
