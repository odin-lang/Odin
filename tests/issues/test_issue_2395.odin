// Tests issue #2395 https://github.com/odin-lang/Odin/issues/2395

// Ensures that we no longer raise the faulty error for #no_nil unions when
// then are 2 variants with the polymorphic type. Also ensure that we raise
// exactly 2 errors from the invalid unions
package test_issues

ValidUnion :: union($T: typeid) #no_nil {
    T,
    f32,
}

OtherValidUnion :: union($T: typeid, $S: typeid) #no_nil {
    T,
    S,
}

InvalidUnion :: union($T: typeid) #no_nil {
    T,
}

OtherInvalidUnion :: union($T: typeid) #no_nil {
    u8,
}

main :: proc() {
}
