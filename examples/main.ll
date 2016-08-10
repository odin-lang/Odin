%.string = type {i8*, i64} ; Basic_string

%.rawptr = type i8* ; Basic_rawptr

define void @main() {
"entry - 0":
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
	%2 = alloca i32, align 4 ; c
	store i32 zeroinitializer, i32* %2
	%3 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 0
	%4 = load i8*, i8** %3
	%5 = load i64, i64* %1
	%6 = getelementptr i8, i8* %4, i64 %5
	%7 = load i8, i8* %6
	%8 = zext i8 %7 to i32
	store i32 %8, i32* %2
	%9 = load i32, i32* %2
	%10 = call i32 @putchar(i32 %9)
	br label %"for.post - 3"

"for.loop - 2":
	%11 = load i64, i64* %1
	%12 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 1
	%13 = load i64, i64* %12
	%14 = icmp slt i64 %11, %13
	br i1 %14, label %"for.body - 1", label %"for.done - 4"

"for.post - 3":
	%15 = load i64, i64* %1
	%16 = add i64 %15, 1
	store i64 %16, i64* %1
	br label %"for.loop - 2"

"for.done - 4":
	ret void
}

define void @string_byte_reverse(%.string %s) {
"entry - 0":
	%0 = alloca %.string, align 8 ; s
	store %.string zeroinitializer, %.string* %0
	store %.string %s, %.string* %0
	%1 = alloca i64, align 8 ; n
	store i64 zeroinitializer, i64* %1
	%2 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 1
	%3 = load i64, i64* %2
	store i64 %3, i64* %1
	%4 = alloca i64, align 8 ; i
	store i64 zeroinitializer, i64* %4
	store i64 0, i64* %4
	br label %"for.loop - 2"

"for.body - 1":
	%5 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 0
	%6 = load i8*, i8** %5
	%7 = load i64, i64* %4
	%8 = getelementptr i8, i8* %6, i64 %7
	%9 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 0
	%10 = load i8*, i8** %9
	%11 = load i64, i64* %4
	%12 = load i64, i64* %1
	%13 = sub i64 %12, 1
	%14 = sub i64 %13, %11
	%15 = getelementptr i8, i8* %10, i64 %14
	%16 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 0
	%17 = load i8*, i8** %16
	%18 = load i64, i64* %4
	%19 = load i64, i64* %1
	%20 = sub i64 %19, 1
	%21 = sub i64 %20, %18
	%22 = getelementptr i8, i8* %17, i64 %21
	%23 = load i8, i8* %22
	%24 = getelementptr inbounds %.string, %.string* %0, i64 0, i32 0
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

define i64 @encode_rune({i8*, i64, i64} %buf, i32 %r) {
"entry - 0":
	%0 = alloca {i8*, i64, i64}, align 8 ; buf
	store {i8*, i64, i64} zeroinitializer, {i8*, i64, i64}* %0
	store {i8*, i64, i64} %buf, {i8*, i64, i64}* %0
	%1 = alloca i32, align 4 ; r
	store i32 zeroinitializer, i32* %1
	store i32 %r, i32* %1
	%2 = alloca i32, align 4 ; i
	store i32 zeroinitializer, i32* %2
	%3 = load i32, i32* %1
	store i32 %3, i32* %2
	%4 = load i32, i32* %2
	%5 = icmp ule i32 %4, 127
	br i1 %5, label %"if.then - 1", label %"if.done - 2"

"if.then - 1":
	%6 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %0, i64 0, i32 0
	%7 = load i8*, i8** %6
	%8 = getelementptr i8, i8* %7, i64 0
	%9 = load i32, i32* %1
	%10 = trunc i32 %9 to i8
	store i8 %10, i8* %8
	ret i64 1

"if.done - 2":
	%11 = load i32, i32* %2
	%12 = icmp ule i32 %11, 2047
	br i1 %12, label %"if.then - 3", label %"if.done - 4"

"if.then - 3":
	%13 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %0, i64 0, i32 0
	%14 = load i8*, i8** %13
	%15 = getelementptr i8, i8* %14, i64 0
	%16 = load i32, i32* %1
	%17 = lshr i32 %16, 6
	%18 = trunc i32 %17 to i8
	%19 = or i8 192, %18
	store i8 %19, i8* %15
	%20 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %0, i64 0, i32 0
	%21 = load i8*, i8** %20
	%22 = getelementptr i8, i8* %21, i64 1
	%23 = load i32, i32* %1
	%24 = trunc i32 %23 to i8
	%25 = and i8 %24, 63
	%26 = or i8 128, %25
	store i8 %26, i8* %22
	ret i64 2

"if.done - 4":
	%27 = load i32, i32* %2
	%28 = icmp ugt i32 %27, 1114111
	br i1 %28, label %"if.then - 5", label %"cmp-or - 6"

"if.then - 5":
	store i32 65533, i32* %1
	%29 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %0, i64 0, i32 0
	%30 = load i8*, i8** %29
	%31 = getelementptr i8, i8* %30, i64 0
	%32 = load i32, i32* %1
	%33 = lshr i32 %32, 12
	%34 = trunc i32 %33 to i8
	%35 = or i8 224, %34
	store i8 %35, i8* %31
	%36 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %0, i64 0, i32 0
	%37 = load i8*, i8** %36
	%38 = getelementptr i8, i8* %37, i64 1
	%39 = load i32, i32* %1
	%40 = lshr i32 %39, 6
	%41 = trunc i32 %40 to i8
	%42 = and i8 %41, 63
	%43 = or i8 128, %42
	store i8 %43, i8* %38
	%44 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %0, i64 0, i32 0
	%45 = load i8*, i8** %44
	%46 = getelementptr i8, i8* %45, i64 2
	%47 = load i32, i32* %1
	%48 = trunc i32 %47 to i8
	%49 = and i8 %48, 63
	%50 = or i8 128, %49
	store i8 %50, i8* %46
	ret i64 3

"cmp-or - 6":
	%51 = load i32, i32* %2
	%52 = icmp uge i32 %51, 55296
	br i1 %52, label %"cmp-and - 7", label %"if.done - 8"

"cmp-and - 7":
	%53 = load i32, i32* %2
	%54 = icmp ule i32 %53, 57343
	br i1 %54, label %"if.then - 5", label %"if.done - 8"

"if.done - 8":
	%55 = load i32, i32* %2
	%56 = icmp ule i32 %55, 65535
	br i1 %56, label %"if.then - 9", label %"if.done - 10"

"if.then - 9":
	%57 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %0, i64 0, i32 0
	%58 = load i8*, i8** %57
	%59 = getelementptr i8, i8* %58, i64 0
	%60 = load i32, i32* %1
	%61 = lshr i32 %60, 12
	%62 = trunc i32 %61 to i8
	%63 = or i8 224, %62
	store i8 %63, i8* %59
	%64 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %0, i64 0, i32 0
	%65 = load i8*, i8** %64
	%66 = getelementptr i8, i8* %65, i64 1
	%67 = load i32, i32* %1
	%68 = lshr i32 %67, 6
	%69 = trunc i32 %68 to i8
	%70 = and i8 %69, 63
	%71 = or i8 128, %70
	store i8 %71, i8* %66
	%72 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %0, i64 0, i32 0
	%73 = load i8*, i8** %72
	%74 = getelementptr i8, i8* %73, i64 2
	%75 = load i32, i32* %1
	%76 = trunc i32 %75 to i8
	%77 = and i8 %76, 63
	%78 = or i8 128, %77
	store i8 %78, i8* %74
	ret i64 3

"if.done - 10":
	%79 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %0, i64 0, i32 0
	%80 = load i8*, i8** %79
	%81 = getelementptr i8, i8* %80, i64 0
	%82 = load i32, i32* %1
	%83 = lshr i32 %82, 18
	%84 = trunc i32 %83 to i8
	%85 = or i8 240, %84
	store i8 %85, i8* %81
	%86 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %0, i64 0, i32 0
	%87 = load i8*, i8** %86
	%88 = getelementptr i8, i8* %87, i64 1
	%89 = load i32, i32* %1
	%90 = lshr i32 %89, 12
	%91 = trunc i32 %90 to i8
	%92 = and i8 %91, 63
	%93 = or i8 128, %92
	store i8 %93, i8* %88
	%94 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %0, i64 0, i32 0
	%95 = load i8*, i8** %94
	%96 = getelementptr i8, i8* %95, i64 2
	%97 = load i32, i32* %1
	%98 = lshr i32 %97, 6
	%99 = trunc i32 %98 to i8
	%100 = and i8 %99, 63
	%101 = or i8 128, %100
	store i8 %101, i8* %96
	%102 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %0, i64 0, i32 0
	%103 = load i8*, i8** %102
	%104 = getelementptr i8, i8* %103, i64 3
	%105 = load i32, i32* %1
	%106 = trunc i32 %105 to i8
	%107 = and i8 %106, 63
	%108 = or i8 128, %107
	store i8 %108, i8* %104
	ret i64 4
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
	%3 = sub i64 4, 0
	%4 = sub i64 4, 0
	%5 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%6 = getelementptr i8, i8* %5, i64 0
	%7 = alloca {i8*, i64, i64}, align 8 
	store {i8*, i64, i64} zeroinitializer, {i8*, i64, i64}* %7
	%8 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %7, i64 0, i32 0
	store i8* %6, i8** %8
	%9 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %7, i64 0, i32 1
	store i64 %3, i64* %9
	%10 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %7, i64 0, i32 2
	store i64 %4, i64* %10
	%11 = load {i8*, i64, i64}, {i8*, i64, i64}* %7
	%12 = load i32, i32* %0
	%13 = call i64 @encode_rune({i8*, i64, i64} %11, i32 %12)
	store i64 %13, i64* %2
	%14 = alloca %.string, align 8 ; str
	store %.string zeroinitializer, %.string* %14
	%15 = load i64, i64* %2
	%16 = sub i64 %15, 0
	%17 = sub i64 4, 0
	%18 = getelementptr inbounds [4 x i8], [4 x i8]* %1, i64 0, i64 0
	%19 = getelementptr i8, i8* %18, i64 0
	%20 = alloca {i8*, i64, i64}, align 8 
	store {i8*, i64, i64} zeroinitializer, {i8*, i64, i64}* %20
	%21 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %20, i64 0, i32 0
	store i8* %19, i8** %21
	%22 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %20, i64 0, i32 1
	store i64 %16, i64* %22
	%23 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %20, i64 0, i32 2
	store i64 %17, i64* %23
	%24 = load {i8*, i64, i64}, {i8*, i64, i64}* %20
	%25 = alloca {i8*, i64, i64}, align 8 
	store {i8*, i64, i64} zeroinitializer, {i8*, i64, i64}* %25
	store {i8*, i64, i64} %24, {i8*, i64, i64}* %25
	%26 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %25, i64 0, i32 0
	%27 = load i8*, i8** %26
	%28 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %25, i64 0, i32 1
	%29 = load i64, i64* %28
	%30 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %30
	%31 = getelementptr inbounds %.string, %.string* %30, i64 0, i32 0
	%32 = getelementptr inbounds %.string, %.string* %30, i64 0, i32 1
	store i8* %27, i8** %31
	store i64 %29, i64* %32
	%33 = load %.string, %.string* %30
	store %.string %33, %.string* %14
	%34 = load %.string, %.string* %14
	call void @print_string(%.string %34)
	ret void
}

define void @print_int(i64 %i, i64 %base) {
"entry - 0":
	%0 = alloca i64, align 8 ; i
	store i64 zeroinitializer, i64* %0
	store i64 %i, i64* %0
	%1 = alloca i64, align 8 ; base
	store i64 zeroinitializer, i64* %1
	store i64 %base, i64* %1
	%2 = alloca [21 x i8], align 1 ; buf
	store [21 x i8] zeroinitializer, [21 x i8]* %2
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
	%10 = icmp sgt i64 %9, 0
	br i1 %10, label %"if.then - 3", label %"if.else - 4"

"if.then - 3":
	br label %"for.loop - 6"

"if.else - 4":
	%11 = getelementptr inbounds [21 x i8], [21 x i8]* %2, i64 0, i64 0
	%12 = load i64, i64* %3
	%13 = getelementptr i8, i8* %11, i64 %12
	store i8 0, i8* %13
	%14 = load i64, i64* %3
	%15 = add i64 %14, 1
	store i64 %15, i64* %3
	br label %"if.done - 8"

"for.body - 5":
	%16 = alloca i8, align 1 ; c
	store i8 zeroinitializer, i8* %16
	%17 = getelementptr inbounds [64 x i8], [64 x i8]* @.str0, i64 0, i64 0
	%18 = load i64, i64* %1
	%19 = load i64, i64* %0
	%20 = srem i64 %19, %18
	%21 = getelementptr i8, i8* %17, i64 %20
	%22 = load i8, i8* %21
	store i8 %22, i8* %16
	%23 = getelementptr inbounds [21 x i8], [21 x i8]* %2, i64 0, i64 0
	%24 = load i64, i64* %3
	%25 = getelementptr i8, i8* %23, i64 %24
	%26 = load i8, i8* %16
	store i8 %26, i8* %25
	%27 = load i64, i64* %3
	%28 = add i64 %27, 1
	store i64 %28, i64* %3
	%29 = load i64, i64* %1
	%30 = load i64, i64* %0
	%31 = sdiv i64 %30, %29
	store i64 %31, i64* %0
	br label %"for.loop - 6"

"for.loop - 6":
	%32 = load i64, i64* %0
	%33 = icmp sgt i64 %32, 0
	br i1 %33, label %"for.body - 5", label %"for.done - 7"

"for.done - 7":
	br label %"if.done - 8"

"if.done - 8":
	%34 = load i1, i1* %4
	br i1 %34, label %"if.then - 9", label %"if.done - 10"

"if.then - 9":
	%35 = getelementptr inbounds [21 x i8], [21 x i8]* %2, i64 0, i64 0
	%36 = load i64, i64* %3
	%37 = getelementptr i8, i8* %35, i64 %36
	store i8 0, i8* %37
	%38 = load i64, i64* %3
	%39 = add i64 %38, 1
	store i64 %39, i64* %3
	br label %"if.done - 10"

"if.done - 10":
	%40 = alloca %.string, align 8 ; str
	store %.string zeroinitializer, %.string* %40
	%41 = load i64, i64* %3
	%42 = sub i64 %41, 0
	%43 = sub i64 21, 0
	%44 = getelementptr inbounds [21 x i8], [21 x i8]* %2, i64 0, i64 0
	%45 = getelementptr i8, i8* %44, i64 0
	%46 = alloca {i8*, i64, i64}, align 8 
	store {i8*, i64, i64} zeroinitializer, {i8*, i64, i64}* %46
	%47 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %46, i64 0, i32 0
	store i8* %45, i8** %47
	%48 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %46, i64 0, i32 1
	store i64 %42, i64* %48
	%49 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %46, i64 0, i32 2
	store i64 %43, i64* %49
	%50 = load {i8*, i64, i64}, {i8*, i64, i64}* %46
	%51 = alloca {i8*, i64, i64}, align 8 
	store {i8*, i64, i64} zeroinitializer, {i8*, i64, i64}* %51
	store {i8*, i64, i64} %50, {i8*, i64, i64}* %51
	%52 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %51, i64 0, i32 0
	%53 = load i8*, i8** %52
	%54 = getelementptr inbounds {i8*, i64, i64}, {i8*, i64, i64}* %51, i64 0, i32 1
	%55 = load i64, i64* %54
	%56 = alloca %.string, align 8 
	store %.string zeroinitializer, %.string* %56
	%57 = getelementptr inbounds %.string, %.string* %56, i64 0, i32 0
	%58 = getelementptr inbounds %.string, %.string* %56, i64 0, i32 1
	store i8* %53, i8** %57
	store i64 %55, i64* %58
	%59 = load %.string, %.string* %56
	store %.string %59, %.string* %40
	%60 = load %.string, %.string* %40
	call void @string_byte_reverse(%.string %60)
	%61 = load %.string, %.string* %40
	call void @print_string(%.string %61)
	ret void
}

@.str0 = global [64 x i8] c"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz\40$"
