package test_core_image

import "core:hash/xxhash"
import "core:time"
import "core:testing"
import "core:fmt"

TEST_count := 0
TEST_fail  := 0

when ODIN_TEST {
    expect  :: testing.expect
    log     :: testing.log
} else {
    expect  :: proc(t: ^testing.T, condition: bool, message: string, loc := #caller_location) {
        fmt.printf("[%v] ", loc)
        TEST_count += 1
        if !condition {
            TEST_fail += 1
            fmt.println(" FAIL:", message)
            return
        }
        fmt.println(" PASS")
    }
    log     :: proc(t: ^testing.T, v: any, loc := #caller_location) {
        fmt.printf("[%v] ", loc)
        fmt.printf("log: %v\n", v)
    }
}

main :: proc() {
    t := testing.T{}
    test_benchmark_runner(&t)
    fmt.printf("%v/%v tests successful.\n", TEST_count - TEST_fail, TEST_count)
}

/*
    Benchmarks
*/

setup_xxhash :: proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
    assert(options != nil)

    options.input = make([]u8, options.bytes, allocator)
    return nil if len(options.input) == options.bytes else .Allocation_Error
}

teardown_xxhash :: proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
    assert(options != nil)

    delete(options.input)
    return nil
}

benchmark_xxhash32 :: proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
    buf := options.input

    h: u32
    for _ in 0..=options.rounds {
        h = xxhash.XXH32(buf)
    }
    options.count     = options.rounds
    options.processed = options.rounds * options.bytes
    options.hash      = u128(h)
    return nil
}

benchmark_xxhash64 :: proc(options: ^time.Benchmark_Options, allocator := context.allocator) -> (err: time.Benchmark_Error) {
    buf := options.input

    h: u64
    for _ in 0..=options.rounds {
        h = xxhash.XXH64(buf)
    }
    options.count     = options.rounds
    options.processed = options.rounds * options.bytes
    options.hash      = u128(h)
    return nil
}

benchmark_print :: proc(name: string, options: ^time.Benchmark_Options) {
    fmt.printf("\t[%v] %v rounds, %v bytes procesed in %v ns\n\t\t%5.3f rounds/s, %5.3f MiB/s\n",
        name,
        options.rounds,
        options.processed,
        time.duration_nanoseconds(options.duration),
        options.rounds_per_second,
        options.megabytes_per_second,
    )
}

@test
test_benchmark_runner :: proc(t: ^testing.T) {
    fmt.println("Starting benchmarks:")

    name    := "xxhash32 100 zero bytes"
    options := &time.Benchmark_Options{
        rounds   = 1_000,
        bytes    = 100,
        setup    = setup_xxhash,
        bench    = benchmark_xxhash32,
        teardown = teardown_xxhash,
    }

    err  := time.benchmark(options, context.allocator)
    expect(t, err == nil, name)
    expect(t, options.hash == 0x85f6413c, name)
    benchmark_print(name, options)

    name = "xxhash32 1 MiB zero bytes"
    options.bytes = 1_048_576
    err = time.benchmark(options, context.allocator)
    expect(t, err == nil, name)
    expect(t, options.hash == 0x9430f97f, name)
    benchmark_print(name, options)

    name = "xxhash64 100 zero bytes"
    options.bytes  = 100
    options.bench = benchmark_xxhash64
    err = time.benchmark(options, context.allocator)
    expect(t, err == nil, name)
    expect(t, options.hash == 0x17bb1103c92c502f, name)
    benchmark_print(name, options)

    name = "xxhash64 1 MiB zero bytes"
    options.bytes = 1_048_576
    err = time.benchmark(options, context.allocator)
    expect(t, err == nil, name)
    expect(t, options.hash == 0x87d2a1b6e1163ef1, name)
    benchmark_print(name, options)
}