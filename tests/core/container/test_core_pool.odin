package test_core_container

import "core:testing"
import "core:pool"

import "core:fmt"

@test
test_pool_type :: proc(t: ^testing.T) {
    v := pool.init(rune, 4)
    defer pool.destroy(&v)

    pool.insert(&v, 'a')
    pool.insert(&v, 'b')
    pool.insert(&v, 'c')
    pool.insert(&v, 'd')

    // Test Bounds
    testing.expectf(t, pool.get_ref(&v, -1) == nil, "value should be nil")
    testing.expectf(t, pool.get_ref(&v, 0) != nil, "value should not be nil")
    testing.expectf(t, pool.get_ref(&v, 5) == nil, "value should be nil")

    // Value Check
    rune_ref := pool.get_ref(&v, 3)
    rune_ref^ = 'z'
    testing.expectf(t, pool.get_value(&v,3) == 'z', "value should be z")
    
    // Flag Check
    testing.expectf(t, pool.active_count(&v) == 4, "value should be 4")
    pool.remove(&v, 1)
    testing.expectf(t, pool.active_count(&v) == 3, "value should be 3")
    testing.expectf(t, pool.get_ref(&v, 1) == nil, "value should be nil")

    // Insert Check - Make sure it occupies the free slot
    pool.insert(&v, 'b')
    testing.expectf(t, pool.get_value(&v, 1) == 'b', "value should be 'b'")
    testing.expectf(t, pool.active_count(&v) == 4, "value should be 4")

    // Confirm a large number of flags works
    v2 := pool.init(rune, 60)

    defer pool.destroy(&v2)
    for i in 0..<100 {
        pool.insert(&v2, 'o')
    }

    testing.expectf(t, pool.active_count(&v2) == 100, "value should be 100")

    for i := 0; i < 100; i += 2 {
        pool.remove(&v2, i)
    }

    testing.expectf(t, pool.active_count(&v2) == 50, "value should be 50")

    testing.expectf(t, pool.get_value(&v2, 99) == 'o', "value should be 'o'")
    testing.expectf(t, pool.get_ref(&v2, 98) == nil, "value should be nil")
    
}
