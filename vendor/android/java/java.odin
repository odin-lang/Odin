#+build linux
/*
JNI wrappers for the Java APIs of the Android SDK, generated from `android.jar` by `_gen/generate.py`.

A Java reference is a pointer to its class's struct, like `jobject` is in C++'s `jni.h`.
The structs are zero-size and never dereferenced: the pointer is the JNI reference itself.
A reference converts implicitly to any superclass, and to an interface through the view of the same name:

	activity: ^java.Activity
	context:  ^java.Context      = activity                        // superclass
	callback: ^java.Window_Callback = &activity.Window_Callback    // interface

Java methods are procedures named `Class_method`; overloads form a procedure group whose members
are named by their parameter types, e.g. `TextView_setText_int`. Constructors are `Class_new`, fields
are `Class_get_name` and `Class_set_name`, and constants are `Class_NAME`.

Every wrapper returns the exception it threw as its last result, or nil. It is cleared, so nothing is
left pending:

	keep_screen_on :: proc(activity: ^java.Activity) -> (exception: ^java.Throwable) {
		window := java.Activity_getWindow(activity) or_return
		return java.Window_addFlags(window, java.WindowManager_LayoutParams_FLAG_KEEP_SCREEN_ON)
	}

The wrappers use the calling thread's JNIEnv from `android.jni_env`, attaching the thread on first use.
That needs the process's JavaVM: `core:sys/android/native_app_glue` sets it, and anything else calls
`android.jni_set_vm` once. Classes are found with the system class loader, so the app's own classes
cannot be found by name from a native thread.

Returned references are local references. A thread Java did not start, `android_main`'s included,
never returns to Java to free them, so free them with `delete_local`, or wrap loops in
`push_local_frame` and `pop_local_frame`. Keep a reference across calls or threads with `new_global`.
*/
package android_java

import "base:intrinsics"
import "base:runtime"
import android "core:sys/android"
import "core:unicode/utf16"

// class java.lang.Object, the root of every class, interface and array.
Object :: struct {}

// A Java array of `T`, e.g. `^Array(String)` for `String[]`.
Array :: struct($T: typeid) #raw_union {
	using Object: Object,
}

BooleanArray :: struct #raw_union { using Object: Object }
ByteArray    :: struct #raw_union { using Object: Object }
CharArray    :: struct #raw_union { using Object: Object }
ShortArray   :: struct #raw_union { using Object: Object }
IntArray     :: struct #raw_union { using Object: Object }
LongArray    :: struct #raw_union { using Object: Object }
FloatArray   :: struct #raw_union { using Object: Object }
DoubleArray  :: struct #raw_union { using Object: Object }

// A class the wrappers use, found on first use and kept as a global reference.
Cached_Class :: struct {
	name: cstring,
	ref:  android.jclass,
}

Cached_Method :: struct {
	id: android.jmethodID,
}

Cached_Field :: struct {
	id: android.jfieldID,
}

// Make a Java string. `allocator` holds its UTF-16 copy until the string is made.
string_from :: proc(s: string, allocator := context.temp_allocator) -> (result: ^String, exception: ^Throwable) {
	env := jni_env_or_panic()
	buffer := make([]u16, len(s), allocator)
	defer delete(buffer, allocator)
	n := utf16.encode_string(buffer, s)
	result = (^String)(env->NewString(raw_data(buffer), i32(n)))
	return result, jni_take(env)
}

// Copy a Java string into an Odin string allocated with `allocator`. A nil reference gives "".
string_to :: proc(s: ^String, allocator := context.allocator) -> (result: string, exception: ^Throwable) {
	if s == nil {
		return
	}
	env := jni_env_or_panic()
	length := env->GetStringLength(s)
	chars := env->GetStringChars(s, nil)
	if chars == nil {
		return "", jni_take(env)
	}
	defer env->ReleaseStringChars(s, chars)

	// A UTF-16 code unit takes at most 3 bytes of UTF-8.
	buffer := make([]byte, int(length)*3, allocator)
	n := utf16.decode_to_utf8(buffer, ([^]u16)(chars)[:length])
	return string(buffer[:n]), nil
}

// The exception's `toString()`, e.g. "java.io.FileNotFoundException: /x: open failed: ENOENT".
exception_message :: proc(exception: ^Throwable, allocator := context.allocator) -> string {
	if exception == nil {
		return ""
	}
	s, e := Object_toString(exception)
	if e != nil {
		delete_local(e)
		return "<exception in toString>"
	}
	defer delete_local(s)
	message, _ := string_to(s, allocator)
	return message
}

// Find a class by its binary name, e.g. "android/os/Build$VERSION", with the system class loader.
find_class :: proc "contextless" (name: cstring) -> (result: ^Class, exception: ^Throwable) {
	env := jni_env_or_panic()
	return (^Class)(env->FindClass(name)), jni_take(env)
}

is_instance_of :: proc "contextless" (object: ^Object, class: ^Class) -> bool {
	env := jni_env_or_panic()
	return env->IsInstanceOf(object, class) != 0
}

is_same_object :: proc "contextless" (a, b: ^Object) -> bool {
	env := jni_env_or_panic()
	return env->IsSameObject(a, b) != 0
}

delete_local :: proc "contextless" (object: ^Object) {
	if object != nil {
		env := jni_env_or_panic()
		env->DeleteLocalRef(object)
	}
}

// A global reference stays valid on every thread until `delete_global`.
new_global :: proc "contextless" (object: ^$T) -> ^T where intrinsics.type_is_subtype_of(T, Object) {
	env := jni_env_or_panic()
	return (^T)(env->NewGlobalRef(object))
}

delete_global :: proc "contextless" (object: ^Object) {
	if object != nil {
		env := jni_env_or_panic()
		env->DeleteGlobalRef(object)
	}
}

// Start a frame of local references, which `pop_local_frame` frees.
push_local_frame :: proc "contextless" (capacity: i32 = 16) -> (exception: ^Throwable) {
	env := jni_env_or_panic()
	if env->PushLocalFrame(capacity) != android.JNI_OK {
		return jni_take(env)
	}
	return nil
}

// Free the frame's local references. `keep` survives: it is returned as a local reference in the outer frame.
pop_local_frame :: proc{
	pop_local_frame_all,
	pop_local_frame_keep,
}

pop_local_frame_all :: proc "contextless" () {
	env := jni_env_or_panic()
	env->PopLocalFrame(nil)
}

pop_local_frame_keep :: proc "contextless" (keep: ^$T) -> ^T where intrinsics.type_is_subtype_of(T, Object) {
	env := jni_env_or_panic()
	return (^T)(env->PopLocalFrame(keep))
}

// The length of any array.
array_length :: proc "contextless" (array: ^Object) -> i32 {
	env := jni_env_or_panic()
	return env->GetArrayLength(array)
}

// A new array of `T`, an array type, e.g. `array_new(IntArray, 4)` or `array_new(Array(String), 4, "java/lang/String")`.
array_new :: proc "contextless" ($T: typeid, length: i32, element_class: cstring = nil) -> (result: ^T, exception: ^Throwable) {
	env := jni_env_or_panic()
	when T == BooleanArray {
		result = (^T)(env->NewBooleanArray(length))
	} else when T == ByteArray {
		result = (^T)(env->NewByteArray(length))
	} else when T == CharArray {
		result = (^T)(env->NewCharArray(length))
	} else when T == ShortArray {
		result = (^T)(env->NewShortArray(length))
	} else when T == IntArray {
		result = (^T)(env->NewIntArray(length))
	} else when T == LongArray {
		result = (^T)(env->NewLongArray(length))
	} else when T == FloatArray {
		result = (^T)(env->NewFloatArray(length))
	} else when T == DoubleArray {
		result = (^T)(env->NewDoubleArray(length))
	} else when intrinsics.type_is_specialization_of(T, Array) {
		class := env->FindClass(element_class)
		if class == nil {
			return nil, jni_take(env)
		}
		defer env->DeleteLocalRef(class)
		result = (^T)(env->NewObjectArray(length, class, nil))
	} else {
		#panic("array_new: T must be an array type")
	}
	return result, jni_take(env)
}

array_get :: proc "contextless" (array: ^Array($T), index: i32) -> (result: ^T, exception: ^Throwable) {
	env := jni_env_or_panic()
	return (^T)(env->GetObjectArrayElement(array, index)), jni_take(env)
}

array_set :: proc "contextless" (array: ^Array($T), index: i32, value: ^T) -> (exception: ^Throwable) {
	env := jni_env_or_panic()
	env->SetObjectArrayElement(array, index, value)
	return jni_take(env)
}

// Copy elements `start ..< start+len(buffer)` of a primitive array into `buffer`.
array_get_region :: proc "contextless" (array: ^$T, start: i32, buffer: []$E) -> (exception: ^Throwable) {
	env := jni_env_or_panic()
	n, p := i32(len(buffer)), raw_data(buffer)
	when T == BooleanArray && E == bool {
		env->GetBooleanArrayRegion(array, start, n, (^android.jboolean)(p))
	} else when T == ByteArray && (E == i8 || E == u8) {
		env->GetByteArrayRegion(array, start, n, (^android.jbyte)(p))
	} else when T == CharArray && E == u16 {
		env->GetCharArrayRegion(array, start, n, p)
	} else when T == ShortArray && E == i16 {
		env->GetShortArrayRegion(array, start, n, p)
	} else when T == IntArray && E == i32 {
		env->GetIntArrayRegion(array, start, n, p)
	} else when T == LongArray && E == i64 {
		env->GetLongArrayRegion(array, start, n, p)
	} else when T == FloatArray && E == f32 {
		env->GetFloatArrayRegion(array, start, n, p)
	} else when T == DoubleArray && E == f64 {
		env->GetDoubleArrayRegion(array, start, n, p)
	} else {
		#panic("array_get_region: the buffer's type does not match the array's")
	}
	return jni_take(env)
}

// Copy `buffer` into elements `start ..< start+len(buffer)` of a primitive array.
array_set_region :: proc "contextless" (array: ^$T, start: i32, buffer: []$E) -> (exception: ^Throwable) {
	env := jni_env_or_panic()
	n, p := i32(len(buffer)), raw_data(buffer)
	when T == BooleanArray && E == bool {
		env->SetBooleanArrayRegion(array, start, n, (^android.jboolean)(p))
	} else when T == ByteArray && (E == i8 || E == u8) {
		env->SetByteArrayRegion(array, start, n, (^android.jbyte)(p))
	} else when T == CharArray && E == u16 {
		env->SetCharArrayRegion(array, start, n, p)
	} else when T == ShortArray && E == i16 {
		env->SetShortArrayRegion(array, start, n, p)
	} else when T == IntArray && E == i32 {
		env->SetIntArrayRegion(array, start, n, p)
	} else when T == LongArray && E == i64 {
		env->SetLongArrayRegion(array, start, n, p)
	} else when T == FloatArray && E == f32 {
		env->SetFloatArrayRegion(array, start, n, p)
	} else when T == DoubleArray && E == f64 {
		env->SetDoubleArrayRegion(array, start, n, p)
	} else {
		#panic("array_set_region: the buffer's type does not match the array's")
	}
	return jni_take(env)
}

@(private)
jni_env_or_panic :: proc "contextless" (loc := #caller_location) -> ^android.JNIEnv {
	env := android.jni_env()
	if env == nil {
		runtime.panic_contextless("vendor:android/java: no JNIEnv; call android.jni_set_vm first (core:sys/android/native_app_glue does)", loc)
	}
	return env
}

@(private)
jni_take :: proc "contextless" (env: ^android.JNIEnv) -> ^Throwable {
	return (^Throwable)(android.jni_take_exception(env))
}

@(private)
jni_find_class :: proc "contextless" (env: ^android.JNIEnv, class: ^Cached_Class) -> (ref: android.jclass, exception: ^Throwable) {
	ref = intrinsics.atomic_load_explicit(&class.ref, .Acquire)
	if ref != nil {
		return
	}
	local := env->FindClass(class.name)
	if local == nil {
		return nil, jni_take(env)
	}
	global := env->NewGlobalRef(local)
	env->DeleteLocalRef(local)
	if previous, ok := intrinsics.atomic_compare_exchange_strong_explicit(&class.ref, nil, global, .Acq_Rel, .Acquire); !ok {
		// Another thread got there first.
		env->DeleteGlobalRef(global)
		return previous, nil
	}
	return global, nil
}

@(private)
jni_method :: proc "contextless" (cache: ^Cached_Method, class: ^Cached_Class, name, signature: cstring, static: bool) -> (env: ^android.JNIEnv, ref: android.jclass, id: android.jmethodID, exception: ^Throwable) {
	env = jni_env_or_panic()
	ref = jni_find_class(env, class) or_return
	id = intrinsics.atomic_load_explicit(&cache.id, .Acquire)
	if id == nil {
		id = env->GetStaticMethodID(ref, name, signature) if static else env->GetMethodID(ref, name, signature)
		if id == nil {
			exception = jni_take(env)
			return
		}
		intrinsics.atomic_store_explicit(&cache.id, id, .Release)
	}
	return
}

@(private)
jni_field :: proc "contextless" (cache: ^Cached_Field, class: ^Cached_Class, name, signature: cstring, static: bool) -> (env: ^android.JNIEnv, ref: android.jclass, id: android.jfieldID, exception: ^Throwable) {
	env = jni_env_or_panic()
	ref = jni_find_class(env, class) or_return
	id = intrinsics.atomic_load_explicit(&cache.id, .Acquire)
	if id == nil {
		id = env->GetStaticFieldID(ref, name, signature) if static else env->GetFieldID(ref, name, signature)
		if id == nil {
			exception = jni_take(env)
			return
		}
		intrinsics.atomic_store_explicit(&cache.id, id, .Release)
	}
	return
}
