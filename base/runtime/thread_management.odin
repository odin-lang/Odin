package runtime

Thread_Local_Cleaner_Odin :: #type proc "odin" ()
Thread_Local_Cleaner_Contextless :: #type proc "contextless" ()

Thread_Local_Cleaner :: union #shared_nil {Thread_Local_Cleaner_Odin, Thread_Local_Cleaner_Contextless}

@(private="file")
thread_local_cleaners: [8]Thread_Local_Cleaner


// Add a procedure that will be run at the end of a thread for the purpose of
// deallocating state marked as `thread_local`.
//
// Intended to be called in an `init` procedure of a package with
// dynamically-allocated memory that is stored in `thread_local` variables.
add_thread_local_cleaner :: proc "contextless" (p: Thread_Local_Cleaner) {
	for &v in thread_local_cleaners {
		if v == nil {
			v = p
			return
		}
	}
	panic_contextless("There are no more thread-local cleaner slots available.")
}

// Run all of the thread-local cleaner procedures.
//
// Intended to be called by the internals of a threading API at the end of a
// thread's lifetime.
run_thread_local_cleaners :: proc "odin" () {
	for p in thread_local_cleaners {
		if p == nil {
			break
		}
		switch v in p {
		case Thread_Local_Cleaner_Odin:        v()
		case Thread_Local_Cleaner_Contextless: v()
		}
	}
}
