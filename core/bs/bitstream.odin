
package bs;

import "core:mem"

BITSTREAM_INITIAL_SIZE: int: 128;
BITSTREAM_GROWTH_RATE:  f64: 2.0;

Bit_Stream :: struct {
    data, head: ^byte,
    size, cap: int,
    
    readonly: bool,
    allocator: mem.Allocator,
}

create :: proc{ create_new, create_from_ptr, create_from_ptr_readonly };

// Creates a new bitstream and allocates an initial buffer
// 0 for initial size == BITSTREAM_INITIAL_SIZE
create_new :: inline proc(auto_cast initial_size: int = 0,
                   allocator := context.allocator) -> Bit_Stream {
    size := initial_size;
    
    if size == 0 {
        size = BITSTREAM_INITIAL_SIZE;
    }
    
    head := cast(^byte) mem.alloc(size, mem.DEFAULT_ALIGNMENT, allocator);
    
    return Bit_Stream{
        head, head,
        0, size,
        false,
        allocator
    };
}

// Creates a bitstream from an existing buffer, allocators must be the same
create_from_ptr :: inline proc "contextless" (auto_cast data: ^byte, auto_cast cap: int,
                                              allocator: mem.Allocator) -> Bit_Stream {
    return Bit_Stream{
        data, data,
        0, cap,
        false,
        allocator
    };
}

// Creates a bitstream from an existing buffer that can only be read
create_from_ptr_readonly :: inline proc "contextless" (auto_cast data: ^byte) -> Bit_Stream {
    return Bit_Stream{
        data, data,
        0, 0,
        true,
        mem.nil_allocator()
    };
}

// Resets the read/write head back to the base
reset :: inline proc "contextless" (bs: ^Bit_Stream) {
    bs.head = bs.data;
}

// Frees the data of the bitstream
delete :: inline proc(bs: ^Bit_Stream) {
    if bs.readonly {
        panic("Can't delete readonly head from a Bit_Stream");
    }
    
    free(bs.data, bs.allocator);
}

// Reads and returns a type
read :: inline proc "contextless" (bs: ^Bit_Stream, $T: typeid) -> T {
    val: T = (cast(^T) bs.head)^;
    bs.head = mem.ptr_offset(bs.head, size_of(T));
    
    return val;
}

// Reads `size` bytes into the `dest` ptr
read_into :: inline proc "contextless" (bs: ^Bit_Stream, auto_cast dest: rawptr, size: int) {
    mem.copy(dest, bs.head, size);
    bs.head = mem.ptr_offset(bs.head, size);
}

write :: proc{ write_value, write_ptr };

// Writes a variable into the stream
write_value :: inline proc(bs: ^Bit_Stream, val: $T) {
    tmp := val;
    write_ptr(bs, &tmp, size_of(T));
}

// Writes `size` bytes of `ptr` into the stream
write_ptr :: proc(bs: ^Bit_Stream, auto_cast ptr: rawptr, auto_cast size: int) {
    if bs.readonly {
        panic("Cannot write into a readonly Bit_Stream");
    }
    
    // Check if we need to grow the buffer
    if bs.size + size > bs.cap {
        old_size := bs.cap;
        bs.cap    = int(f64(bs.cap) * BITSTREAM_GROWTH_RATE);
        bs.data   = cast(^byte) mem.resize(bs.data, old_size,
                                           bs.cap,
                                           mem.DEFAULT_ALIGNMENT, bs.allocator);
        
        bs.head = mem.ptr_offset(bs.data, size);
    }
    
    mem.copy(bs.head, ptr, size);
    bs.head = mem.ptr_offset(bs.head, size);
    bs.size += size;
}
