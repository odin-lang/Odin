%.string = type {i8*, i64} ; Basic_string

%.rawptr = type i8* ; Basic_rawptr

declare void @llvm.memmove.p0i8.p0i8.i64(i8*, i8*, i64, i32, i1)

define void @main() {
entry.-.0:
	%0 = alloca <16 x i1>, align 1 ; v
	store <16 x i1> zeroinitializer, <16 x i1>* %0
	%1 = alloca <16 x i1>, align 1 
	store <16 x i1> zeroinitializer, <16 x i1>* %1
	%2 = load <16 x i1>, <16 x i1>* %1
	%3 = insertelement <16 x i1> %2, i1 true, i64 0
	%4 = insertelement <16 x i1> %3, i1 false, i64 1
	%5 = insertelement <16 x i1> %4, i1 false, i64 2
	%6 = insertelement <16 x i1> %5, i1 false, i64 3
	%7 = insertelement <16 x i1> %6, i1 false, i64 4
	%8 = insertelement <16 x i1> %7, i1 false, i64 5
	%9 = insertelement <16 x i1> %8, i1 false, i64 6
	%10 = insertelement <16 x i1> %9, i1 false, i64 7
	%11 = insertelement <16 x i1> %10, i1 false, i64 8
	%12 = insertelement <16 x i1> %11, i1 false, i64 9
	%13 = insertelement <16 x i1> %12, i1 false, i64 10
	%14 = insertelement <16 x i1> %13, i1 false, i64 11
	%15 = insertelement <16 x i1> %14, i1 false, i64 12
	%16 = insertelement <16 x i1> %15, i1 false, i64 13
	%17 = insertelement <16 x i1> %16, i1 false, i64 14
	%18 = insertelement <16 x i1> %17, i1 true, i64 15
	store <16 x i1> %18, <16 x i1>* %0
	%19 = load <16 x i1>, <16 x i1>* %0
	%20 = extractelement <16 x i1> %19, i64 0
	call void @print_bool(i1 %20)
	call void @main$nl-0()
	%21 = load <16 x i1>, <16 x i1>* %0
	%22 = extractelement <16 x i1> %21, i64 1
	call void @print_bool(i1 %22)
	call void @main$nl-0()
	ret void
}

define void @main$nl-0() {
entry.-.0:
	call void @print_rune(i32 10)
	ret void
}

define void @print_hello() {
entry.-.0:
	%0 = getelementptr inbounds [26 x i8], [26 x i8]* @.str0, i64 0, i64 0
	%1 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %1
	%2 = getelementptr inbounds %.string, %.string* %1, i64 0, i32 0
	%3 = getelementptr inbounds %.string, %.string* %1, i64 0, i32 1
	store i8* %0, i8** %2
	store i64 26, i64* %3
	%4 = load %.string, %.string* %1
	call void @print_string(%.string %4)
	%5 = getelementptr inbounds [26 x i8], [26 x i8]* @.str1, i64 0, i64 0
	%6 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %6
	%7 = getelementptr inbounds %.string, %.string* %6, i64 0, i32 0
	%8 = getelementptr inbounds %.string, %.string* %6, i64 0, i32 1
	store i8* %5, i8** %7
	store i64 26, i64* %8
	%9 = load %.string, %.string* %6
	call void @print_string(%.string %9)
	%10 = getelementptr inbounds [25 x i8], [25 x i8]* @.str2, i64 0, i64 0
	%11 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %11
	%12 = getelementptr inbounds %.string, %.string* %11, i64 0, i32 0
	%13 = getelementptr inbounds %.string, %.string* %11, i64 0, i32 1
	store i8* %10, i8** %12
	store i64 25, i64* %13
	%14 = load %.string, %.string* %11
	call void @print_string(%.string %14)
	%15 = getelementptr inbounds [27 x i8], [27 x i8]* @.str3, i64 0, i64 0
	%16 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %16
	%17 = getelementptr inbounds %.string, %.string* %16, i64 0, i32 0
	%18 = getelementptr inbounds %.string, %.string* %16, i64 0, i32 1
	store i8* %15, i8** %17
	store i64 27, i64* %18
	%19 = load %.string, %.string* %16
	call void @print_string(%.string %19)
	%20 = getelementptr inbounds [24 x i8], [24 x i8]* @.str4, i64 0, i64 0
	%21 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %21
	%22 = getelementptr inbounds %.string, %.string* %21, i64 0, i32 0
	%23 = getelementptr inbounds %.string, %.string* %21, i64 0, i32 1
	store i8* %20, i8** %22
	store i64 24, i64* %23
	%24 = load %.string, %.string* %21
	call void @print_string(%.string %24)
	%25 = getelementptr inbounds [42 x i8], [42 x i8]* @.str5, i64 0, i64 0
	%26 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %26
	%27 = getelementptr inbounds %.string, %.string* %26, i64 0, i32 0
	%28 = getelementptr inbounds %.string, %.string* %26, i64 0, i32 1
	store i8* %25, i8** %27
	store i64 42, i64* %28
	%29 = load %.string, %.string* %26
	call void @print_string(%.string %29)
	%30 = getelementptr inbounds [24 x i8], [24 x i8]* @.str6, i64 0, i64 0
	%31 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %31
	%32 = getelementptr inbounds %.string, %.string* %31, i64 0, i32 0
	%33 = getelementptr inbounds %.string, %.string* %31, i64 0, i32 1
	store i8* %30, i8** %32
	store i64 24, i64* %33
	%34 = load %.string, %.string* %31
	call void @print_string(%.string %34)
	%35 = getelementptr inbounds [35 x i8], [35 x i8]* @.str7, i64 0, i64 0
	%36 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %36
	%37 = getelementptr inbounds %.string, %.string* %36, i64 0, i32 0
	%38 = getelementptr inbounds %.string, %.string* %36, i64 0, i32 1
	store i8* %35, i8** %37
	store i64 35, i64* %38
	%39 = load %.string, %.string* %36
	call void @print_string(%.string %39)
	%40 = getelementptr inbounds [33 x i8], [33 x i8]* @.str8, i64 0, i64 0
	%41 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %41
	%42 = getelementptr inbounds %.string, %.string* %41, i64 0, i32 0
	%43 = getelementptr inbounds %.string, %.string* %41, i64 0, i32 1
	store i8* %40, i8** %42
	store i64 33, i64* %43
	%44 = load %.string, %.string* %41
	call void @print_string(%.string %44)
	%45 = getelementptr inbounds [24 x i8], [24 x i8]* @.str9, i64 0, i64 0
	%46 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %46
	%47 = getelementptr inbounds %.string, %.string* %46, i64 0, i32 0
	%48 = getelementptr inbounds %.string, %.string* %46, i64 0, i32 1
	store i8* %45, i8** %47
	store i64 24, i64* %48
	%49 = load %.string, %.string* %46
	call void @print_string(%.string %49)
	%50 = getelementptr inbounds [45 x i8], [45 x i8]* @.stra, i64 0, i64 0
	%51 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %51
	%52 = getelementptr inbounds %.string, %.string* %51, i64 0, i32 0
	%53 = getelementptr inbounds %.string, %.string* %51, i64 0, i32 1
	store i8* %50, i8** %52
	store i64 45, i64* %53
	%54 = load %.string, %.string* %51
	call void @print_string(%.string %54)
	%55 = getelementptr inbounds [24 x i8], [24 x i8]* @.strb, i64 0, i64 0
	%56 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %56
	%57 = getelementptr inbounds %.string, %.string* %56, i64 0, i32 0
	%58 = getelementptr inbounds %.string, %.string* %56, i64 0, i32 1
	store i8* %55, i8** %57
	store i64 24, i64* %58
	%59 = load %.string, %.string* %56
	call void @print_string(%.string %59)
	ret void
}

declare i32 @putchar(i32 %c) 	; foreign procedure

declare %.rawptr @malloc(i64 %sz) 	; foreign procedure

declare void @free(%.rawptr %ptr) 	; foreign procedure

define void @print_string(%.string %s) {
entry.-.0:
	%0 = alloca %.string, align 8 ; s
	store %.string zeroinitializer, %.string* %0
	store %.string %s, %.string* %0
	%1 = alloca i64, align 8 ; i
	store i64 zeroinitializer, i64* %1
	store i64 0, i64* %1
	br label %for.loop.-.2

for.body.-.1:
	%2 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 0
	%3 = load i8*, i8** %2
	%4 = load i64, i64* %1
	%5 = getelementptr i8, i8* %3, i64 %4
	%6 = load i8, i8* %5
	%7 = zext i8 %6 to i32
	%8 = call i32 @putchar(i32 %7)
	br label %for.post.-.3

for.loop.-.2:
	%9 = load i64, i64* %1
	%10 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 1
	%11 = load i64, i64* %10
	%12 = icmp slt i64 %9, %11
	br i1 %12, label %for.body.-.1, label %for.done.-.4

for.post.-.3:
	%13 = load i64, i64* %1
	%14 = add i64 %13, 1
	store i64 %14, i64* %1
	br label %for.loop.-.2

for.done.-.4:
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
	%3 = load i64, i64* %2
	store i64 %3, i64* %1
	%4 = alloca i64, align 8 ; i
	store i64 zeroinitializer, i64* %4
	store i64 0, i64* %4
	br label %for.loop.-.2

for.body.-.1:
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
	br label %for.post.-.3

for.loop.-.2:
	%29 = load i64, i64* %4
	%30 = load i64, i64* %1
	%31 = sdiv i64 %30, 2
	%32 = icmp slt i64 %29, %31
	br i1 %32, label %for.body.-.1, label %for.done.-.4

for.post.-.3:
	%33 = load i64, i64* %4
	%34 = add i64 %33, 1
	store i64 %34, i64* %4
	br label %for.loop.-.2

for.done.-.4:
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
	%3 = load i32, i32* %0
	store i32 %3, i32* %2
	%4 = load i32, i32* %2
	%5 = icmp ule i32 %4, 127
	br i1 %5, label %if.then.-.1, label %if.done.-.2

if.then.-.1:
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

if.done.-.2:
	%15 = load i32, i32* %2
	%16 = icmp ule i32 %15, 2047
	br i1 %16, label %if.then.-.3, label %if.done.-.4

if.then.-.3:
	%17 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%18 = getelementptr i8, i8* %17, i64 0
	%19 = load i32, i32* %0
	%20 = lshr i32 %19, 6
	%21 = trunc i32 %20 to i8
	%22 = or i8 192, %21
	store i8 %22, i8* %18
	%23 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%24 = getelementptr i8, i8* %23, i64 1
	%25 = load i32, i32* %0
	%26 = trunc i32 %25 to i8
	%27 = and i8 %26, 63
	%28 = or i8 128, %27
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

if.done.-.4:
	%34 = load i32, i32* %2
	%35 = icmp ugt i32 %34, 1114111
	br i1 %35, label %if.then.-.5, label %cmp-or.-.6

if.then.-.5:
	store i32 65533, i32* %0
	br label %if.done.-.8

cmp-or.-.6:
	%36 = load i32, i32* %2
	%37 = icmp uge i32 %36, 55296
	br i1 %37, label %cmp-and.-.7, label %if.done.-.8

cmp-and.-.7:
	%38 = load i32, i32* %2
	%39 = icmp ule i32 %38, 57343
	br i1 %39, label %if.then.-.5, label %if.done.-.8

if.done.-.8:
	%40 = load i32, i32* %2
	%41 = icmp ule i32 %40, 65535
	br i1 %41, label %if.then.-.9, label %if.done.-.10

if.then.-.9:
	%42 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%43 = getelementptr i8, i8* %42, i64 0
	%44 = load i32, i32* %0
	%45 = lshr i32 %44, 12
	%46 = trunc i32 %45 to i8
	%47 = or i8 224, %46
	store i8 %47, i8* %43
	%48 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%49 = getelementptr i8, i8* %48, i64 1
	%50 = load i32, i32* %0
	%51 = lshr i32 %50, 6
	%52 = trunc i32 %51 to i8
	%53 = and i8 %52, 63
	%54 = or i8 128, %53
	store i8 %54, i8* %49
	%55 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%56 = getelementptr i8, i8* %55, i64 2
	%57 = load i32, i32* %0
	%58 = trunc i32 %57 to i8
	%59 = and i8 %58, 63
	%60 = or i8 128, %59
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

if.done.-.10:
	%66 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%67 = getelementptr i8, i8* %66, i64 0
	%68 = load i32, i32* %0
	%69 = lshr i32 %68, 18
	%70 = trunc i32 %69 to i8
	%71 = or i8 240, %70
	store i8 %71, i8* %67
	%72 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%73 = getelementptr i8, i8* %72, i64 1
	%74 = load i32, i32* %0
	%75 = lshr i32 %74, 12
	%76 = trunc i32 %75 to i8
	%77 = and i8 %76, 63
	%78 = or i8 128, %77
	store i8 %78, i8* %73
	%79 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%80 = getelementptr i8, i8* %79, i64 2
	%81 = load i32, i32* %0
	%82 = lshr i32 %81, 6
	%83 = trunc i32 %82 to i8
	%84 = and i8 %83, 63
	%85 = or i8 128, %84
	store i8 %85, i8* %80
	%86 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%87 = getelementptr i8, i8* %86, i64 3
	%88 = load i32, i32* %0
	%89 = trunc i32 %88 to i8
	%90 = and i8 %89, 63
	%91 = or i8 128, %90
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
entry.-.0:
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
entry.-.0:
	%0 = alloca i64, align 8 ; i
	store i64 zeroinitializer, i64* %0
	store i64 %i, i64* %0
	%1 = load i64, i64* %0
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
	%5 = load i64, i64* %0
	%6 = icmp slt i64 %5, 0
	br i1 %6, label %if.then.-.1, label %if.done.-.2

if.then.-.1:
	store i1 true, i1* %4
	%7 = load i64, i64* %0
	%8 = sub i64 0, %7
	store i64 %8, i64* %0
	br label %if.done.-.2

if.done.-.2:
	%9 = load i64, i64* %0
	%10 = icmp eq i64 %9, 0
	br i1 %10, label %if.then.-.3, label %if.done.-.4

if.then.-.3:
	%11 = getelementptr inbounds [65 x i8], [65 x i8]* %2, i64 0, i64 0
	%12 = load i64, i64* %3
	%13 = getelementptr i8, i8* %11, i64 %12
	store i8 48, i8* %13
	%14 = load i64, i64* %3
	%15 = add i64 %14, 1
	store i64 %15, i64* %3
	br label %if.done.-.4

if.done.-.4:
	br label %for.loop.-.6

for.body.-.5:
	%16 = getelementptr inbounds [65 x i8], [65 x i8]* %2, i64 0, i64 0
	%17 = load i64, i64* %3
	%18 = getelementptr i8, i8* %16, i64 %17
	%19 = getelementptr inbounds [64 x i8], [64 x i8]* @.strc, i64 0, i64 0
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
	br label %for.loop.-.6

for.loop.-.6:
	%30 = load i64, i64* %0
	%31 = icmp sgt i64 %30, 0
	br i1 %31, label %for.body.-.5, label %for.done.-.7

for.done.-.7:
	%32 = load i1, i1* %4
	br i1 %32, label %if.then.-.8, label %if.done.-.9

if.then.-.8:
	%33 = getelementptr inbounds [65 x i8], [65 x i8]* %2, i64 0, i64 0
	%34 = load i64, i64* %3
	%35 = getelementptr i8, i8* %33, i64 %34
	store i8 45, i8* %35
	%36 = load i64, i64* %3
	%37 = add i64 %36, 1
	store i64 %37, i64* %3
	br label %if.done.-.9

if.done.-.9:
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
entry.-.0:
	%0 = alloca i64, align 8 ; i
	store i64 zeroinitializer, i64* %0
	store i64 %i, i64* %0
	%1 = load i64, i64* %0
	call void @print_uint_base(i64 %1, i64 10)
	ret void
}

define void @print_uint_base(i64 %i, i64 %base) {
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
	%5 = load i64, i64* %0
	%6 = icmp ult i64 %5, 0
	br i1 %6, label %if.then.-.1, label %if.done.-.2

if.then.-.1:
	store i1 true, i1* %4
	%7 = load i64, i64* %0
	%8 = sub i64 0, %7
	store i64 %8, i64* %0
	br label %if.done.-.2

if.done.-.2:
	%9 = load i64, i64* %0
	%10 = icmp eq i64 %9, 0
	br i1 %10, label %if.then.-.3, label %if.done.-.4

if.then.-.3:
	%11 = getelementptr inbounds [65 x i8], [65 x i8]* %2, i64 0, i64 0
	%12 = load i64, i64* %3
	%13 = getelementptr i8, i8* %11, i64 %12
	store i8 48, i8* %13
	%14 = load i64, i64* %3
	%15 = add i64 %14, 1
	store i64 %15, i64* %3
	br label %if.done.-.4

if.done.-.4:
	br label %for.loop.-.6

for.body.-.5:
	%16 = getelementptr inbounds [65 x i8], [65 x i8]* %2, i64 0, i64 0
	%17 = load i64, i64* %3
	%18 = getelementptr i8, i8* %16, i64 %17
	%19 = getelementptr inbounds [64 x i8], [64 x i8]* @.strd, i64 0, i64 0
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
	br label %for.loop.-.6

for.loop.-.6:
	%30 = load i64, i64* %0
	%31 = icmp ugt i64 %30, 0
	br i1 %31, label %for.body.-.5, label %for.done.-.7

for.done.-.7:
	%32 = load i1, i1* %4
	br i1 %32, label %if.then.-.8, label %if.done.-.9

if.then.-.8:
	%33 = getelementptr inbounds [65 x i8], [65 x i8]* %2, i64 0, i64 0
	%34 = load i64, i64* %3
	%35 = getelementptr i8, i8* %33, i64 %34
	store i8 45, i8* %35
	%36 = load i64, i64* %3
	%37 = add i64 %36, 1
	store i64 %37, i64* %3
	br label %if.done.-.9

if.done.-.9:
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

define void @print_bool(i1 %b) {
entry.-.0:
	%0 = alloca i1, align 1 ; b
	store i1 zeroinitializer, i1* %0
	store i1 %b, i1* %0
	%1 = load i1, i1* %0
	br i1 %1, label %if.then.-.1, label %if.else.-.2

if.then.-.1:
	%2 = getelementptr inbounds [4 x i8], [4 x i8]* @.stre, i64 0, i64 0
	%3 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %3
	%4 = getelementptr inbounds %.string, %.string* %3, i64 0, i32 0
	%5 = getelementptr inbounds %.string, %.string* %3, i64 0, i32 1
	store i8* %2, i8** %4
	store i64 4, i64* %5
	%6 = load %.string, %.string* %3
	call void @print_string(%.string %6)
	br label %if.done.-.3

if.else.-.2:
	%7 = getelementptr inbounds [5 x i8], [5 x i8]* @.strf, i64 0, i64 0
	%8 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %8
	%9 = getelementptr inbounds %.string, %.string* %8, i64 0, i32 0
	%10 = getelementptr inbounds %.string, %.string* %8, i64 0, i32 1
	store i8* %7, i8** %9
	store i64 5, i64* %10
	%11 = load %.string, %.string* %8
	call void @print_string(%.string %11)
	br label %if.done.-.3

if.done.-.3:
	ret void
}

@.str0 = global [26 x i8] c"Chinese\20\20\20\20-\20\E4\BD\A0\E5\A5\BD\E4\B8\96\E7\95\8C\0A"
@.str1 = global [26 x i8] c"Dutch\20\20\20\20\20\20-\20Hello\20wereld\0A"
@.str2 = global [25 x i8] c"English\20\20\20\20-\20Hello\20world\0A"
@.str3 = global [27 x i8] c"French\20\20\20\20\20-\20Bonjour\20monde\0A"
@.str4 = global [24 x i8] c"German\20\20\20\20\20-\20Hallo\20Welt\0A"
@.str5 = global [42 x i8] c"Greek\20\20\20\20\20\20-\20\CE\B3\CE\B5\CE\B9\CE\AC\20\CF\83\CE\BF\CF\85\20\CE\BA\CF\8C\CF\83\CE\BC\CE\BF\CF\82\0A"
@.str6 = global [24 x i8] c"Italian\20\20\20\20-\20Ciao\20mondo\0A"
@.str7 = global [35 x i8] c"Japanese\20\20\20-\20\E3\81\93\E3\82\93\E3\81\AB\E3\81\A1\E3\81\AF\E4\B8\96\E7\95\8C\0A"
@.str8 = global [33 x i8] c"Korean\20\20\20\20\20-\20\EC\97\AC\EB\B3\B4\EC\84\B8\EC\9A\94\20\EC\84\B8\EA\B3\84\0A"
@.str9 = global [24 x i8] c"Portuguese\20-\20Ol\C3\A1\20mundo\0A"
@.stra = global [45 x i8] c"Russian\20\20\20\20-\20\D0\97\D0\B4\D1\80\D0\B0\D0\B2\D1\81\D1\82\D0\B2\D1\83\D0\BB\D1\82\D0\B5\20\D0\BC\D0\B8\D1\80\0A"
@.strb = global [24 x i8] c"Spanish\20\20\20\20-\20Hola\20mundo\0A"
@.strc = global [64 x i8] c"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz\40$"
@.strd = global [64 x i8] c"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz\40$"
@.stre = global [4 x i8] c"true"
@.strf = global [5 x i8] c"false"
