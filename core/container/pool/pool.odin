package container_pool

import "core:fmt"

// Single bit to mark a slot as active
PoolFlag :: bit_set[0..<64;u64]

// Dynamically resizable generic data pool
Pool :: struct($type: typeid) {
    data : [dynamic]type,
    flag : [dynamic]PoolFlag,
    free : [dynamic]int
}

// Reserve memory for the pool
init :: proc($type: typeid, data_cnt : uint, free_cnt : uint = 8) -> Pool(type) {
    pool : Pool(type)
    reserve(&pool.data, data_cnt)
    reserve(&pool.flag, (data_cnt / 64) + 1)
    reserve(&pool.free, free_cnt)
    return pool
}

is_index_valid :: proc(pool : ^Pool($T), index : int) -> (is_valid : bool) {
    if index >= 0 && index < len(pool.data) {
        flag := pool.flag[index / 64]
        
        is_valid = index % 64 in flag
    }
    return
}

active_count :: proc(pool : ^Pool($T)) -> int {
    total : int
    for f in pool.flag do total += card(f)
    return total
}

get_ref :: proc(pool : ^Pool($T), #any_int index : int, loc := #caller_location ) -> (value : ^T = nil, ok : bool) #optional_ok {
    if is_index_valid(pool, index) {
        value = &pool.data[index]
        ok = true
    } else {
        fmt.eprintfln("%v: Index is out of bounds", loc)
    }
    return
}

get_value :: proc(pool : ^Pool($T), #any_int index : int, loc := #caller_location ) -> (value : T, ok : bool) #optional_ok {
    if is_index_valid(pool, index) {
        value = pool.data[index]
        ok = true
    } else {
        fmt.eprintfln("%v: Index is out of bounds", loc)
    }
    return
}

insert :: proc(pool : ^Pool($T), value: T) -> int {
    idx : int = -1
    if len(pool.free) > 0 {
        idx = pop(&pool.free)
        pool.data[idx] = value
    } else {
        idx = len(pool.data)
        append(&pool.data, value)
        
        // If we're out of flags, add a new set
        if (idx / 64) + 1 > len(pool.flag) do append(&pool.flag, PoolFlag{})
    }

    // Get the flag set, then mark the slot as active
    flag_set  := &pool.flag[idx / 64]
    flag_set^ += PoolFlag{idx % 64}

    return idx
}

remove :: proc(pool : ^Pool($T), #any_int index : int, loc := #caller_location ) {
    if is_index_valid(pool, index) {
        pool.data[index] = 0
        append(&pool.free, index)

        // Get the flag set, then invalidate the active flag
        flag_set  := &pool.flag[index / 64]
        flag_set^ -= PoolFlag{index % 64}
    } else {
        fmt.eprintfln("%v: Index is out of bounds", loc)
    }
}

destroy :: proc(pool : ^Pool($T)) {
    delete(pool.data)
    delete(pool.flag)
    delete(pool.free)
}
