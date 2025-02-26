/*
The `mem` package implements various allocators and provides utility procedures
for dealing with memory, pointers and slices.

The documentation below describes basic concepts, applicable to the `mem`
package.

## Pointers, multipointers, and slices

A *pointer* is an abstraction of an *address*, a numberic value representing the
location of an object in memory. That object is said to be *pointed to* by the
pointer. To obtain the address of a pointer, cast it to `uintptr`.

A multipointer is a pointer that points to multiple objects. Unlike a pointer,
a multipointer can be indexed, but does not have a definite length. A slice is
a pointer that points to multiple objects equipped with the length, specifying
the amount of objects a slice points to.

When an object's values are read through a pointer, that operation is called a
*load* operation. When memory is written to through a pointer, that operation is
called a *store* operation. Both of these operations can be called a *memory
access operation*.

## Allocators

In C and C++ memory models, allocations of objects in memory are typically
treated individually with a generic allocator (The `malloc` procedure). Which in
some scenarios can lead to poor cache utilization, slowdowns on individual
objects' memory management and growing complexity of the code needing to keep
track of the pointers and their lifetimes.

Using different kinds of *allocators* for different purposes can solve these
problems. The allocators are typically optimized for specific use-cases and
can potentially simplify the memory management code.

For example, in the context of making a game, having an Arena allocator could
simplify allocations of any temporary memory, because the programmer doesn't
have to keep track of which objects need to be freed every time they are
allocated, because at the end of every frame the whole allocator is reset to
its initial state and all objects are freed at once.

The allocators have different kinds of restrictions on object lifetimes, sizes,
alignment and can be a significant gain, if used properly. Odin supports
allocators on a language level.

Operations such as `new`, `free` and `delete` by default will use
`context.allocator`, which can be overridden by the user. When an override
happens all called procedures will inherit the new context and use the same
allocator.

We will define one concept to simplify the description of some allocator-related
procedures, which is ownership. If the memory was allocated via a specific
allocator, that allocator is said to be the *owner* of that memory region. To
note, unlike Rust, in Odin the memory ownership model is not strict.

## Alignment

An address is said to be *aligned to `N` bytes*, if the addresses's numeric
value is divisible by `N`. The number `N` in this case can be referred to as
the *alignment boundary*. Typically an alignment is a power of two integer
value.

A *natural alignment* of an object is typically equal to its size. For example
a 16 bit integer has a natural alignment of 2 bytes. When an object is not
located on its natural alignment boundary, accesses to that object are
considered *unaligned*.

Some machines issue a hardware **exception**, or experience **slowdowns** when a
memory access operation occurs from an unaligned address. Examples of such
operations are:

- SIMD instructions on x86. These instructions require all memory accesses to be
  on an address that is aligned to 16 bytes.
- On ARM unaligned loads have an extra cycle penalty.

As such, many operations that allocate memory in this package allow to
explicitly specify the alignment of allocated pointers/slices. The default
alignment for all operations is specified in a constant `mem.DEFAULT_ALIGNMENT`.

## Zero by default

Whenever new memory is allocated, via an allocator, or on the stack, by default
Odin will zero-initialize that memory, even if it wasn't explicitly
initialized. This allows for some convenience in certain scenarios and ease of
debugging, which will not be described in detail here.

However zero-initialization can be a cause of slowdowns, when allocating large
buffers. For this reason, allocators have `*_non_zeroed` modes of allocation
that allow the user to request for uninitialized memory and will avoid a
relatively expensive zero-filling of the buffer.

## Naming conventions

The word `size` is used to denote the **size in bytes**. The word `length` is
used to denote the count of objects.

The allocation procedures use the following conventions:

- If the name contains `alloc_bytes` or `resize_bytes`, then the procedure takes
  in slice parameters and returns slices.
- If the procedure name contains `alloc` or `resize`, then the procedure takes
  in a raw pointer and returns raw pointers.
- If the procedure name contains `free_bytes`, then the procedure takes in a
  slice.
- If the procedure name contains `free`, then the procedure takes in a pointer.

Higher-level allocation procedures follow the following naming scheme:

- `new`: Allocates a single object
- `free`: Free a single object (opposite of `new`)
- `make`: Allocate a group of objects
- `delete`: Free a group of objects (opposite of `make`)
*/
package mem
