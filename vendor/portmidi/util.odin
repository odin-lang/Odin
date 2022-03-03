package portmidi

/* util.odin -- some helpful utilities for building midi 
                applications that use PortMidi 
 */


import "core:c"

when ODIN_OS == .Windows {
	foreign import lib "portmidi_s.lib"
} else {
	foreign import lib "system:portmidi"
}


Queue :: distinct rawptr


/*
	A single-reader, single-writer queue is created by
	QueueCreate(), which takes the number of messages and
	the message size as parameters. The queue only accepts
	fixed sized messages. Returns nil if memory cannot be allocated.
	This queue implementation uses the "light pipe" algorithm which
	operates correctly even with multi-processors and out-of-order
	memory writes. (see Alexander Dokumentov, "Lock-free Interprocess
	Communication," Dr. Dobbs Portal, http://www.ddj.com/, 
	articleID=189401457, June 15, 2006. This algorithm requires
	that messages be translated to a form where no words contain
	zeros. Each word becomes its own "data valid" tag. Because of
	this translation, we cannot return a pointer to data still in 
	the queue when the "peek" method is called. Instead, a buffer 
	is preallocated so that data can be copied there. QueuePeek() 
	dequeues a message into this buffer and returns a pointer to 
	it. A subsequent Dequeue() will copy from this buffer.
	This implementation does not try to keep reader/writer data in
	separate cache lines or prevent thrashing on cache lines. 
	However, this algorithm differs by doing inserts/removals in
	units of messages rather than units of machine words. Some
	performance improvement might be obtained by not clearing data
	immediately after a read, but instead by waiting for the end
	of the cache line, especially if messages are smaller than
	cache lines. See the Dokumentov article for explanation.
	The algorithm is extended to handle "overflow" reporting. To report
	an overflow, the sender writes the current tail position to a field.
	The receiver must acknowlege receipt by zeroing the field. The sender
	will not send more until the field is zeroed.

	QueueDestroy() destroys the queue and frees its storage.
 */

@(default_calling_convention="c", link_prefix="Pm_")
foreign lib {
	QueueCreate  :: proc(num_msgs: c.long, bytes_per_msg: i32) -> Queue ---
	QueueDestroy :: proc(queue: Queue) -> Error ---
	
	/* 
		Dequeue() removes one item from the queue, copying it into msg.
		Returns 1 if successful, and 0 if the queue is empty.
		Returns .BufferOverflow if what would have been the next thing
		in the queue was dropped due to overflow. (So when overflow occurs,
		the receiver can receive a queue full of messages before getting the
		overflow report. This protocol ensures that the reader will be 
		notified when data is lost due to overflow.
	 */
	Dequeue      :: proc(queue: Queue, msg: rawptr) -> Error ---
	
	/*
		Enqueue() inserts one item into the queue, copying it from msg.
		Returns .NoError if successful and .BufferOverflow if the queue was 
		already full. If .BufferOverflow is returned, the overflow flag is set.
	 */
	Enqueue      :: proc(queue: Queue, msg: rawptr) -> Error ---
	
	/*
	    QueueFull() returns non-zero if the queue is full
	    QueueEmpty() returns non-zero if the queue is empty
	    Either condition may change immediately because a parallel
	    enqueue or dequeue operation could be in progress. Furthermore,
	    QueueEmpty() is optimistic: it may say false, when due to 
	    out-of-order writes, the full message has not arrived. Therefore,
	    Dequeue() could still return 0 after QueueEmpty() returns
	    false. On the other hand, QueueFull() is pessimistic: if it
	    returns false, then Enqueue() is guaranteed to succeed. 
	    Error conditions: QueueFull() returns .BadPtr if queue is nil.
	    QueueEmpty() returns false if queue is nil.
	 */
	QueueFull    :: proc(queue: Queue) -> b32 ---
	QueueEmpty   :: proc(queue: Queue) -> b32 ---
	
	/*
		QueuePeek() returns a pointer to the item at the head of the queue,
		or NULL if the queue is empty. The item is not removed from the queue.
		QueuePeek() will not indicate when an overflow occurs. If you want
		to get and check .BufferOverflow messages, use the return value of
		QueuePeek() *only* as an indication that you should call 
		Dequeue(). At the point where a direct call to Dequeue() would
		return .BufferOverflow, QueuePeek() will return NULL but internally
		clear the .BufferOverflow flag, enabling Enqueue() to resume
		enqueuing messages. A subsequent call to QueuePeek()
		will return a pointer to the first message *after* the overflow. 
		Using this as an indication to call Dequeue(), the first call
		to Dequeue() will return .BufferOverflow. The second call will
		return success, copying the same message pointed to by the previous
		QueuePeek().
		When to use QueuePeek(): (1) when you need to look at the message
		data to decide who should be called to receive it. (2) when you need
		to know a message is ready but cannot accept the message.
		Note that QueuePeek() is not a fast check, so if possible, you 
		might as well just call Dequeue() and accept the data if it is there.
	 */
	QueuePeek    :: proc(queue: Queue) -> rawptr ---
	
	/*
		SetOverflow() allows the writer (enqueuer) to signal an overflow
		condition to the reader (dequeuer). E.g. when transfering data from 
		the OS to an application, if the OS indicates a buffer overrun,
		SetOverflow() can be used to insure that the reader receives a
		.BufferOverflow result from Dequeue(). Returns .BadPtr if queue
		is NULL, returns .BufferOverflow if buffer is already in an overflow
		state, returns .NoError if successfully set overflow state.
	 */
	SetOverflow  :: proc(queue: Queue) -> Error ---
}
