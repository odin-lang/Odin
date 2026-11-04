#+build linux
package android

import "base:intrinsics"
import "base:runtime"
import "core:c"
import "core:io"
import "core:unicode/utf16"

// The app's `AssetManager`: a global reference to the Java object, and the native one behind it.
@(private="file")
asset_global_java_manager: jobject

@(private="file")
asset_global_manager: ^AAssetManager

@(private="file")
asset_list_method: jmethodID

/*
Keep the app's `android.content.res.AssetManager` for the `asset_*` procedures and `core:os`'s `/android_asset` paths.

`core:sys/android/native_app_glue` sets the application's before `main`. Anything else calls it once, e.g. with
`getAssets()` of the application's `Context`. A global reference to it is kept for the rest of the process.
*/
asset_set_manager :: proc "contextless" (env: ^JNIEnv, java_manager: jobject) -> bool {
	if env == nil || java_manager == nil {
		return false
	}

	class := env->GetObjectClass(java_manager)
	defer env->DeleteLocalRef(class)
	method := env->GetMethodID(class, "list", "(Ljava/lang/String;)[Ljava/lang/String;")
	if method == nil {
		env->ExceptionClear()
		return false
	}

	ref := env->NewGlobalRef(java_manager)
	manager := AAssetManager_fromJava(env, ref)
	if manager == nil {
		env->DeleteGlobalRef(ref)
		return false
	}

	asset_list_method = method
	asset_global_java_manager = ref
	intrinsics.atomic_store_explicit(&asset_global_manager, manager, .Release)
	return true
}

// The app's `AAssetManager`, or nil before `asset_set_manager`.
asset_manager :: proc "contextless" () -> ^AAssetManager {
	return intrinsics.atomic_load_explicit(&asset_global_manager, .Acquire)
}

/*
Open the asset at `path`, relative to the APK's `assets` directory.

Returns nil if there is no such file, or no asset manager. Close it with `AAsset_close`, or through `asset_to_stream`.
*/
asset_open :: proc "contextless" (path: string, mode := AAssetMode.UNKNOWN) -> ^AAsset {
	manager := asset_manager()
	buf: [1024]byte
	if manager == nil || len(path) >= len(buf) {
		return nil
	}
	copy(buf[:], path)
	return AAssetManager_open(manager, cstring(&buf[0]), mode)
}

/*
Read the asset at `path`, relative to the APK's `assets` directory.

*Allocates Using Provided Allocator*
*/
asset_read_entire_file :: proc(path: string, allocator := context.allocator, loc := #caller_location) -> (data: []byte, ok: bool) {
	asset := asset_open(path, .STREAMING)
	if asset == nil {
		return
	}
	defer AAsset_close(asset)

	size := AAsset_getLength64(asset)
	if size < 0 || i64(int(size)) != size {
		return
	}
	err: runtime.Allocator_Error
	if data, err = make([]byte, int(size), allocator, loc); err != nil {
		return
	}

	for total := 0; total < len(data); {
		n := AAsset_read(asset, &data[total], c.size_t(len(data[total:])))
		if n <= 0 {
			delete(data, allocator, loc)
			return nil, false
		}
		total += int(n)
	}
	return data, true
}

/*
An `io.Stream` over `asset`, which the stream then owns: `.Close` and `.Destroy` close the asset.

It reads, seeks, and reports its size. `.Read_At` seeks there and back, so the stream must not be shared between threads.
*/
asset_to_stream :: proc "contextless" (asset: ^AAsset) -> io.Stream {
	return {procedure = asset_stream_proc, data = asset}
}

@(private="file")
asset_stream_proc :: proc(stream_data: rawptr, mode: io.Stream_Mode, p: []byte, offset: i64, whence: io.Seek_From) -> (n: i64, err: io.Error) {
	SEEK_SET :: 0
	SEEK_CUR :: 1
	SEEK_END :: 2

	read :: proc(asset: ^AAsset, p: []byte) -> (n: i64, err: io.Error) {
		if len(p) == 0 {
			return 0, nil
		}
		switch r := AAsset_read(asset, raw_data(p), c.size_t(len(p))); {
		case r > 0:  return i64(r), nil
		case r == 0: return 0, .EOF
		case:        return 0, .Unknown
		}
	}

	asset := (^AAsset)(stream_data)
	switch mode {
	case .Read:
		return read(asset, p)
	case .Read_At:
		current := AAsset_seek64(asset, 0, SEEK_CUR)
		if offset < 0 || current < 0 || AAsset_seek64(asset, offset, SEEK_SET) < 0 {
			return 0, .Invalid_Offset
		}
		defer AAsset_seek64(asset, current, SEEK_SET)
		return read(asset, p)
	case .Seek:
		w: c.int
		switch whence {
		case .Start:   w = SEEK_SET
		case .Current: w = SEEK_CUR
		case .End:     w = SEEK_END
		case:          return 0, .Invalid_Whence
		}
		if n = AAsset_seek64(asset, offset, w); n < 0 {
			return 0, .Invalid_Offset
		}
		return
	case .Size:
		return AAsset_getLength64(asset), nil
	case .Close, .Destroy:
		AAsset_close(asset)
		return
	case .Query:
		return io.query_utility({.Read, .Read_At, .Seek, .Size, .Close, .Destroy, .Query})
	case .Flush, .Write, .Write_At:
	}
	return 0, .Unsupported
}

/*
The names of the files and directories directly in the asset directory `path`, relative to the APK's `assets`
directory, in no particular order. `""` is the top, which also holds a few directories of the system's own, like
`images` and `webkit`. Free them with `asset_list_delete`.

It calls Java's `AssetManager.list` through JNI. The NDK's `AAssetDir` lists files only, never directories.

*Allocates Using Provided Allocator*
*/
asset_list :: proc(path: string, allocator := context.allocator) -> (names: []string, ok: bool) {
	env := jni_env()
	if asset_manager() == nil || env == nil {
		return
	}
	if env->PushLocalFrame(4) != JNI_OK {
		env->ExceptionClear()
		return
	}
	defer env->PopLocalFrame(nil)

	// A byte of UTF-8 is at most one UTF-16 code unit.
	units, units_err := make([]u16, len(path), allocator)
	if units_err != nil {
		return
	}
	units = units[:utf16.encode_string(units, path)]
	jpath := env->NewString(raw_data(units), jsize(len(units)))
	delete(units, allocator)
	if jpath == nil {
		env->ExceptionClear()
		return
	}

	args := [1]jvalue{{l = jpath}}
	array := env->CallObjectMethodA(asset_global_java_manager, asset_list_method, &args[0])
	if env->ExceptionCheck() != JNI_FALSE || array == nil {
		env->ExceptionClear()
		return
	}

	err: runtime.Allocator_Error
	if names, err = make([]string, int(env->GetArrayLength(array)), allocator); err != nil {
		return
	}
	for &name, i in names {
		element := env->GetObjectArrayElement(array, jsize(i))
		length := env->GetStringLength(element)
		chars := env->GetStringChars(element, nil)

		// A UTF-16 code unit takes at most 3 bytes of UTF-8.
		buffer: []byte
		buffer, err = make([]byte, int(length)*3, allocator)
		if err == nil {
			name = string(buffer[:utf16.decode_to_utf8(buffer, ([^]u16)(chars)[:length])])
		}
		env->ReleaseStringChars(element, chars)
		env->DeleteLocalRef(element)
		if err != nil {
			for prev in names[:i] {
				delete(prev, allocator)
			}
			delete(names, allocator)
			return nil, false
		}
	}
	return names, true
}

// Free the names `asset_list` returned.
asset_list_delete :: proc(names: []string, allocator := context.allocator) {
	for name in names {
		delete(name, allocator)
	}
	delete(names, allocator)
}
