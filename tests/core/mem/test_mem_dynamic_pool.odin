package test_core_mem

import "core:testing"
import "core:mem"


expect_pool_allocation :: proc(t: ^testing.T, expected_used_bytes, num_bytes, alignment: int) {
    pool: mem.Dynamic_Pool
    mem.dynamic_pool_init(pool = &pool, alignment = alignment)
    pool_allocator := mem.dynamic_pool_allocator(&pool)

    element, err := mem.alloc(num_bytes, alignment, pool_allocator)
    testing.expect(t, err == .None)
    testing.expect(t, element != nil)

    expected_bytes_left := pool.block_size - expected_used_bytes
    testing.expectf(t, pool.bytes_left == expected_bytes_left,
        `
        Allocated data with size %v bytes, expected %v bytes left, got %v bytes left, off by %v bytes.
        Pool:
        block_size = %v
        out_band_size = %v
        alignment = %v
        unused_blocks = %v
        used_blocks = %v
        out_band_allocations = %v
        current_block = %v
        current_pos = %v
        bytes_left = %v
        `,
        num_bytes, expected_bytes_left, pool.bytes_left, expected_bytes_left - pool.bytes_left,
        pool.block_size,
        pool.out_band_size,
        pool.alignment,
        pool.unused_blocks,
        pool.used_blocks,
        pool.out_band_allocations,
        pool.current_block,
        pool.current_pos,
        pool.bytes_left,
    )

    mem.dynamic_pool_destroy(&pool)
    testing.expect(t, pool.used_blocks == nil)
}

expect_pool_allocation_out_of_band :: proc(t: ^testing.T, num_bytes, out_band_size: int) {
    testing.expect(t, num_bytes >= out_band_size, "Sanity check failed, your test call is flawed! Make sure that num_bytes >= out_band_size!")

    pool: mem.Dynamic_Pool
    mem.dynamic_pool_init(pool = &pool, out_band_size = out_band_size)
    pool_allocator := mem.dynamic_pool_allocator(&pool)

    element, err := mem.alloc(num_bytes, allocator = pool_allocator)
    testing.expect(t, err == .None)
    testing.expect(t, element != nil)
    testing.expectf(t, pool.out_band_allocations != nil,
        "Allocated data with size %v bytes, which is >= out_of_band_size and it should be in pool.out_band_allocations, but isn't!",
    )

    mem.dynamic_pool_destroy(&pool)
    testing.expect(t, pool.out_band_allocations == nil)
}

@(test)
test_dynamic_pool_alloc_aligned :: proc(t: ^testing.T) {
    expect_pool_allocation(t, expected_used_bytes = 16, num_bytes = 16, alignment=8)
}

@(test)
test_dynamic_pool_alloc_unaligned :: proc(t: ^testing.T) {
    expect_pool_allocation(t, expected_used_bytes =   8,   num_bytes=1, alignment=8)
    expect_pool_allocation(t, expected_used_bytes =   16,  num_bytes=9, alignment=8)
}

@(test)
test_dynamic_pool_alloc_out_of_band :: proc(t: ^testing.T) {
    expect_pool_allocation_out_of_band(t, num_bytes = 128, out_band_size = 128)
    expect_pool_allocation_out_of_band(t, num_bytes = 129, out_band_size = 128)
}