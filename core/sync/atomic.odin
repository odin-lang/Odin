package sync

import "base:intrinsics"

/*
This procedure may lower CPU consumption or yield to a hyperthreaded twin
processor. It's exact function is architecture specific, but the intent is to
say that you're not doing much on a CPU.
*/
cpu_relax :: intrinsics.cpu_relax

/*
Describes memory ordering for an atomic operation.

Modern CPU's contain multiple cores and caches specific to those cores. When a
core performs a write to memory, the value is written to cache first. The issue
is that a core doesn't typically see what's inside the caches of other cores.
In order to make operations consistent CPU's implement mechanisms that
synchronize memory operations across cores by asking other cores or by
pushing data about writes to other cores.

Due to how these algorithms are implemented, the stores and loads performed by
one core may seem to happen in a different order to another core. It also may
happen that a core reorders stores and loads (independent of how compiler put
them into the machine code). This can cause issues when trying to synchronize
multiple memory locations between two cores. Which is why CPU's allow for
stronger memory ordering guarantees if certain instructions or instruction
variants are used.

In Odin there are 5 different memory ordering guaranties that can be provided
to an atomic operation:

- `Relaxed`: The memory access (load or store) is unordered with respect to
  other memory accesses. This can be used to implement an atomic counter.
  Multiple threads access a single variable, but it doesn't matter when
  exactly it gets incremented, because it will become eventually consistent.
- `Consume`: No loads or stores dependent on a memory location can be
  reordered before a load with consume memory order. If other threads released
  the same memory, it becomes visible.
- `Acquire`: No loads or stores on a memory location can be reordered before a
  load of that memory location with acquire memory ordering. If other threads
  release the same memory, it becomes visible.
- `Release`: No loads or stores on a memory location can be reordered after a
  store of that memory location with release memory ordering. All threads that
  acquire the same memory location will see all writes done by the current
  thread.
- `Acq_Rel`: Acquire-release memory ordering: combines acquire and release
  memory orderings in the same operation.
- `Seq_Cst`: Sequential consistency. The strongest memory ordering. A load will
  always be an acquire operation, a store will always be a release operation,
  and in addition to that all threads observe the same order of writes.

Non-explicit atomics will always be sequentially consistent.

	Atomic_Memory_Order :: enum {
		Relaxed = 0, // Unordered
		Consume = 1, // Monotonic
		Acquire = 2,
		Release = 3,
		Acq_Rel = 4,
		Seq_Cst = 5,
	}

**Note(i386, x64)**: x86 has a very strong memory model by default. It
guarantees that all writes are ordered, stores and loads aren't reordered. In
a sense, all operations are at least acquire and release operations. If `lock`
prefix is used, all operations are sequentially consistent. If you use explicit
atomics, make sure you have the correct atomic memory order, because bugs likely
will not show up in x86, but may show up on e.g. arm. More on x86 memory
ordering can be found
[[here; https://www.cs.cmu.edu/~410-f10/doc/Intel_Reordering_318147.pdf]]
*/
Atomic_Memory_Order :: intrinsics.Atomic_Memory_Order

/*
Establish memory ordering.

This procedure establishes memory ordering, without an associated atomic
operation.
*/
atomic_thread_fence :: intrinsics.atomic_thread_fence

/*
Establish memory ordering between a current thread and a signal handler.

This procedure establishes memory ordering between a thread and a signal
handler, that run on the same thread, without an associated atomic operation.
This procedure is equivalent to `atomic_thread_fence`, except it doesn't
issue any CPU instructions for memory ordering.
*/
atomic_signal_fence :: intrinsics.atomic_signal_fence

/*
Atomically store a value into memory.

This procedure stores a value to a memory location in such a way that no other
thread is able to see partial reads. This operation is sequentially-consistent.
*/
atomic_store :: intrinsics.atomic_store

/*
Atomically store a value into memory with explicit memory ordering.

This procedure stores a value to a memory location in such a way that no other
thread is able to see partial reads. The memory ordering of this operation is
as specified by the `order` parameter.
*/
atomic_store_explicit :: intrinsics.atomic_store_explicit

/*
Atomically load a value from memory.

This procedure loads a value from a memory location in such a way that the
received value is not a partial read. The memory ordering of this operation is
sequentially-consistent.
*/
atomic_load :: intrinsics.atomic_load

/*
Atomically load a value from memory with explicit memory ordering.

This procedure loads a value from a memory location in such a way that the
received value is not a partial read. The memory ordering of this operation
is as specified by the `order` parameter.
*/
atomic_load_explicit :: intrinsics.atomic_load_explicit

/*
Atomically add a value to the value stored in memory.

This procedure loads a value from memory, adds the specified value to it, and
stores it back as an atomic operation. This operation is an atomic equivalent
of the following:

	dst^ += val

The memory ordering of this operation is sequentially-consistent.
*/
atomic_add :: intrinsics.atomic_add

/*
Atomically add a value to the value stored in memory.

This procedure loads a value from memory, adds the specified value to it, and
stores it back as an atomic operation. This operation is an atomic equivalent
of the following:

	dst^ += val

The memory ordering of this operation is as specified by the `order` parameter.
*/
atomic_add_explicit :: intrinsics.atomic_add_explicit

/*
Atomically subtract a value from the value stored in memory.

This procedure loads a value from memory, subtracts the specified value from it,
and stores the result back as an atomic operation. This operation is an atomic
equivalent of the following:

	dst^ -= val

The memory ordering of this operation is sequentially-consistent.
*/
atomic_sub :: intrinsics.atomic_sub

/*
Atomically subtract a value from the value stored in memory.

This procedure loads a value from memory, subtracts the specified value from it,
and stores the result back as an atomic operation. This operation is an atomic
equivalent of the following:

	dst^ -= val

The memory ordering of this operation is as specified by the `order` parameter.
*/
atomic_sub_explicit :: intrinsics.atomic_sub_explicit

/*
Atomically replace the memory location with the result of AND operation with
the specified value.

This procedure loads a value from memory, calculates the result of AND operation
between the loaded value and the specified value, and stores it back into the
same memory location as an atomic operation. This operation is an atomic
equivalent of the following:

	dst^ &= val

The memory ordering of this operation is sequentially-consistent.
*/
atomic_and :: intrinsics.atomic_and

/*
Atomically replace the memory location with the result of AND operation with
the specified value.

This procedure loads a value from memory, calculates the result of AND operation
between the loaded value and the specified value, and stores it back into the
same memory location as an atomic operation. This operation is an atomic
equivalent of the following:

	dst^ &= val

The memory ordering of this operation is as specified by the `order` parameter.
*/
atomic_and_explicit :: intrinsics.atomic_and_explicit

/*
Atomically replace the memory location with the result of NAND operation with
the specified value.

This procedure loads a value from memory, calculates the result of NAND operation
between the loaded value and the specified value, and stores it back into the
same memory location as an atomic operation. This operation is an atomic
equivalent of the following:

	dst^ = ~(dst^ & val)

The memory ordering of this operation is sequentially-consistent.
*/
atomic_nand :: intrinsics.atomic_nand

/*
Atomically replace the memory location with the result of NAND operation with
the specified value.

This procedure loads a value from memory, calculates the result of NAND operation
between the loaded value and the specified value, and stores it back into the
same memory location as an atomic operation. This operation is an atomic
equivalent of the following:

	dst^ = ~(dst^ & val)

The memory ordering of this operation is as specified by the `order` parameter.
*/
atomic_nand_explicit :: intrinsics.atomic_nand_explicit

/*
Atomically replace the memory location with the result of OR operation with
the specified value.

This procedure loads a value from memory, calculates the result of OR operation
between the loaded value and the specified value, and stores it back into the
same memory location as an atomic operation. This operation is an atomic
equivalent of the following:

	dst^ |= val

The memory ordering of this operation is sequentially-consistent.
*/
atomic_or :: intrinsics.atomic_or

/*
Atomically replace the memory location with the result of OR operation with
the specified value.

This procedure loads a value from memory, calculates the result of OR operation
between the loaded value and the specified value, and stores it back into the
same memory location as an atomic operation. This operation is an atomic
equivalent of the following:

	dst^ |= val

The memory ordering of this operation is as specified by the `order` parameter.
*/
atomic_or_explicit :: intrinsics.atomic_or_explicit

/*
Atomically replace the memory location with the result of XOR operation with
the specified value.

This procedure loads a value from memory, calculates the result of XOR operation
between the loaded value and the specified value, and stores it back into the
same memory location as an atomic operation. This operation is an atomic
equivalent of the following:

	dst^ ~= val

The memory ordering of this operation is sequentially-consistent.
*/
atomic_xor :: intrinsics.atomic_xor

/*
Atomically replace the memory location with the result of XOR operation with
the specified value.

This procedure loads a value from memory, calculates the result of XOR operation
between the loaded value and the specified value, and stores it back into the
same memory location as an atomic operation. This operation is an atomic
equivalent of the following:

	dst^ ~= val

The memory ordering of this operation is as specified by the `order` parameter.
*/
atomic_xor_explicit :: intrinsics.atomic_xor_explicit

/*
Atomically exchange the value in a memory location, with the specified value.

This procedure loads a value from the specified memory location, and stores the
specified value into that memory location. Then the loaded value is returned,
all done in a single atomic operation. This operation is an atomic equivalent
of the following:

	tmp := dst^
	dst^ = val
	return tmp

The memory ordering of this operation is sequentially-consistent.
*/
atomic_exchange :: intrinsics.atomic_exchange

/*
Atomically exchange the value in a memory location, with the specified value.

This procedure loads a value from the specified memory location, and stores the
specified value into that memory location. Then the loaded value is returned,
all done in a single atomic operation. This operation is an atomic equivalent
of the following:

	tmp := dst^
	dst^ = val
	return tmp

The memory ordering of this operation is as specified by the `order` parameter.
*/
atomic_exchange_explicit :: intrinsics.atomic_exchange_explicit

/*
Atomically compare and exchange the value with a memory location.

This procedure checks if the value pointed to by the `dst` parameter is equal
to `old`, and if they are, it stores the value `new` into the memory location,
all done in a single atomic operation. This procedure returns the old value
stored in a memory location and a boolean value signifying whether `old` was
equal to `new`.

This procedure is an atomic equivalent of the following operation:

	old_dst := dst^
	if old_dst == old {
		dst^ = new
		return old_dst, true
	} else {
		return old_dst, false
	}

The strong version of compare exchange always returns true, when the returned
old value stored in location pointed to by `dst` and the `old` parameter are
equal.

Atomic compare exchange has two memory orderings: One is for the
read-modify-write operation, if the comparison succeeds, and the other is for
the load operation, if the comparison fails. The memory ordering for both of
of these operations is sequentially-consistent.
*/
atomic_compare_exchange_strong :: intrinsics.atomic_compare_exchange_strong

/*
Atomically compare and exchange the value with a memory location.

This procedure checks if the value pointed to by the `dst` parameter is equal
to `old`, and if they are, it stores the value `new` into the memory location,
all done in a single atomic operation. This procedure returns the old value
stored in a memory location and a boolean value signifying whether `old` was
equal to `new`.

This procedure is an atomic equivalent of the following operation:

	old_dst := dst^
	if old_dst == old {
		dst^ = new
		return old_dst, true
	} else {
		return old_dst, false
	}

The strong version of compare exchange always returns true, when the returned
old value stored in location pointed to by `dst` and the `old` parameter are
equal.

Atomic compare exchange has two memory orderings: One is for the
read-modify-write operation, if the comparison succeeds, and the other is for
the load operation, if the comparison fails. The memory ordering for these
operations is as specified by `success` and `failure` parameters respectively.
*/
atomic_compare_exchange_strong_explicit :: intrinsics.atomic_compare_exchange_strong_explicit

/*
Atomically compare and exchange the value with a memory location.

This procedure checks if the value pointed to by the `dst` parameter is equal
to `old`, and if they are, it stores the value `new` into the memory location,
all done in a single atomic operation. This procedure returns the old value
stored in a memory location and a boolean value signifying whether `old` was
equal to `new`.

This procedure is an atomic equivalent of the following operation:

	old_dst := dst^
	if old_dst == old {
		// may return false here
		dst^ = new
		return old_dst, true
	} else {
		return old_dst, false
	}

The weak version of compare exchange may return false, even if `dst^ == old`.
On some platforms running weak compare exchange in a loop is faster than a
strong version.

Atomic compare exchange has two memory orderings: One is for the
read-modify-write operation, if the comparison succeeds, and the other is for
the load operation, if the comparison fails. The memory ordering for both
of these operations is sequentially-consistent.
*/
atomic_compare_exchange_weak :: intrinsics.atomic_compare_exchange_weak

/*
Atomically compare and exchange the value with a memory location.

This procedure checks if the value pointed to by the `dst` parameter is equal
to `old`, and if they are, it stores the value `new` into the memory location,
all done in a single atomic operation. This procedure returns the old value
stored in a memory location and a boolean value signifying whether `old` was
equal to `new`.

This procedure is an atomic equivalent of the following operation:

	old_dst := dst^
	if old_dst == old {
		// may return false here
		dst^ = new
		return old_dst, true
	} else {
		return old_dst, false
	}

The weak version of compare exchange may return false, even if `dst^ == old`.
On some platforms running weak compare exchange in a loop is faster than a
strong version.

Atomic compare exchange has two memory orderings: One is for the
read-modify-write operation, if the comparison succeeds, and the other is for
the load operation, if the comparison fails. The memory ordering for these
operations is as specified by the `success` and `failure` parameters
respectively.
*/
atomic_compare_exchange_weak_explicit :: intrinsics.atomic_compare_exchange_weak_explicit