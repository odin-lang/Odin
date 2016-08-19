%.string = type {i8*, i64} ; Basic_string
%.rawptr = type i8* ; Basic_rawptr

%Window = type {i64, i64, %WNDCLASSEXA, %.rawptr, %.rawptr, %.rawptr, %.rawptr, i8*}
%HANDLE = type %.rawptr
%HWND = type %.rawptr
%HDC = type %.rawptr
%HINSTANCE = type %.rawptr
%HICON = type %.rawptr
%HCURSOR = type %.rawptr
%HMENU = type %.rawptr
%HBRUSH = type %.rawptr
%WPARAM = type i64
%LPARAM = type i64
%LRESULT = type i64
%ATOM = type i16
%BOOL = type i32
%POINT = type {i32, i32}
%WNDPROC = type %LRESULT (%HWND, i32, %WPARAM, %LPARAM)*
%WNDCLASSEXA = type {i32, i32, %LRESULT (%HWND, i32, %WPARAM, %LPARAM)*, i32, i32, %.rawptr, %.rawptr, %.rawptr, %.rawptr, i8*, i8*, %.rawptr}
%MSG = type {%.rawptr, i32, i64, i64, i32, %POINT}
%HGLRC = type %.rawptr
%PROC = type void ()*
%wglCreateContextAttribsARBType = type %HGLRC (%HDC, %.rawptr, i32*)*
%PIXELFORMATDESCRIPTOR = type {i32, i32, i32, i8, i8, i8, i8, i8, i8, i8, i8, i8, i8, i8, i8, i8, i8, i8, i8, i8, i8, i8, i8, i32, i32, i32}
%Vec2 = type <2 x float>
%Vec3 = type <3 x float>
%Vec4 = type <4 x float>
%Mat2 = type <4 x float>
declare void @llvm.memmove.p0i8.p0i8.i64(i8*, i8*, i64, i32, i1) argmemonly nounwind 

@win32_perf_count_freq = global i64 zeroinitializer

define double @time_now() {
entry.-.0:
	%0 = load i64, i64* @win32_perf_count_freq, align 8
	%1 = icmp eq i64 %0, 0
	br i1 %1, label %if.then.-.1, label %if.done.-.2

if.then.-.1:
	call void @llvm.debugtrap()
	br label %if.done.-.2

if.done.-.2:
	%2 = alloca i64, align 8 ; counter
	store i64 zeroinitializer, i64* %2
	%3 = getelementptr inbounds i64, i64* %2
	%4 = call i32 @QueryPerformanceCounter(i64* %3)
	%5 = alloca double, align 8 ; result
	store double zeroinitializer, double* %5
	%6 = load i64, i64* @win32_perf_count_freq, align 8
	%7 = sitofp i64 %6 to double
	%8 = load i64, i64* %2, align 8
	%9 = sitofp i64 %8 to double
	%10 = fdiv double %9, %7
	store double %10, double* %5
	%11 = load double, double* %5, align 8
	ret double %11
}

define void @win32_print_last_error() {
entry.-.0:
	%0 = alloca i64, align 8 ; err_code
	store i64 zeroinitializer, i64* %0
	%1 = call i32 @GetLastError()
	%2 = zext i32 %1 to i64
	store i64 %2, i64* %0
	%3 = load i64, i64* %0, align 8
	%4 = icmp ne i64 %3, 0
	br i1 %4, label %if.then.-.1, label %if.done.-.2

if.then.-.1:
	%5 = getelementptr inbounds [14 x i8], [14 x i8]* @.str0, i64 0, i64 0
	%6 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %6
	%7 = getelementptr inbounds %.string, %.string* %6, i64 0, i32 0
	%8 = getelementptr inbounds %.string, %.string* %6, i64 0, i32 1
	store i8* %5, i8** %7
	store i64 14, i64* %8
	%9 = load %.string, %.string* %6, align 8
	call void @print_string(%.string %9)
	%10 = load i64, i64* %0, align 8
	call void @print_int(i64 %10)
	%11 = getelementptr inbounds [1 x i8], [1 x i8]* @.str1, i64 0, i64 0
	%12 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %12
	%13 = getelementptr inbounds %.string, %.string* %12, i64 0, i32 0
	%14 = getelementptr inbounds %.string, %.string* %12, i64 0, i32 1
	store i8* %11, i8** %13
	store i64 1, i64* %14
	%15 = load %.string, %.string* %12, align 8
	call void @print_string(%.string %15)
	br label %if.done.-.2

if.done.-.2:
	ret void
}

define i8* @to_c_string(%.string %s) {
entry.-.0:
	%0 = alloca %.string, align 8 ; s
	store %.string zeroinitializer, %.string* %0
	store %.string %s, %.string* %0
	%1 = alloca i8*, align 8 ; c_str
	store i8* zeroinitializer, i8** %1
	%2 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 1
	%3 = load i64, i64* %2, align 8
	%4 = add i64 %3, 1
	%5 = call %.rawptr @malloc(i64 %4)
	%6 = bitcast %.rawptr %5 to i8*
	store i8* %6, i8** %1
	%7 = load i8*, i8** %1, align 8
	%8 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 0
	%9 = load i8*, i8** %8, align 8
	%10 = getelementptr i8, i8* %9, i64 0
	%11 = getelementptr inbounds i8, i8* %10
	%12 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 1
	%13 = load i64, i64* %12, align 8
	%14 = call i32 @memcpy(%.rawptr %7, %.rawptr %11, i64 %13)
	%15 = load i8*, i8** %1, align 8
	%16 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 1
	%17 = load i64, i64* %16, align 8
	%18 = getelementptr i8, i8* %15, i64 %17
	store i8 0, i8* %18
	%19 = load i8*, i8** %1, align 8
	ret i8* %19
}

define {%Window, i1} @make_window(%.string %title, i64 %msg, i64 %height, %WNDPROC %window_proc) {
entry.-.0:
	%0 = alloca %.string, align 8 ; title
	store %.string zeroinitializer, %.string* %0
	store %.string %title, %.string* %0
	%1 = alloca i64, align 8 ; msg
	store i64 zeroinitializer, i64* %1
	store i64 %msg, i64* %1
	%2 = alloca i64, align 8 ; height
	store i64 zeroinitializer, i64* %2
	store i64 %height, i64* %2
	%3 = alloca %WNDPROC, align 8 ; window_proc
	store %WNDPROC zeroinitializer, %WNDPROC* %3
	store %WNDPROC %window_proc, %WNDPROC* %3
	%4 = alloca %Window, align 8 ; w
	store %Window zeroinitializer, %Window* %4
	%5 = getelementptr inbounds %Window, %Window* %4, i64 0, i32 0
	%6 = getelementptr inbounds %Window, %Window* %4, i64 0, i32 1
	%7 = load i64, i64* %1, align 8
	%8 = load i64, i64* %2, align 8
	store i64 %7, i64* %5
	store i64 %8, i64* %6
	%9 = alloca %.string, align 8 ; class_name
	store %.string zeroinitializer, %.string* %9
	%10 = getelementptr inbounds [18 x i8], [18 x i8]* @.str2, i64 0, i64 0
	%11 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %11
	%12 = getelementptr inbounds %.string, %.string* %11, i64 0, i32 0
	%13 = getelementptr inbounds %.string, %.string* %11, i64 0, i32 1
	store i8* %10, i8** %12
	store i64 18, i64* %13
	%14 = load %.string, %.string* %11, align 8
	store %.string %14, %.string* %9
	%15 = alloca i8*, align 8 ; c_class_name
	store i8* zeroinitializer, i8** %15
	%16 = getelementptr inbounds %.string, %.string* %9, i64 0, i32 0
	%17 = load i8*, i8** %16, align 8
	%18 = getelementptr i8, i8* %17, i64 0
	%19 = getelementptr inbounds i8, i8* %18
	store i8* %19, i8** %15
	%20 = getelementptr inbounds %Window, %Window* %4, i64 0, i32 7
	%21 = load %.string, %.string* %0, align 8
	%22 = call i8* @to_c_string(%.string %21)
	store i8* %22, i8** %20
	%23 = alloca %HINSTANCE, align 8 ; instance
	store %HINSTANCE zeroinitializer, %HINSTANCE* %23
	%24 = call %HINSTANCE @GetModuleHandleA(i8* null)
	store %HINSTANCE %24, %HINSTANCE* %23
	%25 = getelementptr inbounds %Window, %Window* %4, i64 0, i32 2
	%26 = alloca %WNDCLASSEXA, align 8 
	store %WNDCLASSEXA zeroinitializer, %WNDCLASSEXA* %26
	%27 = getelementptr inbounds %WNDCLASSEXA, %WNDCLASSEXA* %26, i64 0, i32 0
	store i32 80, i32* %27
	%28 = getelementptr inbounds %WNDCLASSEXA, %WNDCLASSEXA* %26, i64 0, i32 1
	store i32 3, i32* %28
	%29 = load %HINSTANCE, %HINSTANCE* %23, align 8
	%30 = getelementptr inbounds %WNDCLASSEXA, %WNDCLASSEXA* %26, i64 0, i32 5
	store %HINSTANCE %29, %HINSTANCE* %30
	%31 = load i8*, i8** %15, align 8
	%32 = getelementptr inbounds %WNDCLASSEXA, %WNDCLASSEXA* %26, i64 0, i32 10
	store i8* %31, i8** %32
	%33 = load %WNDPROC, %WNDPROC* %3, align 8
	%34 = getelementptr inbounds %WNDCLASSEXA, %WNDCLASSEXA* %26, i64 0, i32 2
	store %WNDPROC %33, %WNDPROC* %34
	%35 = load %WNDCLASSEXA, %WNDCLASSEXA* %26, align 8
	store %WNDCLASSEXA %35, %WNDCLASSEXA* %25
	%36 = getelementptr inbounds %Window, %Window* %4, i64 0, i32 2
	%37 = getelementptr inbounds %WNDCLASSEXA, %WNDCLASSEXA* %36
	%38 = call %ATOM @RegisterClassExA(%WNDCLASSEXA* %37)
	%39 = icmp eq i16 %38, 0
	br i1 %39, label %if.then.-.1, label %if.done.-.2

if.then.-.1:
	%40 = alloca {%Window, i1}, align 8 
	store {%Window, i1} zeroinitializer, {%Window, i1}* %40
	%41 = load %Window, %Window* %4, align 8
	%42 = getelementptr inbounds {%Window, i1}, {%Window, i1}* %40, i64 0, i32 0
	store %Window %41, %Window* %42
	%43 = getelementptr inbounds {%Window, i1}, {%Window, i1}* %40, i64 0, i32 1
	store i1 false, i1* %43
	%44 = load {%Window, i1}, {%Window, i1}* %40, align 8
	ret {%Window, i1} %44

if.done.-.2:
	%45 = getelementptr inbounds %Window, %Window* %4, i64 0, i32 4
	%46 = load i8*, i8** %15, align 8
	%47 = getelementptr inbounds %Window, %Window* %4, i64 0, i32 7
	%48 = load i8*, i8** %47, align 8
	%49 = getelementptr inbounds %Window, %Window* %4, i64 0, i32 0
	%50 = load i64, i64* %49, align 8
	%51 = trunc i64 %50 to i32
	%52 = getelementptr inbounds %Window, %Window* %4, i64 0, i32 1
	%53 = load i64, i64* %52, align 8
	%54 = trunc i64 %53 to i32
	%55 = load %HINSTANCE, %HINSTANCE* %23, align 8
	%56 = call %HWND @CreateWindowExA(i32 0, i8* %46, i8* %48, i32 281673728, i32 2147483648, i32 2147483648, i32 %51, i32 %54, %HWND null, %HMENU null, %HINSTANCE %55, %.rawptr null)
	store %HWND %56, %HWND* %45
	%57 = getelementptr inbounds %Window, %Window* %4, i64 0, i32 4
	%58 = load %HWND, %HWND* %57, align 8
	%59 = icmp eq %.rawptr %58, null
	br i1 %59, label %if.then.-.3, label %if.done.-.4

if.then.-.3:
	call void @win32_print_last_error()
	%60 = alloca {%Window, i1}, align 8 
	store {%Window, i1} zeroinitializer, {%Window, i1}* %60
	%61 = load %Window, %Window* %4, align 8
	%62 = getelementptr inbounds {%Window, i1}, {%Window, i1}* %60, i64 0, i32 0
	store %Window %61, %Window* %62
	%63 = getelementptr inbounds {%Window, i1}, {%Window, i1}* %60, i64 0, i32 1
	store i1 false, i1* %63
	%64 = load {%Window, i1}, {%Window, i1}* %60, align 8
	ret {%Window, i1} %64

if.done.-.4:
	%65 = getelementptr inbounds %Window, %Window* %4, i64 0, i32 3
	%66 = getelementptr inbounds %Window, %Window* %4, i64 0, i32 4
	%67 = load %HWND, %HWND* %66, align 8
	%68 = call %HDC @GetDC(%HANDLE %67)
	store %HDC %68, %HDC* %65
	%69 = alloca %PIXELFORMATDESCRIPTOR, align 4 ; pfd
	store %PIXELFORMATDESCRIPTOR zeroinitializer, %PIXELFORMATDESCRIPTOR* %69
	%70 = alloca %PIXELFORMATDESCRIPTOR, align 4 
	store %PIXELFORMATDESCRIPTOR zeroinitializer, %PIXELFORMATDESCRIPTOR* %70
	%71 = getelementptr inbounds %PIXELFORMATDESCRIPTOR, %PIXELFORMATDESCRIPTOR* %70, i64 0, i32 0
	store i32 44, i32* %71
	%72 = getelementptr inbounds %PIXELFORMATDESCRIPTOR, %PIXELFORMATDESCRIPTOR* %70, i64 0, i32 1
	store i32 1, i32* %72
	%73 = getelementptr inbounds %PIXELFORMATDESCRIPTOR, %PIXELFORMATDESCRIPTOR* %70, i64 0, i32 2
	store i32 37, i32* %73
	%74 = getelementptr inbounds %PIXELFORMATDESCRIPTOR, %PIXELFORMATDESCRIPTOR* %70, i64 0, i32 3
	store i8 0, i8* %74
	%75 = getelementptr inbounds %PIXELFORMATDESCRIPTOR, %PIXELFORMATDESCRIPTOR* %70, i64 0, i32 4
	store i8 32, i8* %75
	%76 = getelementptr inbounds %PIXELFORMATDESCRIPTOR, %PIXELFORMATDESCRIPTOR* %70, i64 0, i32 11
	store i8 8, i8* %76
	%77 = getelementptr inbounds %PIXELFORMATDESCRIPTOR, %PIXELFORMATDESCRIPTOR* %70, i64 0, i32 18
	store i8 24, i8* %77
	%78 = getelementptr inbounds %PIXELFORMATDESCRIPTOR, %PIXELFORMATDESCRIPTOR* %70, i64 0, i32 19
	store i8 8, i8* %78
	%79 = getelementptr inbounds %PIXELFORMATDESCRIPTOR, %PIXELFORMATDESCRIPTOR* %70, i64 0, i32 21
	store i8 0, i8* %79
	%80 = load %PIXELFORMATDESCRIPTOR, %PIXELFORMATDESCRIPTOR* %70, align 4
	store %PIXELFORMATDESCRIPTOR %80, %PIXELFORMATDESCRIPTOR* %69
	%81 = getelementptr inbounds %Window, %Window* %4, i64 0, i32 3
	%82 = load %HDC, %HDC* %81, align 8
	%83 = getelementptr inbounds %Window, %Window* %4, i64 0, i32 3
	%84 = load %HDC, %HDC* %83, align 8
	%85 = getelementptr inbounds %PIXELFORMATDESCRIPTOR, %PIXELFORMATDESCRIPTOR* %69
	%86 = call i32 @ChoosePixelFormat(%HDC %84, %PIXELFORMATDESCRIPTOR* %85)
	%87 = call %BOOL @SetPixelFormat(%HDC %82, i32 %86, %PIXELFORMATDESCRIPTOR* null)
	%88 = getelementptr inbounds %Window, %Window* %4, i64 0, i32 5
	%89 = getelementptr inbounds %Window, %Window* %4, i64 0, i32 3
	%90 = load %HDC, %HDC* %89, align 8
	%91 = call %HGLRC @wglCreateContext(%HDC %90)
	store %.rawptr %91, %.rawptr* %88
	%92 = getelementptr inbounds %Window, %Window* %4, i64 0, i32 3
	%93 = load %HDC, %HDC* %92, align 8
	%94 = getelementptr inbounds %Window, %Window* %4, i64 0, i32 5
	%95 = load %.rawptr, %.rawptr* %94, align 8
	%96 = call %BOOL @wglMakeCurrent(%HDC %93, %HGLRC %95)
	%97 = alloca [8 x i32], align 4 ; attribs
	store [8 x i32] zeroinitializer, [8 x i32]* %97
	%98 = alloca [8 x i32], align 4 
	store [8 x i32] zeroinitializer, [8 x i32]* %98
	%99 = getelementptr inbounds [8 x i32], [8 x i32]* %98, i64 0, i32 0
	store i32 8337, i32* %99
	%100 = getelementptr inbounds [8 x i32], [8 x i32]* %98, i64 0, i32 1
	store i32 2, i32* %100
	%101 = getelementptr inbounds [8 x i32], [8 x i32]* %98, i64 0, i32 2
	store i32 8338, i32* %101
	%102 = getelementptr inbounds [8 x i32], [8 x i32]* %98, i64 0, i32 3
	store i32 1, i32* %102
	%103 = getelementptr inbounds [8 x i32], [8 x i32]* %98, i64 0, i32 4
	store i32 37158, i32* %103
	%104 = getelementptr inbounds [8 x i32], [8 x i32]* %98, i64 0, i32 5
	store i32 2, i32* %104
	%105 = getelementptr inbounds [8 x i32], [8 x i32]* %98, i64 0, i32 6
	store i32 0, i32* %105
	%106 = load [8 x i32], [8 x i32]* %98, align 4
	store [8 x i32] %106, [8 x i32]* %97
	%107 = alloca %.string, align 8 ; wgl_string
	store %.string zeroinitializer, %.string* %107
	%108 = getelementptr inbounds [27 x i8], [27 x i8]* @.str3, i64 0, i64 0
	%109 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %109
	%110 = getelementptr inbounds %.string, %.string* %109, i64 0, i32 0
	%111 = getelementptr inbounds %.string, %.string* %109, i64 0, i32 1
	store i8* %108, i8** %110
	store i64 27, i64* %111
	%112 = load %.string, %.string* %109, align 8
	store %.string %112, %.string* %107
	%113 = alloca i8*, align 8 ; c_wgl_string
	store i8* zeroinitializer, i8** %113
	%114 = getelementptr inbounds %.string, %.string* %107, i64 0, i32 0
	%115 = load i8*, i8** %114, align 8
	%116 = getelementptr i8, i8* %115, i64 0
	%117 = getelementptr inbounds i8, i8* %116
	store i8* %117, i8** %113
	%118 = alloca %wglCreateContextAttribsARBType, align 8 ; wglCreateContextAttribsARB
	store %wglCreateContextAttribsARBType zeroinitializer, %wglCreateContextAttribsARBType* %118
	%119 = load i8*, i8** %113, align 8
	%120 = call %PROC @wglGetProcAddress(i8* %119)
	%121 = bitcast void ()* %120 to %HGLRC (%HDC, %.rawptr, i32*)*
	%122 = bitcast %HGLRC (%HDC, %.rawptr, i32*)* %121 to %HGLRC (%HDC, %.rawptr, i32*)*
	store %wglCreateContextAttribsARBType %122, %wglCreateContextAttribsARBType* %118
	%123 = getelementptr inbounds %Window, %Window* %4, i64 0, i32 6
	%124 = load %wglCreateContextAttribsARBType, %wglCreateContextAttribsARBType* %118, align 8
	%125 = getelementptr inbounds %Window, %Window* %4, i64 0, i32 3
	%126 = load %HDC, %HDC* %125, align 8
	%127 = getelementptr inbounds [8 x i32], [8 x i32]* %97, i64 0, i64 0
	%128 = getelementptr i32, i32* %127, i64 0
	%129 = getelementptr inbounds i32, i32* %128
	%130 = call %HGLRC %124(%HDC %126, %.rawptr null, i32* %129)
	store %HGLRC %130, %HGLRC* %123
	%131 = getelementptr inbounds %Window, %Window* %4, i64 0, i32 3
	%132 = load %HDC, %HDC* %131, align 8
	%133 = getelementptr inbounds %Window, %Window* %4, i64 0, i32 6
	%134 = load %HGLRC, %HGLRC* %133, align 8
	%135 = call %BOOL @wglMakeCurrent(%HDC %132, %HGLRC %134)
	%136 = getelementptr inbounds %Window, %Window* %4, i64 0, i32 3
	%137 = load %HDC, %HDC* %136, align 8
	%138 = call %BOOL @SwapBuffers(%HDC %137)
	%139 = alloca {%Window, i1}, align 8 
	store {%Window, i1} zeroinitializer, {%Window, i1}* %139
	%140 = load %Window, %Window* %4, align 8
	%141 = getelementptr inbounds {%Window, i1}, {%Window, i1}* %139, i64 0, i32 0
	store %Window %140, %Window* %141
	%142 = getelementptr inbounds {%Window, i1}, {%Window, i1}* %139, i64 0, i32 1
	store i1 true, i1* %142
	%143 = load {%Window, i1}, {%Window, i1}* %139, align 8
	ret {%Window, i1} %143
}

define void @destroy_window(%Window* %w) {
entry.-.0:
	%0 = alloca %Window*, align 8 ; w
	store %Window* zeroinitializer, %Window** %0
	store %Window* %w, %Window** %0
	%1 = load %Window*, %Window** %0, align 8
	%2 = getelementptr %Window, %Window* %1, i64 0
	%3 = getelementptr inbounds %Window, %Window* %2, i64 0, i32 7
	%4 = load i8*, i8** %3, align 8
	call void @free(%.rawptr %4)
	ret void
}

define void @display_window(%Window* %w) {
entry.-.0:
	%0 = alloca %Window*, align 8 ; w
	store %Window* zeroinitializer, %Window** %0
	store %Window* %w, %Window** %0
	%1 = load %Window*, %Window** %0, align 8
	%2 = getelementptr %Window, %Window* %1, i64 0
	%3 = getelementptr inbounds %Window, %Window* %2, i64 0, i32 3
	%4 = load %HDC, %HDC* %3, align 8
	%5 = call %BOOL @SwapBuffers(%HDC %4)
	ret void
}

define void @main() {
entry.-.0:
	call void @__$startup_runtime()
	call void @print_f64(double 0x402abd70a3d70a3e)
	call void @print_rune(i32 10)
	ret void
}

define %LRESULT @main$win32_proc-0(%HWND %hwnd, i32 %msg, %WPARAM %wparam, %LPARAM %lparam) noinline {
entry.-.0:
	%0 = alloca %HWND, align 8 ; hwnd
	store %HWND zeroinitializer, %HWND* %0
	store %HWND %hwnd, %HWND* %0
	%1 = alloca i32, align 4 ; msg
	store i32 zeroinitializer, i32* %1
	store i32 %msg, i32* %1
	%2 = alloca %WPARAM, align 8 ; wparam
	store %WPARAM zeroinitializer, %WPARAM* %2
	store %WPARAM %wparam, %WPARAM* %2
	%3 = alloca %LPARAM, align 8 ; lparam
	store %LPARAM zeroinitializer, %LPARAM* %3
	store %LPARAM %lparam, %LPARAM* %3
	%4 = load i32, i32* %1, align 4
	%5 = icmp eq i32 %4, 2
	br i1 %5, label %if.then.-.1, label %cmp-or.-.3

if.then.-.1:
	call void @ExitProcess(i32 0)
	ret %LRESULT 0

cmp-or.-.2:
	%6 = load i32, i32* %1, align 4
	%7 = icmp eq i32 %6, 18
	br i1 %7, label %if.then.-.1, label %if.done.-.4

cmp-or.-.3:
	%8 = load i32, i32* %1, align 4
	%9 = icmp eq i32 %8, 16
	br i1 %9, label %if.then.-.1, label %cmp-or.-.2

if.done.-.4:
	%10 = load %HWND, %HWND* %0, align 8
	%11 = load i32, i32* %1, align 4
	%12 = load %WPARAM, %WPARAM* %2, align 8
	%13 = load %LPARAM, %LPARAM* %3, align 8
	%14 = call %LRESULT @DefWindowProcA(%HWND %10, i32 %11, %WPARAM %12, %LPARAM %13)
	ret i64 %14
}

define void @print_string(%.string %s) {
entry.-.0:
	%0 = alloca %.string, align 8 ; s
	store %.string zeroinitializer, %.string* %0
	store %.string %s, %.string* %0
	br label %for.init.-.1

for.init.-.1:
	%1 = alloca i64, align 8 ; i
	store i64 zeroinitializer, i64* %1
	store i64 0, i64* %1
	br label %for.loop.-.3

for.body.-.2:
	%2 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 0
	%3 = load i8*, i8** %2, align 8
	%4 = load i64, i64* %1, align 8
	%5 = getelementptr i8, i8* %3, i64 %4
	%6 = load i8, i8* %5, align 1
	%7 = zext i8 %6 to i32
	%8 = call i32 @putchar(i32 %7)
	br label %for.post.-.4

for.loop.-.3:
	%9 = load i64, i64* %1, align 8
	%10 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 1
	%11 = load i64, i64* %10, align 8
	%12 = icmp slt i64 %9, %11
	br i1 %12, label %for.body.-.2, label %for.done.-.5

for.post.-.4:
	%13 = load i64, i64* %1, align 8
	%14 = add i64 %13, 1
	store i64 %14, i64* %1
	br label %for.loop.-.3

for.done.-.5:
	ret void
}

define void @byte_reverse({i8*, i64, i64} %b) {
entry.-.0:
	%0 = alloca {i8*, i64, i64}, align 8 ; b
	store {i8*, i64, i64} zeroinitializer, {i8*, i64, i64}* %0
	store {i8*, i64, i64} %b, {i8*, i64, i64}* %0
	%1 = alloca i64, align 8 ; n
	store i64 zeroinitializer, i64* %1
	%2 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %0, i64 0, i32 1
	%3 = load i64, i64* %2, align 8
	store i64 %3, i64* %1
	br label %for.init.-.1

for.init.-.1:
	%4 = alloca i64, align 8 ; i
	store i64 zeroinitializer, i64* %4
	store i64 0, i64* %4
	br label %for.loop.-.3

for.body.-.2:
	%5 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %0, i64 0, i32 0
	%6 = load i8*, i8** %5, align 8
	%7 = load i64, i64* %4, align 8
	%8 = getelementptr i8, i8* %6, i64 %7
	%9 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %0, i64 0, i32 0
	%10 = load i8*, i8** %9, align 8
	%11 = load i64, i64* %4, align 8
	%12 = load i64, i64* %1, align 8
	%13 = sub i64 %12, 1
	%14 = sub i64 %13, %11
	%15 = getelementptr i8, i8* %10, i64 %14
	%16 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %0, i64 0, i32 0
	%17 = load i8*, i8** %16, align 8
	%18 = load i64, i64* %4, align 8
	%19 = load i64, i64* %1, align 8
	%20 = sub i64 %19, 1
	%21 = sub i64 %20, %18
	%22 = getelementptr i8, i8* %17, i64 %21
	%23 = load i8, i8* %22, align 1
	%24 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %0, i64 0, i32 0
	%25 = load i8*, i8** %24, align 8
	%26 = load i64, i64* %4, align 8
	%27 = getelementptr i8, i8* %25, i64 %26
	%28 = load i8, i8* %27, align 1
	store i8 %23, i8* %8
	store i8 %28, i8* %15
	br label %for.post.-.4

for.loop.-.3:
	%29 = load i64, i64* %4, align 8
	%30 = load i64, i64* %1, align 8
	%31 = sdiv i64 %30, 2
	%32 = icmp slt i64 %29, %31
	br i1 %32, label %for.body.-.2, label %for.done.-.5

for.post.-.4:
	%33 = load i64, i64* %4, align 8
	%34 = add i64 %33, 1
	store i64 %34, i64* %4
	br label %for.loop.-.3

for.done.-.5:
	ret void
}

define {[4 x i8], i64} @encode_rune(i32 %r) {
entry.-.0:
	%0 = alloca i32, align 4 ; r
	store i32 zeroinitializer, i32* %0
	store i32 %r, i32* %0
	%1 = alloca [4 x i8], align 1 ; buf
	store [4 x i8] zeroinitializer, [4 x i8]* %1
	%2 = alloca i32, align 4 ; i
	store i32 zeroinitializer, i32* %2
	%3 = load i32, i32* %0, align 4
	store i32 %3, i32* %2
	%4 = load i32, i32* %2, align 4
	%5 = icmp ule i32 %4, 127
	br i1 %5, label %if.then.-.1, label %if.done.-.2

if.then.-.1:
	%6 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%7 = getelementptr i8, i8* %6, i64 0
	%8 = load i32, i32* %0, align 4
	%9 = trunc i32 %8 to i8
	store i8 %9, i8* %7
	%10 = alloca {[4 x i8], i64}, align 8 
	store {[4 x i8], i64} zeroinitializer, {[4 x i8], i64}* %10
	%11 = load [4 x i8], [4 x i8]* %1, align 1
	%12 = getelementptr inbounds {[4 x i8], i64}, {[4 x i8], i64}* %10, i64 0, i32 0
	store [4 x i8] %11, [4 x i8]* %12
	%13 = getelementptr inbounds {[4 x i8], i64}, {[4 x i8], i64}* %10, i64 0, i32 1
	store i64 1, i64* %13
	%14 = load {[4 x i8], i64}, {[4 x i8], i64}* %10, align 8
	ret {[4 x i8], i64} %14

if.done.-.2:
	%15 = load i32, i32* %2, align 4
	%16 = icmp ule i32 %15, 2047
	br i1 %16, label %if.then.-.3, label %if.done.-.4

if.then.-.3:
	%17 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%18 = getelementptr i8, i8* %17, i64 0
	%19 = load i32, i32* %0, align 4
	%20 = lshr i32 %19, 6
	%21 = trunc i32 %20 to i8
	%22 = or i8 192, %21
	store i8 %22, i8* %18
	%23 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%24 = getelementptr i8, i8* %23, i64 1
	%25 = load i32, i32* %0, align 4
	%26 = trunc i32 %25 to i8
	%27 = and i8 %26, 63
	%28 = or i8 128, %27
	store i8 %28, i8* %24
	%29 = alloca {[4 x i8], i64}, align 8 
	store {[4 x i8], i64} zeroinitializer, {[4 x i8], i64}* %29
	%30 = load [4 x i8], [4 x i8]* %1, align 1
	%31 = getelementptr inbounds {[4 x i8], i64}, {[4 x i8], i64}* %29, i64 0, i32 0
	store [4 x i8] %30, [4 x i8]* %31
	%32 = getelementptr inbounds {[4 x i8], i64}, {[4 x i8], i64}* %29, i64 0, i32 1
	store i64 2, i64* %32
	%33 = load {[4 x i8], i64}, {[4 x i8], i64}* %29, align 8
	ret {[4 x i8], i64} %33

if.done.-.4:
	%34 = load i32, i32* %2, align 4
	%35 = icmp ugt i32 %34, 1114111
	br i1 %35, label %if.then.-.5, label %cmp-or.-.6

if.then.-.5:
	store i32 65533, i32* %0
	br label %if.done.-.8

cmp-or.-.6:
	%36 = load i32, i32* %2, align 4
	%37 = icmp uge i32 %36, 55296
	br i1 %37, label %cmp-and.-.7, label %if.done.-.8

cmp-and.-.7:
	%38 = load i32, i32* %2, align 4
	%39 = icmp ule i32 %38, 57343
	br i1 %39, label %if.then.-.5, label %if.done.-.8

if.done.-.8:
	%40 = load i32, i32* %2, align 4
	%41 = icmp ule i32 %40, 65535
	br i1 %41, label %if.then.-.9, label %if.done.-.10

if.then.-.9:
	%42 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%43 = getelementptr i8, i8* %42, i64 0
	%44 = load i32, i32* %0, align 4
	%45 = lshr i32 %44, 12
	%46 = trunc i32 %45 to i8
	%47 = or i8 224, %46
	store i8 %47, i8* %43
	%48 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%49 = getelementptr i8, i8* %48, i64 1
	%50 = load i32, i32* %0, align 4
	%51 = lshr i32 %50, 6
	%52 = trunc i32 %51 to i8
	%53 = and i8 %52, 63
	%54 = or i8 128, %53
	store i8 %54, i8* %49
	%55 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%56 = getelementptr i8, i8* %55, i64 2
	%57 = load i32, i32* %0, align 4
	%58 = trunc i32 %57 to i8
	%59 = and i8 %58, 63
	%60 = or i8 128, %59
	store i8 %60, i8* %56
	%61 = alloca {[4 x i8], i64}, align 8 
	store {[4 x i8], i64} zeroinitializer, {[4 x i8], i64}* %61
	%62 = load [4 x i8], [4 x i8]* %1, align 1
	%63 = getelementptr inbounds {[4 x i8], i64}, {[4 x i8], i64}* %61, i64 0, i32 0
	store [4 x i8] %62, [4 x i8]* %63
	%64 = getelementptr inbounds {[4 x i8], i64}, {[4 x i8], i64}* %61, i64 0, i32 1
	store i64 3, i64* %64
	%65 = load {[4 x i8], i64}, {[4 x i8], i64}* %61, align 8
	ret {[4 x i8], i64} %65

if.done.-.10:
	%66 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%67 = getelementptr i8, i8* %66, i64 0
	%68 = load i32, i32* %0, align 4
	%69 = lshr i32 %68, 18
	%70 = trunc i32 %69 to i8
	%71 = or i8 240, %70
	store i8 %71, i8* %67
	%72 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%73 = getelementptr i8, i8* %72, i64 1
	%74 = load i32, i32* %0, align 4
	%75 = lshr i32 %74, 12
	%76 = trunc i32 %75 to i8
	%77 = and i8 %76, 63
	%78 = or i8 128, %77
	store i8 %78, i8* %73
	%79 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%80 = getelementptr i8, i8* %79, i64 2
	%81 = load i32, i32* %0, align 4
	%82 = lshr i32 %81, 6
	%83 = trunc i32 %82 to i8
	%84 = and i8 %83, 63
	%85 = or i8 128, %84
	store i8 %85, i8* %80
	%86 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%87 = getelementptr i8, i8* %86, i64 3
	%88 = load i32, i32* %0, align 4
	%89 = trunc i32 %88 to i8
	%90 = and i8 %89, 63
	%91 = or i8 128, %90
	store i8 %91, i8* %87
	%92 = alloca {[4 x i8], i64}, align 8 
	store {[4 x i8], i64} zeroinitializer, {[4 x i8], i64}* %92
	%93 = load [4 x i8], [4 x i8]* %1, align 1
	%94 = getelementptr inbounds {[4 x i8], i64}, {[4 x i8], i64}* %92, i64 0, i32 0
	store [4 x i8] %93, [4 x i8]* %94
	%95 = getelementptr inbounds {[4 x i8], i64}, {[4 x i8], i64}* %92, i64 0, i32 1
	store i64 4, i64* %95
	%96 = load {[4 x i8], i64}, {[4 x i8], i64}* %92, align 8
	ret {[4 x i8], i64} %96
}

define void @print_rune(i32 %r) {
entry.-.0:
	%0 = alloca i32, align 4 ; r
	store i32 zeroinitializer, i32* %0
	store i32 %r, i32* %0
	%1 = alloca [4 x i8], align 1 ; buf
	store [4 x i8] zeroinitializer, [4 x i8]* %1
	%2 = alloca i64, align 8 ; n
	store i64 zeroinitializer, i64* %2
	%3 = load i32, i32* %0, align 4
	%4 = call {[4 x i8], i64} @encode_rune(i32 %3)
	%5 = extractvalue {[4 x i8], i64} %4, 0
	%6 = extractvalue {[4 x i8], i64} %4, 1
	store [4 x i8] %5, [4 x i8]* %1
	store i64 %6, i64* %2
	%7 = alloca %.string, align 8 ; str
	store %.string zeroinitializer, %.string* %7
	%8 = load i64, i64* %2, align 8
	%9 = sub i64 %8, 0
	%10 = sub i64 4, 0
	%11 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%12 = getelementptr i8, i8* %11, i64 0
	%13 = alloca {i8*, i64, i64}, align 8 
	store {i8*, i64, i64} zeroinitializer, {i8*, i64, i64}* %13
	%14 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %13, i64 0, i32 0
	store i8* %12, i8** %14
	%15 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %13, i64 0, i32 1
	store i64 %9, i64* %15
	%16 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %13, i64 0, i32 2
	store i64 %10, i64* %16
	%17 = load {i8*, i64, i64}, {i8*, i64, i64}* %13, align 8
	%18 = alloca {i8*, i64, i64}, align 8 
	store {i8*, i64, i64} zeroinitializer, {i8*, i64, i64}* %18
	store {i8*, i64, i64} %17, {i8*, i64, i64}* %18
	%19 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %18, i64 0, i32 0
	%20 = load i8*, i8** %19, align 8
	%21 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %18, i64 0, i32 1
	%22 = load i64, i64* %21, align 8
	%23 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %23
	%24 = getelementptr inbounds %.string, %.string* %23, i64 0, i32 0
	%25 = getelementptr inbounds %.string, %.string* %23, i64 0, i32 1
	store i8* %20, i8** %24
	store i64 %22, i64* %25
	%26 = load %.string, %.string* %23, align 8
	store %.string %26, %.string* %7
	%27 = load %.string, %.string* %7, align 8
	call void @print_string(%.string %27)
	ret void
}

define void @print_int(i64 %i) {
entry.-.0:
	%0 = alloca i64, align 8 ; i
	store i64 zeroinitializer, i64* %0
	store i64 %i, i64* %0
	%1 = load i64, i64* %0, align 8
	call void @print_int_base(i64 %1, i64 10)
	ret void
}

define void @print_int_base(i64 %i, i64 %base) {
entry.-.0:
	%0 = alloca i64, align 8 ; i
	store i64 zeroinitializer, i64* %0
	store i64 %i, i64* %0
	%1 = alloca i64, align 8 ; base
	store i64 zeroinitializer, i64* %1
	store i64 %base, i64* %1
	%2 = alloca [65 x i8], align 1 ; buf
	store [65 x i8] zeroinitializer, [65 x i8]* %2
	%3 = alloca i64, align 8 ; len
	store i64 zeroinitializer, i64* %3
	store i64 0, i64* %3
	%4 = alloca i1, align 1 ; negative
	store i1 zeroinitializer, i1* %4
	store i1 false, i1* %4
	%5 = load i64, i64* %0, align 8
	%6 = icmp slt i64 %5, 0
	br i1 %6, label %if.then.-.1, label %if.done.-.2

if.then.-.1:
	store i1 true, i1* %4
	%7 = load i64, i64* %0, align 8
	%8 = sub i64 0, %7
	store i64 %8, i64* %0
	br label %if.done.-.2

if.done.-.2:
	%9 = load i64, i64* %0, align 8
	%10 = icmp eq i64 %9, 0
	br i1 %10, label %if.then.-.3, label %if.done.-.4

if.then.-.3:
	%11 = getelementptr inbounds [65 x i8], [65 x i8]* %2, i64 0, i64 0
	%12 = load i64, i64* %3, align 8
	%13 = getelementptr i8, i8* %11, i64 %12
	store i8 48, i8* %13
	%14 = load i64, i64* %3, align 8
	%15 = add i64 %14, 1
	store i64 %15, i64* %3
	br label %if.done.-.4

if.done.-.4:
	br label %for.loop.-.6

for.body.-.5:
	%16 = getelementptr inbounds [65 x i8], [65 x i8]* %2, i64 0, i64 0
	%17 = load i64, i64* %3, align 8
	%18 = getelementptr i8, i8* %16, i64 %17
	%19 = getelementptr inbounds [64 x i8], [64 x i8]* @.str4, i64 0, i64 0
	%20 = load i64, i64* %1, align 8
	%21 = load i64, i64* %0, align 8
	%22 = srem i64 %21, %20
	%23 = getelementptr i8, i8* %19, i64 %22
	%24 = load i8, i8* %23, align 1
	store i8 %24, i8* %18
	%25 = load i64, i64* %3, align 8
	%26 = add i64 %25, 1
	store i64 %26, i64* %3
	%27 = load i64, i64* %1, align 8
	%28 = load i64, i64* %0, align 8
	%29 = sdiv i64 %28, %27
	store i64 %29, i64* %0
	br label %for.loop.-.6

for.loop.-.6:
	%30 = load i64, i64* %0, align 8
	%31 = icmp sgt i64 %30, 0
	br i1 %31, label %for.body.-.5, label %for.done.-.7

for.done.-.7:
	%32 = load i1, i1* %4, align 1
	br i1 %32, label %if.then.-.8, label %if.done.-.9

if.then.-.8:
	%33 = getelementptr inbounds [65 x i8], [65 x i8]* %2, i64 0, i64 0
	%34 = load i64, i64* %3, align 8
	%35 = getelementptr i8, i8* %33, i64 %34
	store i8 45, i8* %35
	%36 = load i64, i64* %3, align 8
	%37 = add i64 %36, 1
	store i64 %37, i64* %3
	br label %if.done.-.9

if.done.-.9:
	%38 = load i64, i64* %3, align 8
	%39 = sub i64 %38, 0
	%40 = sub i64 65, 0
	%41 = getelementptr inbounds [65 x i8], [65 x i8]* %2, i64 0, i64 0
	%42 = getelementptr i8, i8* %41, i64 0
	%43 = alloca {i8*, i64, i64}, align 8 
	store {i8*, i64, i64} zeroinitializer, {i8*, i64, i64}* %43
	%44 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %43, i64 0, i32 0
	store i8* %42, i8** %44
	%45 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %43, i64 0, i32 1
	store i64 %39, i64* %45
	%46 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %43, i64 0, i32 2
	store i64 %40, i64* %46
	%47 = load {i8*, i64, i64}, {i8*, i64, i64}* %43, align 8
	call void @byte_reverse({i8*, i64, i64} %47)
	%48 = load i64, i64* %3, align 8
	%49 = sub i64 %48, 0
	%50 = sub i64 65, 0
	%51 = getelementptr inbounds [65 x i8], [65 x i8]* %2, i64 0, i64 0
	%52 = getelementptr i8, i8* %51, i64 0
	%53 = alloca {i8*, i64, i64}, align 8 
	store {i8*, i64, i64} zeroinitializer, {i8*, i64, i64}* %53
	%54 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %53, i64 0, i32 0
	store i8* %52, i8** %54
	%55 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %53, i64 0, i32 1
	store i64 %49, i64* %55
	%56 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %53, i64 0, i32 2
	store i64 %50, i64* %56
	%57 = load {i8*, i64, i64}, {i8*, i64, i64}* %53, align 8
	%58 = alloca {i8*, i64, i64}, align 8 
	store {i8*, i64, i64} zeroinitializer, {i8*, i64, i64}* %58
	store {i8*, i64, i64} %57, {i8*, i64, i64}* %58
	%59 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %58, i64 0, i32 0
	%60 = load i8*, i8** %59, align 8
	%61 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %58, i64 0, i32 1
	%62 = load i64, i64* %61, align 8
	%63 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %63
	%64 = getelementptr inbounds %.string, %.string* %63, i64 0, i32 0
	%65 = getelementptr inbounds %.string, %.string* %63, i64 0, i32 1
	store i8* %60, i8** %64
	store i64 %62, i64* %65
	%66 = load %.string, %.string* %63, align 8
	call void @print_string(%.string %66)
	ret void
}

define void @print_uint(i64 %i) {
entry.-.0:
	%0 = alloca i64, align 8 ; i
	store i64 zeroinitializer, i64* %0
	store i64 %i, i64* %0
	%1 = load i64, i64* %0, align 8
	call void @print__uint(i64 %1, i64 10, i64 0, i8 32)
	ret void
}

define void @print__uint(i64 %i, i64 %base, i64 %min_width, i8 %pad_char) {
entry.-.0:
	%0 = alloca i64, align 8 ; i
	store i64 zeroinitializer, i64* %0
	store i64 %i, i64* %0
	%1 = alloca i64, align 8 ; base
	store i64 zeroinitializer, i64* %1
	store i64 %base, i64* %1
	%2 = alloca i64, align 8 ; min_width
	store i64 zeroinitializer, i64* %2
	store i64 %min_width, i64* %2
	%3 = alloca i8, align 1 ; pad_char
	store i8 zeroinitializer, i8* %3
	store i8 %pad_char, i8* %3
	%4 = alloca [65 x i8], align 1 ; buf
	store [65 x i8] zeroinitializer, [65 x i8]* %4
	%5 = alloca i64, align 8 ; len
	store i64 zeroinitializer, i64* %5
	store i64 0, i64* %5
	%6 = load i64, i64* %0, align 8
	%7 = icmp eq i64 %6, 0
	br i1 %7, label %if.then.-.1, label %if.done.-.2

if.then.-.1:
	%8 = getelementptr inbounds [65 x i8], [65 x i8]* %4, i64 0, i64 0
	%9 = load i64, i64* %5, align 8
	%10 = getelementptr i8, i8* %8, i64 %9
	store i8 48, i8* %10
	%11 = load i64, i64* %5, align 8
	%12 = add i64 %11, 1
	store i64 %12, i64* %5
	br label %if.done.-.2

if.done.-.2:
	br label %for.loop.-.4

for.body.-.3:
	%13 = getelementptr inbounds [65 x i8], [65 x i8]* %4, i64 0, i64 0
	%14 = load i64, i64* %5, align 8
	%15 = getelementptr i8, i8* %13, i64 %14
	%16 = getelementptr inbounds [64 x i8], [64 x i8]* @.str5, i64 0, i64 0
	%17 = load i64, i64* %1, align 8
	%18 = load i64, i64* %0, align 8
	%19 = urem i64 %18, %17
	%20 = getelementptr i8, i8* %16, i64 %19
	%21 = load i8, i8* %20, align 1
	store i8 %21, i8* %15
	%22 = load i64, i64* %5, align 8
	%23 = add i64 %22, 1
	store i64 %23, i64* %5
	%24 = load i64, i64* %1, align 8
	%25 = load i64, i64* %0, align 8
	%26 = udiv i64 %25, %24
	store i64 %26, i64* %0
	br label %for.loop.-.4

for.loop.-.4:
	%27 = load i64, i64* %0, align 8
	%28 = icmp ugt i64 %27, 0
	br i1 %28, label %for.body.-.3, label %for.done.-.5

for.done.-.5:
	br label %for.loop.-.7

for.body.-.6:
	%29 = getelementptr inbounds [65 x i8], [65 x i8]* %4, i64 0, i64 0
	%30 = load i64, i64* %5, align 8
	%31 = getelementptr i8, i8* %29, i64 %30
	%32 = load i8, i8* %3, align 1
	store i8 %32, i8* %31
	%33 = load i64, i64* %5, align 8
	%34 = add i64 %33, 1
	store i64 %34, i64* %5
	br label %for.loop.-.7

for.loop.-.7:
	%35 = load i64, i64* %5, align 8
	%36 = load i64, i64* %2, align 8
	%37 = icmp slt i64 %35, %36
	br i1 %37, label %for.body.-.6, label %for.done.-.8

for.done.-.8:
	%38 = load i64, i64* %5, align 8
	%39 = sub i64 %38, 0
	%40 = sub i64 65, 0
	%41 = getelementptr inbounds [65 x i8], [65 x i8]* %4, i64 0, i64 0
	%42 = getelementptr i8, i8* %41, i64 0
	%43 = alloca {i8*, i64, i64}, align 8 
	store {i8*, i64, i64} zeroinitializer, {i8*, i64, i64}* %43
	%44 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %43, i64 0, i32 0
	store i8* %42, i8** %44
	%45 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %43, i64 0, i32 1
	store i64 %39, i64* %45
	%46 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %43, i64 0, i32 2
	store i64 %40, i64* %46
	%47 = load {i8*, i64, i64}, {i8*, i64, i64}* %43, align 8
	call void @byte_reverse({i8*, i64, i64} %47)
	%48 = load i64, i64* %5, align 8
	%49 = sub i64 %48, 0
	%50 = sub i64 65, 0
	%51 = getelementptr inbounds [65 x i8], [65 x i8]* %4, i64 0, i64 0
	%52 = getelementptr i8, i8* %51, i64 0
	%53 = alloca {i8*, i64, i64}, align 8 
	store {i8*, i64, i64} zeroinitializer, {i8*, i64, i64}* %53
	%54 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %53, i64 0, i32 0
	store i8* %52, i8** %54
	%55 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %53, i64 0, i32 1
	store i64 %49, i64* %55
	%56 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %53, i64 0, i32 2
	store i64 %50, i64* %56
	%57 = load {i8*, i64, i64}, {i8*, i64, i64}* %53, align 8
	%58 = alloca {i8*, i64, i64}, align 8 
	store {i8*, i64, i64} zeroinitializer, {i8*, i64, i64}* %58
	store {i8*, i64, i64} %57, {i8*, i64, i64}* %58
	%59 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %58, i64 0, i32 0
	%60 = load i8*, i8** %59, align 8
	%61 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %58, i64 0, i32 1
	%62 = load i64, i64* %61, align 8
	%63 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %63
	%64 = getelementptr inbounds %.string, %.string* %63, i64 0, i32 0
	%65 = getelementptr inbounds %.string, %.string* %63, i64 0, i32 1
	store i8* %60, i8** %64
	store i64 %62, i64* %65
	%66 = load %.string, %.string* %63, align 8
	call void @print_string(%.string %66)
	ret void
}

define void @print_bool(i1 %b) {
entry.-.0:
	%0 = alloca i1, align 1 ; b
	store i1 zeroinitializer, i1* %0
	store i1 %b, i1* %0
	%1 = load i1, i1* %0, align 1
	br i1 %1, label %if.then.-.1, label %if.else.-.2

if.then.-.1:
	%2 = getelementptr inbounds [4 x i8], [4 x i8]* @.str6, i64 0, i64 0
	%3 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %3
	%4 = getelementptr inbounds %.string, %.string* %3, i64 0, i32 0
	%5 = getelementptr inbounds %.string, %.string* %3, i64 0, i32 1
	store i8* %2, i8** %4
	store i64 4, i64* %5
	%6 = load %.string, %.string* %3, align 8
	call void @print_string(%.string %6)
	br label %if.done.-.3

if.else.-.2:
	%7 = getelementptr inbounds [5 x i8], [5 x i8]* @.str7, i64 0, i64 0
	%8 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %8
	%9 = getelementptr inbounds %.string, %.string* %8, i64 0, i32 0
	%10 = getelementptr inbounds %.string, %.string* %8, i64 0, i32 1
	store i8* %7, i8** %9
	store i64 5, i64* %10
	%11 = load %.string, %.string* %8, align 8
	call void @print_string(%.string %11)
	br label %if.done.-.3

if.done.-.3:
	ret void
}

define void @print_pointer(%.rawptr %p) alwaysinline {
entry.-.0:
	%0 = alloca %.rawptr, align 8 ; p
	store %.rawptr zeroinitializer, %.rawptr* %0
	store %.rawptr %p, %.rawptr* %0
	%1 = load %.rawptr, %.rawptr* %0, align 8
	%2 = ptrtoint %.rawptr %1 to i64
	call void @print__uint(i64 %2, i64 16, i64 0, i8 32)
	ret void
}

define void @print_f32(float %f) alwaysinline {
entry.-.0:
	%0 = alloca float, align 4 ; f
	store float zeroinitializer, float* %0
	store float %f, float* %0
	%1 = load float, float* %0, align 4
	%2 = fpext float %1 to double
	call void @print__f64(double %2, i64 7)
	ret void
}

define void @print_f64(double %f) alwaysinline {
entry.-.0:
	%0 = alloca double, align 8 ; f
	store double zeroinitializer, double* %0
	store double %f, double* %0
	%1 = load double, double* %0, align 8
	call void @print__f64(double %1, i64 10)
	ret void
}

define void @print__f64(double %f, i64 %decimal_places) {
entry.-.0:
	%0 = alloca double, align 8 ; f
	store double zeroinitializer, double* %0
	store double %f, double* %0
	%1 = alloca i64, align 8 ; decimal_places
	store i64 zeroinitializer, i64* %1
	store i64 %decimal_places, i64* %1
	%2 = load double, double* %0, align 8
	%3 = fcmp oeq double %2, 0x0000000000000000
	br i1 %3, label %if.then.-.1, label %if.done.-.2

if.then.-.1:
	call void @print_rune(i32 48)
	ret void

if.done.-.2:
	%4 = load double, double* %0, align 8
	%5 = fcmp olt double %4, 0x0000000000000000
	br i1 %5, label %if.then.-.3, label %if.done.-.4

if.then.-.3:
	call void @print_rune(i32 45)
	%6 = load double, double* %0, align 8
	%7 = fsub double 0x0000000000000000, %6
	store double %7, double* %0
	br label %if.done.-.4

if.done.-.4:
	%8 = alloca i64, align 8 ; i
	store i64 zeroinitializer, i64* %8
	%9 = load double, double* %0, align 8
	%10 = fptoui double %9 to i64
	store i64 %10, i64* %8
	%11 = load i64, i64* %8, align 8
	call void @print__f64$print_u64-0(i64 %11)
	%12 = load i64, i64* %8, align 8
	%13 = uitofp i64 %12 to double
	%14 = load double, double* %0, align 8
	%15 = fsub double %14, %13
	store double %15, double* %0
	call void @print_rune(i32 46)
	%16 = alloca double, align 8 ; mult
	store double zeroinitializer, double* %16
	store double 0x4024000000000000, double* %16
	br label %for.init.-.5

for.init.-.5:
	%17 = alloca i64, align 8 ; decimal_places
	store i64 zeroinitializer, i64* %17
	store i64 6, i64* %17
	br label %for.loop.-.7

for.body.-.6:
	%18 = load double, double* %16, align 8
	%19 = load double, double* %0, align 8
	%20 = fmul double %19, %18
	%21 = fptoui double %20 to i64
	store i64 %21, i64* %8
	%22 = load i64, i64* %8, align 8
	call void @print__f64$print_u64-0(i64 %22)
	%23 = load double, double* %16, align 8
	%24 = load i64, i64* %8, align 8
	%25 = uitofp i64 %24 to double
	%26 = fdiv double %25, %23
	%27 = load double, double* %0, align 8
	%28 = fsub double %27, %26
	store double %28, double* %0
	%29 = load double, double* %16, align 8
	%30 = fmul double %29, 0x4024000000000000
	store double %30, double* %16
	br label %for.post.-.8

for.loop.-.7:
	%31 = load i64, i64* %17, align 8
	%32 = icmp sge i64 %31, 0
	br i1 %32, label %for.body.-.6, label %for.done.-.9

for.post.-.8:
	%33 = load i64, i64* %17, align 8
	%34 = sub i64 %33, 1
	store i64 %34, i64* %17
	br label %for.loop.-.7

for.done.-.9:
	ret void
}

define void @print__f64$print_u64-0(i64 %i) {
entry.-.0:
	%0 = alloca i64, align 8 ; i
	store i64 zeroinitializer, i64* %0
	store i64 %i, i64* %0
	%1 = alloca [22 x i8], align 1 ; buf
	store [22 x i8] zeroinitializer, [22 x i8]* %1
	%2 = alloca i64, align 8 ; len
	store i64 zeroinitializer, i64* %2
	store i64 0, i64* %2
	%3 = load i64, i64* %0, align 8
	%4 = icmp eq i64 %3, 0
	br i1 %4, label %if.then.-.1, label %if.done.-.2

if.then.-.1:
	%5 = getelementptr inbounds [22 x i8], [22 x i8]* %1, i64 0, i64 0
	%6 = load i64, i64* %2, align 8
	%7 = getelementptr i8, i8* %5, i64 %6
	store i8 48, i8* %7
	%8 = load i64, i64* %2, align 8
	%9 = add i64 %8, 1
	store i64 %9, i64* %2
	br label %if.done.-.2

if.done.-.2:
	br label %for.loop.-.4

for.body.-.3:
	%10 = getelementptr inbounds [22 x i8], [22 x i8]* %1, i64 0, i64 0
	%11 = load i64, i64* %2, align 8
	%12 = getelementptr i8, i8* %10, i64 %11
	%13 = getelementptr inbounds [10 x i8], [10 x i8]* @.str8, i64 0, i64 0
	%14 = load i64, i64* %0, align 8
	%15 = urem i64 %14, 10
	%16 = getelementptr i8, i8* %13, i64 %15
	%17 = load i8, i8* %16, align 1
	store i8 %17, i8* %12
	%18 = load i64, i64* %2, align 8
	%19 = add i64 %18, 1
	store i64 %19, i64* %2
	%20 = load i64, i64* %0, align 8
	%21 = udiv i64 %20, 10
	store i64 %21, i64* %0
	br label %for.loop.-.4

for.loop.-.4:
	%22 = load i64, i64* %0, align 8
	%23 = icmp ugt i64 %22, 0
	br i1 %23, label %for.body.-.3, label %for.done.-.5

for.done.-.5:
	%24 = load i64, i64* %2, align 8
	%25 = sub i64 %24, 0
	%26 = sub i64 22, 0
	%27 = getelementptr inbounds [22 x i8], [22 x i8]* %1, i64 0, i64 0
	%28 = getelementptr i8, i8* %27, i64 0
	%29 = alloca {i8*, i64, i64}, align 8 
	store {i8*, i64, i64} zeroinitializer, {i8*, i64, i64}* %29
	%30 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %29, i64 0, i32 0
	store i8* %28, i8** %30
	%31 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %29, i64 0, i32 1
	store i64 %25, i64* %31
	%32 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %29, i64 0, i32 2
	store i64 %26, i64* %32
	%33 = load {i8*, i64, i64}, {i8*, i64, i64}* %29, align 8
	call void @byte_reverse({i8*, i64, i64} %33)
	%34 = load i64, i64* %2, align 8
	%35 = sub i64 %34, 0
	%36 = sub i64 22, 0
	%37 = getelementptr inbounds [22 x i8], [22 x i8]* %1, i64 0, i64 0
	%38 = getelementptr i8, i8* %37, i64 0
	%39 = alloca {i8*, i64, i64}, align 8 
	store {i8*, i64, i64} zeroinitializer, {i8*, i64, i64}* %39
	%40 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %39, i64 0, i32 0
	store i8* %38, i8** %40
	%41 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %39, i64 0, i32 1
	store i64 %35, i64* %41
	%42 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %39, i64 0, i32 2
	store i64 %36, i64* %42
	%43 = load {i8*, i64, i64}, {i8*, i64, i64}* %39, align 8
	%44 = alloca {i8*, i64, i64}, align 8 
	store {i8*, i64, i64} zeroinitializer, {i8*, i64, i64}* %44
	store {i8*, i64, i64} %43, {i8*, i64, i64}* %44
	%45 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %44, i64 0, i32 0
	%46 = load i8*, i8** %45, align 8
	%47 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %44, i64 0, i32 1
	%48 = load i64, i64* %47, align 8
	%49 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %49
	%50 = getelementptr inbounds %.string, %.string* %49, i64 0, i32 0
	%51 = getelementptr inbounds %.string, %.string* %49, i64 0, i32 1
	store i8* %46, i8** %50
	store i64 %48, i64* %51
	%52 = load %.string, %.string* %49, align 8
	call void @print_string(%.string %52)
	ret void
}
declare %HANDLE @GetStdHandle(i32 %h) ; foreign
declare i32 @CloseHandle(%HANDLE %h) ; foreign
declare i32 @WriteFileA(%HANDLE %h, %.rawptr %buf, i32 %len, i32* %written_result, %.rawptr %overlapped) ; foreign
declare i32 @GetLastError() ; foreign
declare void @ExitProcess(i32 %exit_code) ; foreign
declare %HWND @GetDesktopWindow() ; foreign
declare i32 @GetCursorPos(%POINT* %p) ; foreign
declare i32 @ScreenToClient(%HWND %h, %POINT* %p) ; foreign
declare %HINSTANCE @GetModuleHandleA(i8* %module_name) ; foreign
declare i32 @QueryPerformanceFrequency(i64* %result) ; foreign
declare i32 @QueryPerformanceCounter(i64* %result) ; foreign

define void @sleep_ms(i32 %ms) {
entry.-.0:
	%0 = alloca i32, align 4 ; ms
	store i32 zeroinitializer, i32* %0
	store i32 %ms, i32* %0
	%1 = load i32, i32* %0, align 4
	%2 = call i32 @Sleep(i32 %1)
	ret void
}
declare i32 @Sleep(i32 %ms) declare void @OutputDebugStringA(i8* %c_str) ; foreign
declare %ATOM @RegisterClassExA(%WNDCLASSEXA* %wc) ; foreign
declare %HWND @CreateWindowExA(i32 %ex_style, i8* %class_name, i8* %title, i32 %style, i32 %x, i32 %y, i32 %w, i32 %h, %HWND %parent, %HMENU %menu, %HINSTANCE %instance, %.rawptr %param) ; foreign
declare %BOOL @ShowWindow(%HWND %hwnd, i32 %cmd_show) ; foreign
declare %BOOL @UpdateWindow(%HWND %hwnd) ; foreign
declare %BOOL @PeekMessageA(%MSG* %msg, %HWND %hwnd, i32 %msg_filter_min, i32 %msg_filter_max, i32 %remove_msg) ; foreign
declare %BOOL @TranslateMessage(%MSG* %msg) ; foreign
declare %LRESULT @DispatchMessageA(%MSG* %msg) ; foreign
declare %LRESULT @DefWindowProcA(%HWND %hwnd, i32 %msg, %WPARAM %wparam, %LPARAM %lparam) ; foreign

define i64 @GetQueryPerformanceFrequency() {
entry.-.0:
	%0 = alloca i64, align 8 ; r
	store i64 zeroinitializer, i64* %0
	%1 = getelementptr inbounds i64, i64* %0
	%2 = call i32 @QueryPerformanceFrequency(i64* %1)
	%3 = load i64, i64* %0, align 8
	ret i64 %3
}
declare %HDC @GetDC(%HANDLE %h) ; foreign
declare %BOOL @SetPixelFormat(%HDC %hdc, i32 %pixel_format, %PIXELFORMATDESCRIPTOR* %pfd) ; foreign
declare i32 @ChoosePixelFormat(%HDC %hdc, %PIXELFORMATDESCRIPTOR* %pfd) ; foreign
declare %BOOL @SwapBuffers(%HDC %hdc) ; foreign
declare %HGLRC @wglCreateContext(%HDC %hdc) ; foreign
declare %BOOL @wglMakeCurrent(%HDC %hdc, %HGLRC %hglrc) ; foreign
declare %PROC @wglGetProcAddress(i8* %c_str) ; foreign
declare %BOOL @wglDeleteContext(%HGLRC %hglrc) ; foreign
declare void @glClear(i32 %mask) ; foreign
declare void @glClearColor(float %r, float %g, float %b, float %a) ; foreign
declare void @glBegin(i32 %mode) ; foreign
declare void @glEnd() ; foreign
declare void @glColor3f(float %r, float %g, float %b) ; foreign
declare void @glColor4f(float %r, float %g, float %b, float %a) ; foreign
declare void @glVertex2f(float %x, float %y) ; foreign
declare void @glVertex3f(float %x, float %y, float %z) ; foreign
declare void @glTexCoord2f(float %u, float %v) ; foreign
declare void @glLoadIdentity() ; foreign
declare void @glOrtho(double %left, double %right, double %bottom, double %top, double %near, double %far) ; foreign
declare void @glBlendFunc(i32 %sfactor, i32 %dfactor) ; foreign
declare void @glEnable(i32 %cap) ; foreign
declare void @glDisable(i32 %cap) ; foreign
declare void @glGenTextures(i32 %count, i32* %result) ; foreign
declare void @glTexParameteri(i32 %target, i32 %pname, i32 %param) ; foreign
declare void @glTexParameterf(i32 %target, i32 %pname, float %param) ; foreign
declare void @glBindTexture(i32 %target, i32 %texture) ; foreign
declare void @glTexImage2D(i32 %target, i32 %level, i32 %internal_format, i32 %width, i32 %height, i32 %border, i32 %format, i32 %_type, %.rawptr %pixels) ; foreign
declare float @llvm.sqrt.f32(float %x) ; foreign
declare float @llvm.sin.f32(float %x) ; foreign
declare float @llvm.cos.f32(float %x) ; foreign

define float @vec2_dot(%Vec2 %a, %Vec2 %b) {
entry.-.0:
	%0 = alloca %Vec2, align 8 ; a
	store %Vec2 zeroinitializer, %Vec2* %0
	store %Vec2 %a, %Vec2* %0
	%1 = alloca %Vec2, align 8 ; b
	store %Vec2 zeroinitializer, %Vec2* %1
	store %Vec2 %b, %Vec2* %1
	%2 = alloca %Vec2, align 8 ; c
	store %Vec2 zeroinitializer, %Vec2* %2
	%3 = load %Vec2, %Vec2* %1, align 8
	%4 = load %Vec2, %Vec2* %0, align 8
	%5 = fmul <2 x float> %4, %3
	store %Vec2 %5, %Vec2* %2
	%6 = load %Vec2, %Vec2* %2, align 8
	%7 = extractelement %Vec2 %6, i64 1
	%8 = load %Vec2, %Vec2* %2, align 8
	%9 = extractelement %Vec2 %8, i64 0
	%10 = fadd float %9, %7
	ret float %10
}

define float @vec3_dot(%Vec3 %a, %Vec3 %b) {
entry.-.0:
	%0 = alloca %Vec3, align 8 ; a
	store %Vec3 zeroinitializer, %Vec3* %0
	store %Vec3 %a, %Vec3* %0
	%1 = alloca %Vec3, align 8 ; b
	store %Vec3 zeroinitializer, %Vec3* %1
	store %Vec3 %b, %Vec3* %1
	%2 = alloca %Vec3, align 8 ; c
	store %Vec3 zeroinitializer, %Vec3* %2
	%3 = load %Vec3, %Vec3* %1, align 8
	%4 = load %Vec3, %Vec3* %0, align 8
	%5 = fmul <3 x float> %4, %3
	store %Vec3 %5, %Vec3* %2
	%6 = load %Vec3, %Vec3* %2, align 8
	%7 = extractelement %Vec3 %6, i64 2
	%8 = load %Vec3, %Vec3* %2, align 8
	%9 = extractelement %Vec3 %8, i64 1
	%10 = load %Vec3, %Vec3* %2, align 8
	%11 = extractelement %Vec3 %10, i64 0
	%12 = fadd float %11, %9
	%13 = fadd float %12, %7
	ret float %13
}

define float @lerp(float %a, float %b, float %t) {
entry.-.0:
	%0 = alloca float, align 4 ; a
	store float zeroinitializer, float* %0
	store float %a, float* %0
	%1 = alloca float, align 4 ; b
	store float zeroinitializer, float* %1
	store float %b, float* %1
	%2 = alloca float, align 4 ; t
	store float zeroinitializer, float* %2
	store float %t, float* %2
	%3 = load float, float* %2, align 4
	%4 = load float, float* %1, align 4
	%5 = fmul float %4, %3
	%6 = load float, float* %2, align 4
	%7 = fsub float 0x3ff0000000000000, %6
	%8 = load float, float* %0, align 4
	%9 = fmul float %8, %7
	%10 = fadd float %9, %5
	ret float %10
}

define float @vec2_mag(%Vec2 %a) {
entry.-.0:
	%0 = alloca %Vec2, align 8 ; a
	store %Vec2 zeroinitializer, %Vec2* %0
	store %Vec2 %a, %Vec2* %0
	%1 = load %Vec2, %Vec2* %0, align 8
	%2 = load %Vec2, %Vec2* %0, align 8
	%3 = call float @vec2_dot(%Vec2 %1, %Vec2 %2)
	%4 = call float @llvm.sqrt.f32(float %3)
	ret float %4
}

define float @vec3_mag(%Vec3 %a) {
entry.-.0:
	%0 = alloca %Vec3, align 8 ; a
	store %Vec3 zeroinitializer, %Vec3* %0
	store %Vec3 %a, %Vec3* %0
	%1 = load %Vec3, %Vec3* %0, align 8
	%2 = load %Vec3, %Vec3* %0, align 8
	%3 = call float @vec3_dot(%Vec3 %1, %Vec3 %2)
	%4 = call float @llvm.sqrt.f32(float %3)
	ret float %4
}
declare i32 @putchar(i32 %c) ; foreign
declare %.rawptr @malloc(i64 %sz) ; foreign
declare void @free(%.rawptr %ptr) ; foreign
declare i32 @memcmp(%.rawptr %dst, %.rawptr %src, i64 %len) ; foreign
declare i32 @memcpy(%.rawptr %dst, %.rawptr %src, i64 %len) ; foreign
declare i32 @memmove(%.rawptr %dst, %.rawptr %src, i64 %len) ; foreign
declare void @llvm.debugtrap() ; foreign

define i1 @__string_eq(%.string %a, %.string %b) {
entry.-.0:
	%0 = alloca %.string, align 8 ; a
	store %.string zeroinitializer, %.string* %0
	store %.string %a, %.string* %0
	%1 = alloca %.string, align 8 ; b
	store %.string zeroinitializer, %.string* %1
	store %.string %b, %.string* %1
	%2 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 1
	%3 = load i64, i64* %2, align 8
	%4 = getelementptr inbounds %.string, %.string* %1, i64 0, i32 1
	%5 = load i64, i64* %4, align 8
	%6 = icmp ne i64 %3, %5
	br i1 %6, label %if.then.-.1, label %if.done.-.2

if.then.-.1:
	ret i1 false

if.done.-.2:
	%7 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 0
	%8 = load i8*, i8** %7, align 8
	%9 = getelementptr i8, i8* %8, i64 0
	%10 = getelementptr inbounds i8, i8* %9
	%11 = getelementptr inbounds %.string, %.string* %1, i64 0, i32 0
	%12 = load i8*, i8** %11, align 8
	%13 = getelementptr i8, i8* %12, i64 0
	%14 = getelementptr inbounds i8, i8* %13
	%15 = icmp eq i8* %10, %14
	br i1 %15, label %if.then.-.3, label %if.done.-.4

if.then.-.3:
	ret i1 true

if.done.-.4:
	%16 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 0
	%17 = load i8*, i8** %16, align 8
	%18 = getelementptr i8, i8* %17, i64 0
	%19 = getelementptr inbounds i8, i8* %18
	%20 = getelementptr inbounds %.string, %.string* %1, i64 0, i32 0
	%21 = load i8*, i8** %20, align 8
	%22 = getelementptr i8, i8* %21, i64 0
	%23 = getelementptr inbounds i8, i8* %22
	%24 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 1
	%25 = load i64, i64* %24, align 8
	%26 = call i32 @memcmp(%.rawptr %19, %.rawptr %23, i64 %25)
	%27 = icmp eq i32 %26, 0
	ret i1 %27
}

define i1 @__string_ne(%.string %a, %.string %b) {
entry.-.0:
	%0 = alloca %.string, align 8 ; a
	store %.string zeroinitializer, %.string* %0
	store %.string %a, %.string* %0
	%1 = alloca %.string, align 8 ; b
	store %.string zeroinitializer, %.string* %1
	store %.string %b, %.string* %1
	%2 = load %.string, %.string* %0, align 8
	%3 = load %.string, %.string* %1, align 8
	%4 = call i1 @__string_eq(%.string %2, %.string %3)
	%5 = xor i1 %4, -1
	ret i1 %5
}

define i64 @__string_cmp(%.string %a, %.string %b) {
entry.-.0:
	%0 = alloca %.string, align 8 ; a
	store %.string zeroinitializer, %.string* %0
	store %.string %a, %.string* %0
	%1 = alloca %.string, align 8 ; b
	store %.string zeroinitializer, %.string* %1
	store %.string %b, %.string* %1
	%2 = alloca i64, align 8 ; min_len
	store i64 zeroinitializer, i64* %2
	%3 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 1
	%4 = load i64, i64* %3, align 8
	store i64 %4, i64* %2
	%5 = getelementptr inbounds %.string, %.string* %1, i64 0, i32 1
	%6 = load i64, i64* %5, align 8
	%7 = load i64, i64* %2, align 8
	%8 = icmp slt i64 %6, %7
	br i1 %8, label %if.then.-.1, label %if.done.-.2

if.then.-.1:
	%9 = getelementptr inbounds %.string, %.string* %1, i64 0, i32 1
	%10 = load i64, i64* %9, align 8
	store i64 %10, i64* %2
	br label %if.done.-.2

if.done.-.2:
	br label %for.init.-.3

for.init.-.3:
	%11 = alloca i64, align 8 ; i
	store i64 zeroinitializer, i64* %11
	store i64 0, i64* %11
	br label %for.loop.-.5

for.body.-.4:
	%12 = alloca i8, align 1 ; x
	store i8 zeroinitializer, i8* %12
	%13 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 0
	%14 = load i8*, i8** %13, align 8
	%15 = load i64, i64* %11, align 8
	%16 = getelementptr i8, i8* %14, i64 %15
	%17 = load i8, i8* %16, align 1
	store i8 %17, i8* %12
	%18 = alloca i8, align 1 ; y
	store i8 zeroinitializer, i8* %18
	%19 = getelementptr inbounds %.string, %.string* %1, i64 0, i32 0
	%20 = load i8*, i8** %19, align 8
	%21 = load i64, i64* %11, align 8
	%22 = getelementptr i8, i8* %20, i64 %21
	%23 = load i8, i8* %22, align 1
	store i8 %23, i8* %18
	%24 = load i8, i8* %12, align 1
	%25 = load i8, i8* %18, align 1
	%26 = icmp ult i8 %24, %25
	br i1 %26, label %if.then.-.7, label %if.else.-.8

for.loop.-.5:
	%27 = load i64, i64* %11, align 8
	%28 = load i64, i64* %2, align 8
	%29 = icmp slt i64 %27, %28
	br i1 %29, label %for.body.-.4, label %for.done.-.12

for.post.-.6:
	%30 = load i64, i64* %11, align 8
	%31 = add i64 %30, 1
	store i64 %31, i64* %11
	br label %for.loop.-.5

if.then.-.7:
	ret i64 -1

if.else.-.8:
	%32 = load i8, i8* %12, align 1
	%33 = load i8, i8* %18, align 1
	%34 = icmp ugt i8 %32, %33
	br i1 %34, label %if.then.-.9, label %if.done.-.10

if.then.-.9:
	ret i64 1

if.done.-.10:
	br label %if.done.-.11

if.done.-.11:
	br label %for.post.-.6

for.done.-.12:
	%35 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 1
	%36 = load i64, i64* %35, align 8
	%37 = getelementptr inbounds %.string, %.string* %1, i64 0, i32 1
	%38 = load i64, i64* %37, align 8
	%39 = icmp slt i64 %36, %38
	br i1 %39, label %if.then.-.13, label %if.else.-.14

if.then.-.13:
	ret i64 -1

if.else.-.14:
	%40 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 1
	%41 = load i64, i64* %40, align 8
	%42 = getelementptr inbounds %.string, %.string* %1, i64 0, i32 1
	%43 = load i64, i64* %42, align 8
	%44 = icmp sgt i64 %41, %43
	br i1 %44, label %if.then.-.15, label %if.done.-.16

if.then.-.15:
	ret i64 1

if.done.-.16:
	br label %if.done.-.17

if.done.-.17:
	ret i64 0
}

define i1 @__string_lt(%.string %a, %.string %b) {
entry.-.0:
	%0 = alloca %.string, align 8 ; a
	store %.string zeroinitializer, %.string* %0
	store %.string %a, %.string* %0
	%1 = alloca %.string, align 8 ; b
	store %.string zeroinitializer, %.string* %1
	store %.string %b, %.string* %1
	%2 = load %.string, %.string* %0, align 8
	%3 = load %.string, %.string* %1, align 8
	%4 = call i64 @__string_cmp(%.string %2, %.string %3)
	%5 = icmp slt i64 %4, 0
	ret i1 %5
}

define i1 @__string_gt(%.string %a, %.string %b) {
entry.-.0:
	%0 = alloca %.string, align 8 ; a
	store %.string zeroinitializer, %.string* %0
	store %.string %a, %.string* %0
	%1 = alloca %.string, align 8 ; b
	store %.string zeroinitializer, %.string* %1
	store %.string %b, %.string* %1
	%2 = load %.string, %.string* %0, align 8
	%3 = load %.string, %.string* %1, align 8
	%4 = call i64 @__string_cmp(%.string %2, %.string %3)
	%5 = icmp sgt i64 %4, 0
	ret i1 %5
}

define i1 @__string_le(%.string %a, %.string %b) {
entry.-.0:
	%0 = alloca %.string, align 8 ; a
	store %.string zeroinitializer, %.string* %0
	store %.string %a, %.string* %0
	%1 = alloca %.string, align 8 ; b
	store %.string zeroinitializer, %.string* %1
	store %.string %b, %.string* %1
	%2 = load %.string, %.string* %0, align 8
	%3 = load %.string, %.string* %1, align 8
	%4 = call i64 @__string_cmp(%.string %2, %.string %3)
	%5 = icmp sle i64 %4, 0
	ret i1 %5
}

define i1 @__string_ge(%.string %a, %.string %b) {
entry.-.0:
	%0 = alloca %.string, align 8 ; a
	store %.string zeroinitializer, %.string* %0
	store %.string %a, %.string* %0
	%1 = alloca %.string, align 8 ; b
	store %.string zeroinitializer, %.string* %1
	store %.string %b, %.string* %1
	%2 = load %.string, %.string* %0, align 8
	%3 = load %.string, %.string* %1, align 8
	%4 = call i64 @__string_cmp(%.string %2, %.string %3)
	%5 = icmp sge i64 %4, 0
	ret i1 %5
}
@.str0 = global [14 x i8] c"GetLastError\3A\20"
@.str1 = global [1 x i8] c"\0A"
@.str2 = global [18 x i8] c"Win32-Odin-Window\00"
@.str3 = global [27 x i8] c"wglCreateContextAttribsARB\00"
@.str4 = global [64 x i8] c"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz\40$"
@.str5 = global [64 x i8] c"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz\40$"
@.str6 = global [4 x i8] c"true"
@.str7 = global [5 x i8] c"false"
@.str8 = global [10 x i8] c"0123456789"

define void @__$startup_runtime() noinline {
entry.-.0:
	%0 = call i64 @GetQueryPerformanceFrequency()
	store i64 %0, i64* @win32_perf_count_freq
	ret void
}
