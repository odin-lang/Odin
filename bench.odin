package bench

import "core:slice"
import "core:math/rand"
import "core:time"
import "core:fmt"

T :: u64

benchmark_sort :: proc(num: int) -> f64 {
    data := make([]T, num)
    defer delete(data)
    for &x in data {
        x = T(rand.uint64())
    }
    
    start := time.tick_now()
    
    slice.sort(data)
    
    return time.duration_milliseconds(time.tick_since(start))
}

benchmark_sort_with_indices :: proc(num: int) -> f64 {
    data := make([]T, num)
    defer delete(data)
    for &x in data {
        x = T(rand.uint64())
    }
    
    start := time.tick_now()
    
    // Important: includes 'sort_from_permutation_indices'
    indices := slice.sort_with_indices(data)
    
    return time.duration_milliseconds(time.tick_since(start))
}

benchmark_proc :: proc(num: int, bench: proc(int) -> f64, expr := #caller_expression(bench)) {

    ITERS :: 10
    min_dur := max(f64)
    max_dur := min(f64)
    sum_dur: f64
    for i in 0..<ITERS {
        dur := bench(num)
        min_dur = min(min_dur, dur)
        max_dur = max(max_dur, dur)
        sum_dur += dur
    }
    
    // fmt.printfln("[%s] num: %i, avg ms: %.5f, min: %.5f, max: %.5f", expr, num, sum_dur / ITERS, min_dur, max_dur)
    fmt.printfln("%i, %.5f, %.5f, %.5f", num, sum_dur / ITERS, min_dur, max_dur)
}

main :: proc() {
    fmt.println("Running...")
    benchmark_proc(1000, benchmark_sort)
    
    
    fmt.printfln("\nnum, avg, min, max")
    for i in 1..=1000 {
        benchmark_proc(1000 * i, benchmark_sort)
    }
    // for i in 1..=uint(16) {
    //     benchmark_proc(1 << i, benchmark_sort_with_indices)
    // }
    fmt.println("Done")
}