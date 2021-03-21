package main

import "core:fmt"

E :: enum {
    zero = 0,
    one = 1,
    two = 2,
}

A :: struct {
    e: E,
    b1: bool,
    a: int,
    b2: bool,
}

B :: struct {
    a: A,
    d: []byte,
}

bad :: proc(buffer: []byte) -> (B, bool, []byte) {
    a := A{
        e= .one,
        b1= true,
        a= 7,
        b2= true,
    };

    b: B;
    b.a = a;
    b.d = buffer[:];

    fmt.println("inside bad:", b);
    return b, true, buffer[:];
}

main :: proc() {
    data := make([]byte, 17);
    for _, k in data {
        data[k] = 7;
    }
    b, _, _ := bad(data);
    fmt.println("after return:", b);
}