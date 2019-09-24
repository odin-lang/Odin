
package bit_stream;

import "core:mem"

BITSTREAM_INITIAL_SIZE :: 128;
BITSTREAM_GROWTH_RATE  :: 2;

Bit_Stream :: struct {
    data: []byte,
    head, len: int,
    
    readonly: bool,
    allocator: mem.Allocator,
}

create :: proc{ create_new, create_from_ptr, create_from_ptr_readonly };

// Creates a new bitstream and allocates an initial buffer
// <=0 for initial size == BITSTREAM_INITIAL_SIZE
create_new :: inline proc(auto_cast initial_size: int = 0,
                          allocator := context.allocator) -> Bit_Stream {
    size := initial_size;
    
    if size <= 0 {
        size = BITSTREAM_INITIAL_SIZE;
    }
    
    data := make([]byte, size, allocator);
    
    return Bit_Stream{
        data,
        0, 0,
        false,
        allocator
    };
}

// Creates a bitstream from an existing buffer, allocators must be the same
create_from_ptr :: inline proc "contextless" (data: ^byte, auto_cast cap: int,
                                              allocator: mem.Allocator) -> Bit_Stream {
    return Bit_Stream{
        mem.slice_ptr(data, cap),
        0, 0,
        false,
        allocator
    };
}

// Creates a bitstream from an existing buffer that can only be read
create_from_ptr_readonly :: inline proc "contextless" (data: ^byte, auto_cast cap: int) -> Bit_Stream {
    return Bit_Stream{
        mem.slice_ptr(data, cap),
        0, 0,
        true,
        mem.nil_allocator()
    };
}

reset :: inline proc "contextless" (bs: ^Bit_Stream) {
    bs.head = 0;
}

get_data :: inline proc "contextless" (bs: ^Bit_Stream) -> []byte {
    return bs.data[0:bs.len];
}

delete :: inline proc(bs: ^Bit_Stream) {
    if bs.readonly {
        panic("Can't delete readonly Bit_Stream");
    }
    
    mem.delete(bs.data);
}

// Reads and returns a type
read :: inline proc "contextless" (bs: ^Bit_Stream, $T: typeid) -> T {
    assert(bs.head + size_of(T) < len(bs.data), "Trying to read outside of Bit_Stream.data's bounds");
    
    bs.head += size_of(T);
    return (cast(^T) &bs.data[bs.head])^;
}

// Reads `size` bytes into the `dest` ptr
read_into :: inline proc "contextless" (bs: ^Bit_Stream, dest: rawptr,
                                        auto_cast size: int) {
    assert(bs.head + size < len(bs.data), "Trying to read outside of Bit_Stream.data's bounds");
    
    bs.head += size;
    mem.copy(dest, &bs.data[bs.head], size);
}

write :: proc{ write_value, write_ptr };

// Writes a variable into the stream
write_value :: inline proc(bs: ^Bit_Stream, val: $T) {
    tmp := val;
    write_ptr(bs, &tmp, size_of(T));
}

// Writes `size` bytes of `ptr` into the stream
write_ptr :: proc(bs: ^Bit_Stream, ptr: rawptr, auto_cast size: int) {
    if bs.readonly {
        panic("Cannot write into a readonly Bit_Stream");
    }
    
    // Check if we need to grow the buffer
    if bs.len + size > len(bs.data) {
        // Find a capacity that's able to accomodate the new data
        new_cap := len(bs.data);
        for new_cap < bs.len + size {
            new_cap *= BITSTREAM_GROWTH_RATE;
        }
        
        new_data := mem.resize(mem.raw_slice_data(bs.data), len(bs.data), new_cap,
                               mem.DEFAULT_ALIGNMENT, bs.allocator);
        
        bs.data = transmute([]byte)mem.Raw_Slice{
            new_data,
            new_cap
        };
    }
    
    mem.copy(&bs.data[bs.head], ptr, size);
    bs.head += size;
    bs.len  += size;
}
