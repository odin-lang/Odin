#+build linux
package android

import "base:intrinsics"
import "core:sys/posix"

// The JavaVM of the process. Android has exactly one.
@(private="file")
jni_global_vm: ^JavaVM

// A thread `jni_env` attached is detached by this key's destructor when it exits.
@(private="file")
jni_detach_key: posix.pthread_key_t

@(private="file")
jni_detach_key_state: u32 // 0: none, 1: being created, 2: ready

/*
Set the process's JavaVM, which `jni_env` and the `vendor:android/java` wrappers use.

`core:sys/android/native_app_glue` sets it from the activity. Anything else calls it once, e.g. from an exported `JNI_OnLoad`.
*/
jni_set_vm :: proc "contextless" (vm: ^JavaVM) {
	intrinsics.atomic_store_explicit(&jni_global_vm, vm, .Release)
}

// The process's JavaVM, or nil before `jni_set_vm`.
jni_vm :: proc "contextless" () -> ^JavaVM {
	return intrinsics.atomic_load_explicit(&jni_global_vm, .Acquire)
}

/*
This thread's JNIEnv.

A thread Java did not start is attached on first use, and detached when it exits.
Returns nil before `jni_set_vm`, or if attaching fails.
*/
jni_env :: proc "contextless" () -> ^JNIEnv {
	vm := jni_vm()
	if vm == nil {
		return nil
	}

	env: ^JNIEnv
	switch vm->GetEnv((^rawptr)(&env), JNI_VERSION_1_6) {
	case JNI_OK:
		return env
	case JNI_EDETACHED:
		if vm->AttachCurrentThread(&env, nil) != JNI_OK {
			return nil
		}
		posix.pthread_setspecific(jni_detach_key_get(), vm)
		return env
	}
	return nil
}

/*
Clear the exception pending on `env`, if any, and return it as a local reference.

Every JNI call that can throw must be followed by this (or by `env->ExceptionClear()`).
Calling JNI with an exception pending aborts the app.
*/
jni_take_exception :: proc "contextless" (env: ^JNIEnv) -> jthrowable {
	if env->ExceptionCheck() == JNI_FALSE {
		return nil
	}
	exception := env->ExceptionOccurred()
	env->ExceptionClear()
	return exception
}

@(private="file")
jni_detach_key_get :: proc "contextless" () -> posix.pthread_key_t {
	detach :: proc "c" (vm: rawptr) {
		(^JavaVM)(vm)->DetachCurrentThread()
	}

	if intrinsics.atomic_load_explicit(&jni_detach_key_state, .Acquire) != 2 {
		if _, ok := intrinsics.atomic_compare_exchange_strong(&jni_detach_key_state, 0, 1); ok {
			posix.pthread_key_create(&jni_detach_key, detach)
			intrinsics.atomic_store_explicit(&jni_detach_key_state, 2, .Release)
		}
		for intrinsics.atomic_load_explicit(&jni_detach_key_state, .Acquire) != 2 {
			intrinsics.cpu_relax()
		}
	}
	return jni_detach_key
}
