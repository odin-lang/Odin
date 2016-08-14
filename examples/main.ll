%.string = type {i8*, i64} ; Basic_string

%.rawptr = type i8* ; Basic_rawptr

declare void @llvm.memmove.p0i8.p0i8.i64(i8*, i8*, i64, i32, i1)

define void @main() {
"entry - 0":
	%0 = alloca <8 x float>, align 4 ; a
	store <8 x float> zeroinitializer, <8 x float>* %0
	%1 = alloca <8 x float>, align 4 ; b
	store <8 x float> zeroinitializer, <8 x float>* %1
	%2 = alloca <8 x float>, align 4 
	store <8 x float> zeroinitializer, <8 x float>* %2
	%3 = load <8 x float>, <8 x float>* %2
	%4 = insertelement <8 x float> %3, float 0x3ff0000000000000, i64 0
	%5 = insertelement <8 x float> %4, float 0x4000000000000000, i64 1
	%6 = insertelement <8 x float> %5, float 0x4008000000000000, i64 2
	%7 = insertelement <8 x float> %6, float 0x4010000000000000, i64 3
	%8 = alloca <8 x float>, align 4 
	store <8 x float> zeroinitializer, <8 x float>* %8
	%9 = load <8 x float>, <8 x float>* %8
	%10 = insertelement <8 x float> %9, float 0x3ff0000000000000, i64 0
	%11 = insertelement <8 x float> %10, float 0x4000000000000000, i64 1
	%12 = insertelement <8 x float> %11, float 0x4008000000000000, i64 2
	%13 = insertelement <8 x float> %12, float 0x4010000000000000, i64 3
	store <8 x float> %7, <8 x float>* %0
	store <8 x float> %13, <8 x float>* %1
	%14 = alloca <8 x i1>, align 1 ; c
	store <8 x i1> zeroinitializer, <8 x i1>* %14
	%15 = load <8 x float>, <8 x float>* %0
	%16 = load <8 x float>, <8 x float>* %1
	%17 = fcmp oeq <8 x float> %15, %16
	store <8 x i1> %17, <8 x i1>* %14
	%18 = alloca <32 x i1>, align 1 ; x
	store <32 x i1> zeroinitializer, <32 x i1>* %18
	%19 = alloca <32 x i1>, align 1 
	store <32 x i1> zeroinitializer, <32 x i1>* %19
	%20 = load <32 x i1>, <32 x i1>* %19
	%21 = insertelement <32 x i1> %20, i1 true, i64 0
	%22 = insertelement <32 x i1> %21, i1 false, i64 1
	%23 = insertelement <32 x i1> %22, i1 true, i64 2
	store <32 x i1> %23, <32 x i1>* %18
	%24 = alloca i32, align 4 ; d
	store i32 zeroinitializer, i32* %24
	%25 = alloca i32*, align 8 
	store i32* zeroinitializer, i32** %25
	%26 = getelementptr inbounds <32 x i1>, <32 x i1>* %18, i64 0, i32 0
	%27 = getelementptr i1, i1* %26, i64 0
	%28 = getelementptr inbounds i1, i1* %27
	%29 = bitcast i1* %28 to i32*
	store i32* %29, i32** %25
	%30 = load i32*, i32** %25
	%31 = getelementptr i32, i32* %30
	%32 = load i32, i32* %31
	store i32 %32, i32* %24
	%33 = load i32, i32* %24
	%34 = zext i32 %33 to i64
	call void @print_int_base(i64 %34, i64 2)
	ret void
}

declare i32 @putchar(i32 %c) 	; foreign procedure

define void @print_string(%.string %s) {
"entry - 0":
	%0 = alloca %.string, align 8 ; s
	store %.string zeroinitializer, %.string* %0
	store %.string %s, %.string* %0
	%1 = alloca i64, align 8 ; i
	store i64 zeroinitializer, i64* %1
	store i64 0, i64* %1
	br label %"for.loop - 2"

"for.body - 1":
	%2 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 0
	%3 = load i8*, i8** %2
	%4 = load i64, i64* %1
	%5 = getelementptr i8, i8* %3, i64 %4
	%6 = load i8, i8* %5
	%7 = zext i8 %6 to i32
	%8 = call i32 @putchar(i32 %7)
	br label %"for.post - 3"

"for.loop - 2":
	%9 = load i64, i64* %1
	%10 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 1
	%11 = load i64, i64* %10
	%12 = icmp slt i64 %9, %11
	br i1 %12, label %"for.body - 1", label %"for.done - 4"

"for.post - 3":
	%13 = load i64, i64* %1
	%14 = add i64 %13, 1
	store i64 %14, i64* %1
	br label %"for.loop - 2"

"for.done - 4":
	ret void
}

define void @byte_reverse({i8*, i64, i64} %b) {
"entry - 0":
	%0 = alloca {i8*, i64, i64}, align 8 ; b
	store {i8*, i64, i64} zeroinitializer, {i8*, i64, i64}* %0
	store {i8*, i64, i64} %b, {i8*, i64, i64}* %0
	%1 = alloca i64, align 8 ; n
	store i64 zeroinitializer, i64* %1
	%2 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %0, i64 0, i32 1
	%3 = load i64, i64* %2
	store i64 %3, i64* %1
	%4 = alloca i64, align 8 ; i
	store i64 zeroinitializer, i64* %4
	store i64 0, i64* %4
	br label %"for.loop - 2"

"for.body - 1":
	%5 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %0, i64 0, i32 0
	%6 = load i8*, i8** %5
	%7 = load i64, i64* %4
	%8 = getelementptr i8, i8* %6, i64 %7
	%9 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %0, i64 0, i32 0
	%10 = load i8*, i8** %9
	%11 = load i64, i64* %4
	%12 = load i64, i64* %1
	%13 = sub i64 %12, 1
	%14 = sub i64 %13, %11
	%15 = getelementptr i8, i8* %10, i64 %14
	%16 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %0, i64 0, i32 0
	%17 = load i8*, i8** %16
	%18 = load i64, i64* %4
	%19 = load i64, i64* %1
	%20 = sub i64 %19, 1
	%21 = sub i64 %20, %18
	%22 = getelementptr i8, i8* %17, i64 %21
	%23 = load i8, i8* %22
	%24 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %0, i64 0, i32 0
	%25 = load i8*, i8** %24
	%26 = load i64, i64* %4
	%27 = getelementptr i8, i8* %25, i64 %26
	%28 = load i8, i8* %27
	store i8 %23, i8* %8
	store i8 %28, i8* %15
	br label %"for.post - 3"

"for.loop - 2":
	%29 = load i64, i64* %4
	%30 = load i64, i64* %1
	%31 = sdiv i64 %30, 2
	%32 = icmp slt i64 %29, %31
	br i1 %32, label %"for.body - 1", label %"for.done - 4"

"for.post - 3":
	%33 = load i64, i64* %4
	%34 = add i64 %33, 1
	store i64 %34, i64* %4
	br label %"for.loop - 2"

"for.done - 4":
	ret void
}

define {[4 x i8], i64} @encode_rune(i32 %r) {
"entry - 0":
	%0 = alloca i32, align 4 ; r
	store i32 zeroinitializer, i32* %0
	store i32 %r, i32* %0
	%1 = alloca [4 x i8], align 1 ; buf
	store [4 x i8] zeroinitializer, [4 x i8]* %1
	%2 = alloca i32, align 4 ; i
	store i32 zeroinitializer, i32* %2
	%3 = load i32, i32* %0
	store i32 %3, i32* %2
	%4 = load i32, i32* %2
	%5 = icmp ule i32 %4, 127
	br i1 %5, label %"if.then - 1", label %"if.done - 2"

"if.then - 1":
	%6 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%7 = getelementptr i8, i8* %6, i64 0
	%8 = load i32, i32* %0
	%9 = trunc i32 %8 to i8
	store i8 %9, i8* %7
	%10 = alloca {[4 x i8], i64}, align 8 
	store {[4 x i8], i64} zeroinitializer, {[4 x i8], i64}* %10
	%11 = load [4 x i8], [4 x i8]* %1
	%12 = getelementptr inbounds {[4 x i8], i64}, {[4 x i8], i64}* %10, i64 0, i32 0
	store [4 x i8] %11, [4 x i8]* %12
	%13 = getelementptr inbounds {[4 x i8], i64}, {[4 x i8], i64}* %10, i64 0, i32 1
	store i64 1, i64* %13
	%14 = load {[4 x i8], i64}, {[4 x i8], i64}* %10
	ret {[4 x i8], i64} %14

"if.done - 2":
	%15 = load i32, i32* %2
	%16 = icmp ule i32 %15, 2047
	br i1 %16, label %"if.then - 3", label %"if.done - 4"

"if.then - 3":
	%17 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%18 = getelementptr i8, i8* %17, i64 0
	%19 = load i32, i32* %0
	%20 = lshr i32 %19, 6
	%21 = or i32 192, %20
	%22 = trunc i32 %21 to i8
	store i8 %22, i8* %18
	%23 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%24 = getelementptr i8, i8* %23, i64 1
	%25 = load i32, i32* %0
	%26 = or i32 128, %25
	%27 = trunc i32 %26 to i8
	%28 = and i8 %27, 63
	store i8 %28, i8* %24
	%29 = alloca {[4 x i8], i64}, align 8 
	store {[4 x i8], i64} zeroinitializer, {[4 x i8], i64}* %29
	%30 = load [4 x i8], [4 x i8]* %1
	%31 = getelementptr inbounds {[4 x i8], i64}, {[4 x i8], i64}* %29, i64 0, i32 0
	store [4 x i8] %30, [4 x i8]* %31
	%32 = getelementptr inbounds {[4 x i8], i64}, {[4 x i8], i64}* %29, i64 0, i32 1
	store i64 2, i64* %32
	%33 = load {[4 x i8], i64}, {[4 x i8], i64}* %29
	ret {[4 x i8], i64} %33

"if.done - 4":
	%34 = load i32, i32* %2
	%35 = icmp ugt i32 %34, 1114111
	br i1 %35, label %"if.then - 5", label %"cmp-or - 6"

"if.then - 5":
	store i32 65533, i32* %0
	br label %"if.done - 8"

"cmp-or - 6":
	%36 = load i32, i32* %2
	%37 = icmp uge i32 %36, 55296
	br i1 %37, label %"cmp-and - 7", label %"if.done - 8"

"cmp-and - 7":
	%38 = load i32, i32* %2
	%39 = icmp ule i32 %38, 57343
	br i1 %39, label %"if.then - 5", label %"if.done - 8"

"if.done - 8":
	%40 = load i32, i32* %2
	%41 = icmp ule i32 %40, 65535
	br i1 %41, label %"if.then - 9", label %"if.done - 10"

"if.then - 9":
	%42 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%43 = getelementptr i8, i8* %42, i64 0
	%44 = load i32, i32* %0
	%45 = lshr i32 %44, 12
	%46 = or i32 224, %45
	%47 = trunc i32 %46 to i8
	store i8 %47, i8* %43
	%48 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%49 = getelementptr i8, i8* %48, i64 1
	%50 = load i32, i32* %0
	%51 = lshr i32 %50, 6
	%52 = or i32 128, %51
	%53 = trunc i32 %52 to i8
	%54 = and i8 %53, 63
	store i8 %54, i8* %49
	%55 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%56 = getelementptr i8, i8* %55, i64 2
	%57 = load i32, i32* %0
	%58 = or i32 128, %57
	%59 = trunc i32 %58 to i8
	%60 = and i8 %59, 63
	store i8 %60, i8* %56
	%61 = alloca {[4 x i8], i64}, align 8 
	store {[4 x i8], i64} zeroinitializer, {[4 x i8], i64}* %61
	%62 = load [4 x i8], [4 x i8]* %1
	%63 = getelementptr inbounds {[4 x i8], i64}, {[4 x i8], i64}* %61, i64 0, i32 0
	store [4 x i8] %62, [4 x i8]* %63
	%64 = getelementptr inbounds {[4 x i8], i64}, {[4 x i8], i64}* %61, i64 0, i32 1
	store i64 3, i64* %64
	%65 = load {[4 x i8], i64}, {[4 x i8], i64}* %61
	ret {[4 x i8], i64} %65

"if.done - 10":
	%66 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%67 = getelementptr i8, i8* %66, i64 0
	%68 = load i32, i32* %0
	%69 = lshr i32 %68, 18
	%70 = or i32 240, %69
	%71 = trunc i32 %70 to i8
	store i8 %71, i8* %67
	%72 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%73 = getelementptr i8, i8* %72, i64 1
	%74 = load i32, i32* %0
	%75 = lshr i32 %74, 12
	%76 = or i32 128, %75
	%77 = trunc i32 %76 to i8
	%78 = and i8 %77, 63
	store i8 %78, i8* %73
	%79 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%80 = getelementptr i8, i8* %79, i64 2
	%81 = load i32, i32* %0
	%82 = lshr i32 %81, 6
	%83 = or i32 128, %82
	%84 = trunc i32 %83 to i8
	%85 = and i8 %84, 63
	store i8 %85, i8* %80
	%86 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%87 = getelementptr i8, i8* %86, i64 3
	%88 = load i32, i32* %0
	%89 = or i32 128, %88
	%90 = trunc i32 %89 to i8
	%91 = and i8 %90, 63
	store i8 %91, i8* %87
	%92 = alloca {[4 x i8], i64}, align 8 
	store {[4 x i8], i64} zeroinitializer, {[4 x i8], i64}* %92
	%93 = load [4 x i8], [4 x i8]* %1
	%94 = getelementptr inbounds {[4 x i8], i64}, {[4 x i8], i64}* %92, i64 0, i32 0
	store [4 x i8] %93, [4 x i8]* %94
	%95 = getelementptr inbounds {[4 x i8], i64}, {[4 x i8], i64}* %92, i64 0, i32 1
	store i64 4, i64* %95
	%96 = load {[4 x i8], i64}, {[4 x i8], i64}* %92
	ret {[4 x i8], i64} %96
}

define void @print_rune(i32 %r) {
"entry - 0":
	%0 = alloca i32, align 4 ; r
	store i32 zeroinitializer, i32* %0
	store i32 %r, i32* %0
	%1 = alloca [4 x i8], align 1 ; buf
	store [4 x i8] zeroinitializer, [4 x i8]* %1
	%2 = alloca i64, align 8 ; n
	store i64 zeroinitializer, i64* %2
	%3 = load i32, i32* %0
	%4 = call {[4 x i8], i64} @encode_rune(i32 %3)
	%5 = extractvalue {[4 x i8], i64} %4, 0
	%6 = extractvalue {[4 x i8], i64} %4, 1
	store [4 x i8] %5, [4 x i8]* %1
	store i64 %6, i64* %2
	%7 = alloca %.string, align 8 ; str
	store %.string zeroinitializer, %.string* %7
	%8 = load i64, i64* %2
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
	%17 = load {i8*, i64, i64}, {i8*, i64, i64}* %13
	%18 = alloca {i8*, i64, i64}, align 8 
	store {i8*, i64, i64} zeroinitializer, {i8*, i64, i64}* %18
	store {i8*, i64, i64} %17, {i8*, i64, i64}* %18
	%19 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %18, i64 0, i32 0
	%20 = load i8*, i8** %19
	%21 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %18, i64 0, i32 1
	%22 = load i64, i64* %21
	%23 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %23
	%24 = getelementptr inbounds %.string, %.string* %23, i64 0, i32 0
	%25 = getelementptr inbounds %.string, %.string* %23, i64 0, i32 1
	store i8* %20, i8** %24
	store i64 %22, i64* %25
	%26 = load %.string, %.string* %23
	store %.string %26, %.string* %7
	%27 = load %.string, %.string* %7
	call void @print_string(%.string %27)
	ret void
}

define void @print_int(i64 %i) {
"entry - 0":
	%0 = alloca i64, align 8 ; i
	store i64 zeroinitializer, i64* %0
	store i64 %i, i64* %0
	%1 = load i64, i64* %0
	call void @print_int_base(i64 %1, i64 10)
	ret void
}

define void @print_int_base(i64 %i, i64 %base) {
"entry - 0":
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
	%5 = load i64, i64* %0
	%6 = icmp slt i64 %5, 0
	br i1 %6, label %"if.then - 1", label %"if.done - 2"

"if.then - 1":
	store i1 true, i1* %4
	%7 = load i64, i64* %0
	%8 = sub i64 0, %7
	store i64 %8, i64* %0
	br label %"if.done - 2"

"if.done - 2":
	%9 = load i64, i64* %0
	%10 = icmp eq i64 %9, 0
	br i1 %10, label %"if.then - 3", label %"if.done - 4"

"if.then - 3":
	%11 = getelementptr inbounds [65 x i8], [65 x i8]* %2, i64 0, i64 0
	%12 = load i64, i64* %3
	%13 = getelementptr i8, i8* %11, i64 %12
	store i8 48, i8* %13
	%14 = load i64, i64* %3
	%15 = add i64 %14, 1
	store i64 %15, i64* %3
	br label %"if.done - 4"

"if.done - 4":
	br label %"for.loop - 6"

"for.body - 5":
	%16 = getelementptr inbounds [65 x i8], [65 x i8]* %2, i64 0, i64 0
	%17 = load i64, i64* %3
	%18 = getelementptr i8, i8* %16, i64 %17
	%19 = getelementptr inbounds [64 x i8], [64 x i8]* @.str0, i64 0, i64 0
	%20 = load i64, i64* %1
	%21 = load i64, i64* %0
	%22 = srem i64 %21, %20
	%23 = getelementptr i8, i8* %19, i64 %22
	%24 = load i8, i8* %23
	store i8 %24, i8* %18
	%25 = load i64, i64* %3
	%26 = add i64 %25, 1
	store i64 %26, i64* %3
	%27 = load i64, i64* %1
	%28 = load i64, i64* %0
	%29 = sdiv i64 %28, %27
	store i64 %29, i64* %0
	br label %"for.loop - 6"

"for.loop - 6":
	%30 = load i64, i64* %0
	%31 = icmp sgt i64 %30, 0
	br i1 %31, label %"for.body - 5", label %"for.done - 7"

"for.done - 7":
	%32 = load i1, i1* %4
	br i1 %32, label %"if.then - 8", label %"if.done - 9"

"if.then - 8":
	%33 = getelementptr inbounds [65 x i8], [65 x i8]* %2, i64 0, i64 0
	%34 = load i64, i64* %3
	%35 = getelementptr i8, i8* %33, i64 %34
	store i8 45, i8* %35
	%36 = load i64, i64* %3
	%37 = add i64 %36, 1
	store i64 %37, i64* %3
	br label %"if.done - 9"

"if.done - 9":
	%38 = load i64, i64* %3
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
	%47 = load {i8*, i64, i64}, {i8*, i64, i64}* %43
	call void @byte_reverse({i8*, i64, i64} %47)
	%48 = load i64, i64* %3
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
	%57 = load {i8*, i64, i64}, {i8*, i64, i64}* %53
	%58 = alloca {i8*, i64, i64}, align 8 
	store {i8*, i64, i64} zeroinitializer, {i8*, i64, i64}* %58
	store {i8*, i64, i64} %57, {i8*, i64, i64}* %58
	%59 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %58, i64 0, i32 0
	%60 = load i8*, i8** %59
	%61 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %58, i64 0, i32 1
	%62 = load i64, i64* %61
	%63 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %63
	%64 = getelementptr inbounds %.string, %.string* %63, i64 0, i32 0
	%65 = getelementptr inbounds %.string, %.string* %63, i64 0, i32 1
	store i8* %60, i8** %64
	store i64 %62, i64* %65
	%66 = load %.string, %.string* %63
	call void @print_string(%.string %66)
	ret void
}

define void @print_uint(i64 %i) {
"entry - 0":
	%0 = alloca i64, align 8 ; i
	store i64 zeroinitializer, i64* %0
	store i64 %i, i64* %0
	%1 = load i64, i64* %0
	call void @print_uint_base(i64 %1, i64 10)
	ret void
}

define void @print_uint_base(i64 %i, i64 %base) {
"entry - 0":
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
	%5 = load i64, i64* %0
	%6 = icmp ult i64 %5, 0
	br i1 %6, label %"if.then - 1", label %"if.done - 2"

"if.then - 1":
	store i1 true, i1* %4
	%7 = load i64, i64* %0
	%8 = sub i64 0, %7
	store i64 %8, i64* %0
	br label %"if.done - 2"

"if.done - 2":
	%9 = load i64, i64* %0
	%10 = icmp eq i64 %9, 0
	br i1 %10, label %"if.then - 3", label %"if.done - 4"

"if.then - 3":
	%11 = getelementptr inbounds [65 x i8], [65 x i8]* %2, i64 0, i64 0
	%12 = load i64, i64* %3
	%13 = getelementptr i8, i8* %11, i64 %12
	store i8 48, i8* %13
	%14 = load i64, i64* %3
	%15 = add i64 %14, 1
	store i64 %15, i64* %3
	br label %"if.done - 4"

"if.done - 4":
	br label %"for.loop - 6"

"for.body - 5":
	%16 = getelementptr inbounds [65 x i8], [65 x i8]* %2, i64 0, i64 0
	%17 = load i64, i64* %3
	%18 = getelementptr i8, i8* %16, i64 %17
	%19 = getelementptr inbounds [64 x i8], [64 x i8]* @.str1, i64 0, i64 0
	%20 = load i64, i64* %1
	%21 = load i64, i64* %0
	%22 = urem i64 %21, %20
	%23 = getelementptr i8, i8* %19, i64 %22
	%24 = load i8, i8* %23
	store i8 %24, i8* %18
	%25 = load i64, i64* %3
	%26 = add i64 %25, 1
	store i64 %26, i64* %3
	%27 = load i64, i64* %1
	%28 = load i64, i64* %0
	%29 = udiv i64 %28, %27
	store i64 %29, i64* %0
	br label %"for.loop - 6"

"for.loop - 6":
	%30 = load i64, i64* %0
	%31 = icmp ugt i64 %30, 0
	br i1 %31, label %"for.body - 5", label %"for.done - 7"

"for.done - 7":
	%32 = load i1, i1* %4
	br i1 %32, label %"if.then - 8", label %"if.done - 9"

"if.then - 8":
	%33 = getelementptr inbounds [65 x i8], [65 x i8]* %2, i64 0, i64 0
	%34 = load i64, i64* %3
	%35 = getelementptr i8, i8* %33, i64 %34
	store i8 45, i8* %35
	%36 = load i64, i64* %3
	%37 = add i64 %36, 1
	store i64 %37, i64* %3
	br label %"if.done - 9"

"if.done - 9":
	%38 = load i64, i64* %3
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
	%47 = load {i8*, i64, i64}, {i8*, i64, i64}* %43
	call void @byte_reverse({i8*, i64, i64} %47)
	%48 = load i64, i64* %3
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
	%57 = load {i8*, i64, i64}, {i8*, i64, i64}* %53
	%58 = alloca {i8*, i64, i64}, align 8 
	store {i8*, i64, i64} zeroinitializer, {i8*, i64, i64}* %58
	store {i8*, i64, i64} %57, {i8*, i64, i64}* %58
	%59 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %58, i64 0, i32 0
	%60 = load i8*, i8** %59
	%61 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %58, i64 0, i32 1
	%62 = load i64, i64* %61
	%63 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %63
	%64 = getelementptr inbounds %.string, %.string* %63, i64 0, i32 0
	%65 = getelementptr inbounds %.string, %.string* %63, i64 0, i32 1
	store i8* %60, i8** %64
	store i64 %62, i64* %65
	%66 = load %.string, %.string* %63
	call void @print_string(%.string %66)
	ret void
}

define void @print_f64(double %f) {
"entry - 0":
	%0 = alloca double, align 8 ; f
	store double zeroinitializer, double* %0
	store double %f, double* %0
	%1 = alloca [128 x i8], align 1 ; buf
	store [128 x i8] zeroinitializer, [128 x i8]* %1
	%2 = load double, double* %0
	%3 = fcmp oeq double %2, 0x0000000000000000
	br i1 %3, label %"if.then - 1", label %"if.else - 2"

"if.then - 1":
	%4 = alloca i64, align 8 ; value
	store i64 zeroinitializer, i64* %4
	br label %"if.done - 5"

"if.else - 2":
	%5 = load double, double* %0
	%6 = fcmp olt double %5, 0x0000000000000000
	br i1 %6, label %"if.then - 3", label %"if.done - 4"

"if.then - 3":
	call void @print_rune(i32 45)
	br label %"if.done - 4"

"if.done - 4":
	call void @print_rune(i32 48)
	br label %"if.done - 5"

"if.done - 5":
	ret void
}

@.str0 = global [64 x i8] c"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz\40$"
@.str1 = global [64 x i8] c"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz\40$"
