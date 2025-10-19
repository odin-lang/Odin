package foo

import "core:math"
import "core:fmt"

dump_val :: proc(x: $T, msg := "x", expr := #caller_expression(x)) {
    fmt.printfln("{} = {} = {}", msg, expr, x)
}

main :: proc() {
    dump_val(max(f32))
    dump_val(max(f32) * max(f32))
    dump_val(max(f32) + max(f32))
    dump_val(max(f32) + 1)
    dump_val(math.mod_f32(60, 0))
    // dump_val(math.sqrt(f32(-1)))
    // dump_val(math.ln_f32(f32(0)))
    // f: f32 = 1
    // index: i32 = 0
    // for i in 0..<50 {
    //     fmt.println(i, ":", f, ":", 12345678.0 * f)
        
    //     f /= 10
    // }
}