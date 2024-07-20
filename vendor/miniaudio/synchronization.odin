package miniaudio

foreign import lib { LIB }

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	/*
	Locks a spinlock.
	*/
	spinlock_lock :: proc(/*volatile*/ pSpinlock: ^spinlock) -> result ---

	/*
	Locks a spinlock, but does not yield() when looping.
	*/
	spinlock_lock_noyield :: proc(/*volatile*/ pSpinlock: ^spinlock) -> result ---

	/*
	Unlocks a spinlock.
	*/
	spinlock_unlock :: proc(/*volatile*/ pSpinlock: ^spinlock) -> result ---

when !NO_THREADING {
	/*
	Creates a mutex.

	A mutex must be created from a valid context. A mutex is initially unlocked.
	*/
	mutex_init :: proc(pMutex: ^mutex) -> result ---

	/*
	Deletes a mutex.
	*/
	mutex_uninit :: proc(pMutex: ^mutex) ---

	/*
	Locks a mutex with an infinite timeout.
	*/
	mutex_lock :: proc(pMutex: ^mutex) ---

	/*
	Unlocks a mutex.
	*/
	mutex_unlock :: proc(pMutex: ^mutex) ---


	/*
	Initializes an auto-reset event.
	*/
	event_init :: proc(pEvent: ^event) -> result ---

	/*
	Uninitializes an auto-reset event.
	*/
	event_uninit :: proc(pEvent: ^event) ---

	/*
	Waits for the specified auto-reset event to become signalled.
	*/
	event_wait :: proc(pEvent: ^event) -> result ---

	/*
	Signals the specified auto-reset event.
	*/
	event_signal :: proc(pEvent: ^event) -> result ---
} /* NO_THREADING */

}

/*
Fence
=====
This locks while the counter is larger than 0. Counter can be incremented and decremented by any
thread, but care needs to be taken when waiting. It is possible for one thread to acquire the
fence just as another thread returns from ma_fence_wait().

The idea behind a fence is to allow you to wait for a group of operations to complete. When an
operation starts, the counter is incremented which locks the fence. When the operation completes,
the fence will be released which decrements the counter. ma_fence_wait() will block until the
counter hits zero.

If threading is disabled, ma_fence_wait() will spin on the counter.
*/
fence :: struct {
	e:       (struct {} when NO_THREADING else event),
	counter: (u32 when NO_THREADING else struct {}),
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	fence_init    :: proc(pFence: ^fence) -> result ---
	fence_uninit  :: proc(pFence: ^fence) ---
	fence_acquire :: proc(pFence: ^fence) -> result ---    /* Increment counter. */
	fence_release :: proc(pFence: ^fence) -> result ---    /* Decrement counter. */
	fence_wait    :: proc(pFence: ^fence) -> result ---    /* Wait for counter to reach 0. */
}


/*
Notification callback for asynchronous operations.
*/
async_notification :: struct {}

async_notification_callbacks :: struct {
	onSignal: proc "c" (pNotification: ^async_notification),
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	async_notification_signal :: proc(pNotification: ^async_notification) -> result ---
}


/*
Simple polling notification.

This just sets a variable when the notification has been signalled which is then polled with ma_async_notification_poll_is_signalled()
*/
async_notification_poll :: struct {
		cb:        async_notification_callbacks,
		signalled: b32,
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	async_notification_poll_init         :: proc(pNotificationPoll: ^async_notification_poll) -> result ---
	async_notification_poll_is_signalled :: proc(pNotificationPoll: ^async_notification_poll) -> b32 ---
}


/*
Event Notification

This uses an ma_event. If threading is disabled (MA_NO_THREADING), initialization will fail.
*/
async_notification_event :: struct {
	cb: async_notification_callbacks,
	e:  (struct {} when NO_THREADING else event),
}

@(default_calling_convention="c", link_prefix="ma_")
foreign lib {
	async_notification_event_init   :: proc(pNotificationEvent: ^async_notification_event) -> result ---
	async_notification_event_uninit :: proc(pNotificationEvent: ^async_notification_event) -> result ---
	async_notification_event_wait   :: proc(pNotificationEvent: ^async_notification_event) -> result ---
	async_notification_event_signal :: proc(pNotificationEvent: ^async_notification_event) -> result ---
}
