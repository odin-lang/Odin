package uring

import "core:math"
import "core:sync"
import "core:sys/linux"

DEFAULT_THREAD_IDLE_MS :: 1000
DEFAULT_ENTRIES        :: 32
MAX_ENTRIES            :: 4096

Ring :: struct {
	fd:       linux.Fd,
	sq:       Submission_Queue,
	cq:       Completion_Queue,
	flags:    linux.IO_Uring_Setup_Flags,
	features: linux.IO_Uring_Features,
}

DEFAULT_PARAMS :: linux.IO_Uring_Params {
	sq_thread_idle = DEFAULT_THREAD_IDLE_MS,
}

// Initialize and setup an uring, `entries` must be a power of 2 between 1 and 4096.
init :: proc(ring: ^Ring, params: ^linux.IO_Uring_Params, entries: u32 = DEFAULT_ENTRIES) -> (err: linux.Errno) {
	assert(entries <= MAX_ENTRIES,             "too many entries")
	assert(entries != 0,                       "entries must be positive")
	assert(math.is_power_of_two(int(entries)), "entries must be a power of two")

	fd := linux.io_uring_setup(entries, params) or_return
	defer if err != nil { linux.close(fd) }

	if .SINGLE_MMAP not_in params.features {
		// NOTE: Could support this, but currently isn't.
		err = .ENOSYS
		return
	}

	assert(.CQE32       not_in params.flags,    "unsupported flag") // NOTE: Could support this by making IO_Uring generic.
	assert(.SQE128      not_in params.flags,    "unsupported flag") // NOTE: Could support this by making IO_Uring generic.

	sq := submission_queue_make(fd, params) or_return

	ring.fd = fd
	ring.sq = sq
	ring.cq = completion_queue_make(fd, params, &sq)
	ring.flags = params.flags
	ring.features = params.features

	return
}

destroy :: proc(ring: ^Ring) {
	assert(ring.fd >= 0)
	submission_queue_destroy(&ring.sq)
	linux.close(ring.fd)
	ring.fd = -1
}

// Returns a pointer to a vacant submission queue entry, or nil if the submission queue is full.
// NOTE: extra is so you can make sure there is space for related entries, defaults to 1 so
// a link timeout op can always be added after another.
get_sqe :: proc(ring: ^Ring, extra: int = 1) -> (sqe: ^linux.IO_Uring_SQE, ok: bool) {
	sq := &ring.sq
	head: u32 = sync.atomic_load_explicit(sq.head, .Acquire)
	next := sq.sqe_tail + 1

	if int(next - head) > len(sq.sqes)-extra {
		sqe = nil
		ok = false
		return
	}

	sqe = &sq.sqes[sq.sqe_tail & sq.mask]
	sqe^ = {}

	sq.sqe_tail = next
	ok = true
	return
}

free_space :: proc(ring: ^Ring) -> int {
	sq   := &ring.sq
	head := sync.atomic_load_explicit(sq.head, .Acquire)
	next := sq.sqe_tail + 1
	free := len(sq.sqes) - int(next - head)
	assert(free >= 0)
	return free
}

// Sync internal state with kernel ring state on the submission queue side.
// Returns the number of all pending events in the submission queue.
// Rationale is to determine that an enter call is needed.
flush_sq :: proc(ring: ^Ring) -> (n_pending: u32) {
	sq := &ring.sq
	to_submit := sq.sqe_tail - sq.sqe_head
	if to_submit != 0 {
		tail := sq.tail^
		i: u32 = 0
		for ; i < to_submit; i += 1 {
			sq.array[tail & sq.mask] = sq.sqe_head & sq.mask
			tail += 1
			sq.sqe_head += 1
		}
		sync.atomic_store_explicit(sq.tail, tail, .Release)
	}
	n_pending = sq_ready(ring)
	return
}

// Returns true if we are not using an SQ thread (thus nobody submits but us),
// or if IORING_SQ_NEED_WAKEUP is set and the SQ thread must be explicitly awakened.
// For the latter case, we set the SQ thread wakeup flag.
// Matches the implementation of sq_ring_needs_enter() in liburing.
sq_ring_needs_enter :: proc(ring: ^Ring, flags: ^linux.IO_Uring_Enter_Flags) -> bool {
	assert(flags^ == {})
	if .SQPOLL not_in ring.flags { return true }
	if .NEED_WAKEUP in sync.atomic_load_explicit(ring.sq.flags, .Relaxed) {
		flags^ += {.SQ_WAKEUP}
		return true
	}
	return false
}


// Submits the submission queue entries acquired via get_sqe().
// Returns the number of entries submitted.
// Optionally wait for a number of events by setting `wait_nr`, and/or set a maximum wait time by setting `timeout`.
submit :: proc(ring: ^Ring, wait_nr: u32 = 0, timeout: ^linux.Time_Spec = nil) -> (n_submitted: u32, err: linux.Errno) {
	n_submitted = flush_sq(ring)
	flags: linux.IO_Uring_Enter_Flags
	if sq_ring_needs_enter(ring, &flags) || wait_nr > 0 {
		if wait_nr > 0 || .IOPOLL in ring.flags {
			flags += {.GETEVENTS}
		}

		flags += {.EXT_ARG}
		ext: linux.IO_Uring_Getevents_Arg
		ext.ts = timeout

		n_submitted_: int
		n_submitted_, err = linux.io_uring_enter2(ring.fd, n_submitted, wait_nr, flags, &ext)
		assert(n_submitted_ >= 0)
		n_submitted = u32(n_submitted_)
	}
	return
}

// Returns the number of submission queue entries in the submission queue.
sq_ready :: proc(ring: ^Ring) -> u32 {
	// Always use the shared ring state (i.e. head and not sqe_head) to avoid going out of sync,
	// see https://github.com/axboe/liburing/issues/92.
	return ring.sq.sqe_tail - sync.atomic_load_explicit(ring.sq.head, .Acquire)
}

// Returns the number of completion queue entries in the completion queue (yet to consume).
cq_ready :: proc(ring: ^Ring) -> (n_ready: u32) {
	return sync.atomic_load_explicit(ring.cq.tail, .Acquire) - ring.cq.head^
}

// Copies as many CQEs as are ready, and that can fit into the destination `cqes` slice.
// If none are available, enters into the kernel to wait for at most `wait_nr` CQEs.
// Returns the number of CQEs copied, advancing the CQ ring.
// Provides all the wait/peek methods found in liburing, but with batching and a single method.
// TODO: allow for timeout.
copy_cqes :: proc(ring: ^Ring, cqes: []linux.IO_Uring_CQE, wait_nr: u32) -> (n_copied: u32, err: linux.Errno) {
	n_copied = copy_cqes_ready(ring, cqes)
	if n_copied > 0 { return }
	if wait_nr > 0 || cq_ring_needs_flush(ring) {
		_ = linux.io_uring_enter(ring.fd, 0, wait_nr, {.GETEVENTS}, nil) or_return
		n_copied = copy_cqes_ready(ring, cqes)
	}
	return
}

copy_cqes_ready :: proc(ring: ^Ring, cqes: []linux.IO_Uring_CQE) -> (n_copied: u32) {
	n_ready := cq_ready(ring)
	n_copied = min(u32(len(cqes)), n_ready)
	head := ring.cq.head^
	tail := head + n_copied
	shift := u32(.CQE32 in ring.flags)

	i := 0
	for head != tail {
		cqes[i] = ring.cq.cqes[(head & ring.cq.mask) << shift]
		head += 1
		i += 1
	}
	cq_advance(ring, n_copied)
	return
}

cq_ring_needs_flush :: proc(ring: ^Ring) -> bool {
	return .CQ_OVERFLOW in sync.atomic_load_explicit(ring.sq.flags, .Relaxed)
}

// For advanced use cases only that implement custom completion queue methods.
// If you use copy_cqes() or copy_cqe() you must not call cqe_seen() or cq_advance().
// Must be called exactly once after a zero-copy CQE has been processed by your application.
// Not idempotent, calling more than once will result in other CQEs being lost.
// Matches the implementation of cqe_seen() in liburing.
cqe_seen :: proc(ring: ^Ring) {
	cq_advance(ring, 1)
}

// For advanced use cases only that implement custom completion queue methods.
// Matches the implementation of cq_advance() in liburing.
cq_advance :: proc(ring: ^Ring, count: u32) {
	if count == 0 { return }
	sync.atomic_store_explicit(ring.cq.head, ring.cq.head^ + count, .Release)
}

Submission_Queue :: struct {
	head:      ^u32,
	tail:      ^u32,
	mask:      u32,
	flags:     ^linux.IO_Uring_Submission_Queue_Flags,
	dropped:   ^u32,
	array:     []u32,
	sqes:      []linux.IO_Uring_SQE,
	mmap:      []u8,
	mmap_sqes: []u8,

	// We use `sqe_head` and `sqe_tail` in the same way as liburing:
	// We increment `sqe_tail` (but not `tail`) for each call to `get_sqe()`.
	// We then set `tail` to `sqe_tail` once, only when these events are actually submitted.
	// This allows us to amortize the cost of the @atomicStore to `tail` across multiple SQEs.
	sqe_head:  u32,
	sqe_tail:  u32,
}

submission_queue_make :: proc(fd: linux.Fd, params: ^linux.IO_Uring_Params) -> (sq: Submission_Queue, err: linux.Errno) {
	assert(fd >= 0, "uninitialized queue fd")
	assert(.SINGLE_MMAP in params.features, "unsupported feature") // NOTE: Could support this, but currently isn't.

	sq_size := params.sq_off.array + params.sq_entries * size_of(u32)
	cq_size := params.cq_off.cqes + params.cq_entries * size_of(linux.IO_Uring_CQE)
	size := max(sq_size, cq_size)

	// PERF: .POPULATE commits all pages right away, is that desired?

	cqe_map := cast([^]byte)(linux.mmap(0, uint(size), {.READ, .WRITE}, {.SHARED, .POPULATE}, fd, linux.IORING_OFF_SQ_RING) or_return)
	defer if err != nil { linux.munmap(cqe_map, uint(size)) }

	size_sqes := params.sq_entries * size_of(linux.IO_Uring_SQE)
	sqe_map   := cast([^]byte)(linux.mmap(0, uint(size_sqes), {.READ, .WRITE}, {.SHARED, .POPULATE}, fd, linux.IORING_OFF_SQES) or_return)

	array := cast([^]u32)cqe_map[params.sq_off.array:]
	sqes  := cast([^]linux.IO_Uring_SQE)sqe_map

	sq.head      = cast(^u32)&cqe_map[params.sq_off.head]
	sq.tail      = cast(^u32)&cqe_map[params.sq_off.tail]
	sq.mask      = (cast(^u32)&cqe_map[params.sq_off.ring_mask])^
	sq.flags     = cast(^linux.IO_Uring_Submission_Queue_Flags)&cqe_map[params.sq_off.flags]
	sq.dropped   = cast(^u32)&cqe_map[params.sq_off.dropped]
	sq.array     = array[:params.sq_entries]
	sq.sqes      = sqes[:params.sq_entries]
	sq.mmap      = cqe_map[:size]
	sq.mmap_sqes = sqe_map[:size_sqes]

	return
}

submission_queue_destroy :: proc(sq: ^Submission_Queue) -> (err: linux.Errno) {
	err   = linux.munmap(raw_data(sq.mmap), uint(len(sq.mmap)))
	err2 := linux.munmap(raw_data(sq.mmap_sqes), uint(len(sq.mmap_sqes)))
	if err == nil { err = err2 }
	return
}

Completion_Queue :: struct {
	head:     ^u32,
	tail:     ^u32,
	mask:     u32,
	overflow: ^u32,
	cqes:     []linux.IO_Uring_CQE,
}

completion_queue_make :: proc(fd: linux.Fd, params: ^linux.IO_Uring_Params, sq: ^Submission_Queue) -> Completion_Queue {
	assert(fd >= 0, "uninitialized queue fd")
	assert(.SINGLE_MMAP in params.features, "required feature SINGLE_MMAP not supported")

	mmap := sq.mmap
	cqes := cast([^]linux.IO_Uring_CQE)&mmap[params.cq_off.cqes]

	return(
		{
			head     = cast(^u32)&mmap[params.cq_off.head],
			tail     = cast(^u32)&mmap[params.cq_off.tail],
			mask     = (cast(^u32)&mmap[params.cq_off.ring_mask])^,
			overflow = cast(^u32)&mmap[params.cq_off.overflow],
			cqes     = cqes[:params.cq_entries],
		} \
	)
}
