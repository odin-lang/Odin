package foo

import "core:math/linalg"
import "core:time"
import "core:math/rand"
import "core:math"
import "core:fmt"

dump_val :: proc(x: $T, msg := "x", expr := #caller_expression(x)) {
    fmt.printfln("{} = {} = {}", msg, expr, x)
}

main :: proc() {
    benchmark()
}

N :: 10_000_000
buf: [1024 * 32]f32

benchmark :: proc() {
    state := rand.create(1234567899999)
    context.random_generator = rand.default_random_generator(&state)
    for &it in buf {
        it = rand.float32()
    }

    start := time.tick_now()

    sum: f32    
    for i in 0..<N {
        index := i % len(buf)
        
        PRINT :: 100_000
        // if i % PRINT == 0 do fmt.println(i / PRINT)
        
        val := buf[index]
        defer buf[index] = val
        
        val += math.sin_f32(val)
        val += math.cos_f32(val)
        val += linalg.fract(math.tan_f32(linalg.fract(val)))
        val -= math.asin_f32(linalg.fract(val))
        val *= 1.0 + math.exp_f32(-val)
        val = math.pow(val, 1 + linalg.fract(val))
        val += math.ln_f32(abs(val) + 1)
        // val *= math.gamma_f32(abs(val))
        
        sum += val
    }
    
    fmt.printfln("Duration: %.6f s", time.duration_seconds(time.tick_since(start)))
    // fmt.printfln("sum: {}", sum)
}