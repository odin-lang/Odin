#+build linux
package android_java

import "base:intrinsics"
import "base:runtime"
import android "core:sys/android"

/*
Called when Java calls a method of a `proxy_new` object, on whichever thread Java calls it on, with
the default context. Its `context.temp_allocator` is freed when it returns. `args` is nil for a method
without parameters, and holds primitives boxed, as a `^Integer` for an `int`.

Return nil for a `void` method, and a boxed value for a primitive result, e.g. `Boolean_valueOf(true)`.
A non-nil `exception` is thrown to the caller.
*/
Proxy_Handler :: #type proc(data: rawptr, method: ^Method, args: ^Array(Object)) -> (result: ^Object, exception: ^Throwable)

/*
Make an object that implements Java interfaces by calling `handler`:

	run :: proc(data: rawptr, method: ^java.Method, args: ^java.Array(java.Object)) -> (result: ^java.Object, exception: ^java.Throwable) {
		log.info("on the UI thread")
		return
	}

	runnable_class := java.find_class("java/lang/Runnable") or_return
	runnable := java.proxy_new({runnable_class}, run) or_return
	java.Activity_runOnUiThread(activity, (^java.Runnable)(runnable)) or_return

`data` must stay valid for as long as Java can call the object.
*/
proxy_new :: proc "contextless" (interfaces: []^Class, handler: Proxy_Handler, data: rawptr = nil) -> (result: ^Object, exception: ^Throwable) {
	env := jni_env_or_panic()
	proxy_class := proxy_class_get(env) or_return

	array := (^Array(Class))(env->NewObjectArray(i32(len(interfaces)), jni_find_class(env, &Class__class) or_return, nil))
	if array == nil {
		return nil, jni_take(env)
	}
	defer env->DeleteLocalRef(array)

	// The proxy class must be defined by a class loader that can see every interface.
	loader: ^ClassLoader
	for interface, i in interfaces {
		env->SetObjectArrayElement(array, i32(i), interface)
		if loader == nil {
			loader = Class_getClassLoader(interface) or_return
		}
	}
	if loader == nil {
		// The interfaces are all Android's: the loader of NativeProxy sees them.
		loader = Class_getClassLoader((^Class)(proxy_class)) or_return
	}
	defer env->DeleteLocalRef(loader)

	init := env->GetMethodID(proxy_class, "<init>", "(JJ)V")
	if init == nil {
		return nil, jni_take(env)
	}
	args := [?]android.jvalue{{j = i64(uintptr(rawptr(handler)))}, {j = i64(uintptr(data))}}
	invocation_handler := (^InvocationHandler)(env->NewObjectA(proxy_class, init, &args[0]))
	if invocation_handler == nil {
		return nil, jni_take(env)
	}
	defer env->DeleteLocalRef(invocation_handler)

	return Proxy_newProxyInstance(loader, array, invocation_handler)
}

// The name of a `Proxy_Handler`'s method, e.g. "onClick".
method_name :: proc(method: ^Method, allocator := context.temp_allocator) -> string {
	name, exception := Method_getName(method)
	if exception != nil {
		delete_local(exception)
		return ""
	}
	defer delete_local(name)
	s, _ := string_to(name, allocator)
	return s
}

/*
Add a listener to an `org.odin_lang.OdinActivity`, the NativeActivity subclass `odin bundle android` puts
in every app, which a manifest names instead of `android.app.NativeActivity`. `handler` is called for:

	onActivityResult(int requestCode, int resultCode, Intent data)
	onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults)
	onNewIntent(Intent intent)

Use `method_name` to tell them apart. Returns the listener, a local reference, or an exception if the
activity is not an `OdinActivity`.
*/
odin_activity_add_listener :: proc "contextless" (activity: ^Activity, handler: Proxy_Handler, data: rawptr = nil) -> (listener: ^Object, exception: ^Throwable) {
	env := jni_env_or_panic()
	class := env->GetObjectClass(activity)
	defer env->DeleteLocalRef(class)

	add := env->GetMethodID(class, "addListener", "(Lorg/odin_lang/OdinActivity$Listener;)V")
	if add == nil {
		return nil, jni_take(env)
	}

	// The app's class loader, which loaded the activity, is the only one that can find the interface.
	loader := Class_getClassLoader((^Class)(class)) or_return
	defer env->DeleteLocalRef(loader)
	name := (^String)(env->NewStringUTF("org.odin_lang.OdinActivity$Listener"))
	defer env->DeleteLocalRef(name)
	listener_class := ClassLoader_loadClass(loader, name) or_return
	defer env->DeleteLocalRef(listener_class)

	listener = proxy_new({listener_class}, handler, data) or_return
	args := [?]android.jvalue{{l = listener}}
	env->CallVoidMethodA(activity, add, &args[0])
	if exception = jni_take(env); exception != nil {
		env->DeleteLocalRef(listener)
		return nil, exception
	}
	return
}

// classes.dex holds NativeProxy, from `_dex/NativeProxy.java`, and OdinActivity, which `odin bundle android` adds to apps.
@(private="file")
dex := #load("classes.dex")

@(private="file")
proxy_class_ref: android.jclass

// NativeProxy, loaded from the embedded dex, so proxies work without the bundler's classes.dex too.
@(private="file")
proxy_class_get :: proc "contextless" (env: ^android.JNIEnv) -> (class: android.jclass, exception: ^Throwable) {
	class = intrinsics.atomic_load_explicit(&proxy_class_ref, .Acquire)
	if class != nil {
		return
	}

	loader_class := env->FindClass("dalvik/system/InMemoryDexClassLoader")
	if loader_class == nil {
		return nil, jni_take(env)
	}
	defer env->DeleteLocalRef(loader_class)
	init := env->GetMethodID(loader_class, "<init>", "(Ljava/nio/ByteBuffer;Ljava/lang/ClassLoader;)V")
	if init == nil {
		return nil, jni_take(env)
	}

	// InMemoryDexClassLoader copies the buffer.
	buffer := env->NewDirectByteBuffer(raw_data(dex), i64(len(dex)))
	if buffer == nil {
		return nil, jni_take(env)
	}
	defer env->DeleteLocalRef(buffer)
	parent := ClassLoader_getSystemClassLoader() or_return
	defer env->DeleteLocalRef(parent)

	args := [?]android.jvalue{{l = buffer}, {l = parent}}
	loader := (^ClassLoader)(env->NewObjectA(loader_class, init, &args[0]))
	if loader == nil {
		return nil, jni_take(env)
	}
	defer env->DeleteLocalRef(loader)

	name := (^String)(env->NewStringUTF("org.odin_lang.NativeProxy"))
	defer env->DeleteLocalRef(name)
	local := ClassLoader_loadClass(loader, name) or_return
	defer env->DeleteLocalRef(local)

	natives := [?]android.JNINativeMethod{
		{"call", "(JJLjava/lang/reflect/Method;[Ljava/lang/Object;)Ljava/lang/Object;", rawptr(proxy_call)},
	}
	if env->RegisterNatives(local, &natives[0], len(natives)) != android.JNI_OK {
		return nil, jni_take(env)
	}

	global := env->NewGlobalRef(local)
	if previous, ok := intrinsics.atomic_compare_exchange_strong_explicit(&proxy_class_ref, nil, global, .Acq_Rel, .Acquire); !ok {
		// Another thread got there first.
		env->DeleteGlobalRef(global)
		return previous, nil
	}
	return global, nil
}

// NativeProxy.call
@(private="file")
proxy_call :: proc "c" (env: ^android.JNIEnv, class: android.jclass, handler, data: i64, method, args: android.jobject) -> android.jobject {
	context = runtime.default_context()

	// Temporary memory lasts for the call. It is not the thread's own temporary allocator, which a
	// handler called from Odin code on the same thread could otherwise free under it.
	temp := runtime.Arena{backing_allocator = runtime.heap_allocator(), minimum_block_size = 4 << 10}
	defer runtime.arena_destroy(&temp)
	context.temp_allocator = runtime.arena_allocator(&temp)

	result, exception := Proxy_Handler(rawptr(uintptr(handler)))(rawptr(uintptr(data)), (^Method)(method), (^Array(Object))(args))
	if exception != nil {
		env->Throw(exception)
		return nil
	}
	return result
}
