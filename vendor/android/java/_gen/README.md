# Java API generator

Most of `vendor:android/java` is generated from an Android SDK platform's `android.jar` by `generate.py`:

```
python vendor/android/java/_gen/generate.py --sdk <path/to/sdk> [--platform android-37.2]
```

`--sdk` defaults to the `ODIN_ANDROID_SDK` environment variable. Only Python 3 and the SDK platform are needed.
`classfile.py` reads the class files, so there is no JDK dependency. `--stats` prints counts per Java package and generates nothing.

Last generated from platform `android-37.2`.

## Inputs

| File                    | Gives                                               |
|-------------------------|-----------------------------------------------------|
| `android.jar`           | Every class, field, method, and constant.           |
| `android-stubs-src.jar` | Parameter names, which the class files do not keep. |
| `data/api-versions.xml` | The API level each class and member appeared in.    |

## What it does

- Only the Java packages in `PACKAGES` get methods, fields, and constants, one Odin file per Java package.
  - Classes they refer to from other packages get a type only, in `other_packages.odin`, so every signature can be generated.
- A Java reference is a pointer to its class's struct, like `jobject` in C++'s `jni.h`. The structs are zero-size and never dereferenced.
  - The superclass is a `using` field named after it, so `^Activity` converts implicitly to `^Context` and `^Object`.
  - An interface's first superinterface is its `using` field.
  - Every other interface is a field named after it: `&activity.Window_Callback`.
  - Arrays are `^IntArray` and the like, or `^Array(String)` for `String[]`.
- Nested classes are named `Outer_Inner`.
  - When packages share a class name, the earliest package in `NAME_PRIORITY` keeps it and the others get a prefix: `android.graphics.Path` is `Path`, and `java.nio.file.Path` is `file_Path`.
- Methods are `Class_method`. Overloads become a procedure group of members named by their parameter types (`TextView_setText_int`).
  - Constructors are `Class_new`, fields `Class_get_name` and `Class_set_name`, and `static final` constants `Class_NAME`.
  - Overloads Odin cannot tell apart stay out of the group, but can still be called by name.
- Every wrapper returns the exception it threw as its last result, cleared, so no exception is left pending.
- Classes, methods, and fields are looked up on first use and cached, the classes as global references.
- Members newer than Odin's minimum API level (29) get an `// API level N` comment, as do classes.
- Every generated file starts with a marker line. Only marked files are overwritten or deleted.

## Hand-written

| File          | What                                                                                                     |
|---------------|----------------------------------------------------------------------------------------------------------|
| `java.odin`   | The package documentation, `Object`, the array types, strings, references, arrays, and the caches.       |
| `proxy.odin`  | `proxy_new`, which implements Java interfaces with an Odin procedure, and `odin_activity_add_listener`.  |
| `classes.dex` | Built from `_dex` by `_dex/build.py`. `proxy.odin` embeds it, and `odin bundle android` adds it to apps. |

The implicit `JNIEnv` comes from `core:sys/android` (`jni_set_vm`, `jni_env`).

## The dex

`_dex` holds Odin's Java classes, in package `org.odin_lang`:

| Class          | What                                                                                              |
|----------------|---------------------------------------------------------------------------------------------------|
| `NativeProxy`  | The `InvocationHandler` behind `proxy_new`. Loaded from the embedded dex, so any app can use it.  |
| `OdinActivity` | A `NativeActivity` passing on activity results, permission results, and new intents to listeners. |

```
python vendor/android/java/_dex/build.py --sdk <path/to/sdk> --jdk <path/to/jdk>
```

It needs a JDK (`javac`) and the SDK's build-tools (`d8`). The output is reproducible.
