%-string = type {i8*, i64} ; Basic_string

%-rawptr = type i8* ; Basic_rawptr

define void @main() {
"entry - 0":
	call void @print_int(i64 123, i64 10)
	%0 = getelementptr inbounds [1 x i8], [1 x i8]* @.str0, i64 0, i64 0
	%1 = alloca %-string, align 8 
	store %-string zeroinitializer, %-string* %1
	%2 = getelementptr inbounds %-string, %-string* %1, i64 0, i32 0
	%3 = getelementptr inbounds %-string, %-string* %1, i64 0, i32 1
	store i8* %0, i8** %2
	store i64 1, i64* %3
	%4 = load %-string, %-string* %1
	call void @print_string(%-string %4)
	ret void
}

declare i32 @putchar(i32 %c) 	; foreign procedure

define void @print_string(%-string %s) {
"entry - 0":
	%0 = alloca %-string, align 8 ; s
	store %-string zeroinitializer, %-string* %0
	store %-string %s, %-string* %0
	%1 = alloca i64, align 8 ; i
	store i64 zeroinitializer, i64* %1
	store i64 0, i64* %1
	br label %"for.loop - 2"

"for.body - 1":
	%2 = alloca i32, align 4 ; c
	store i32 zeroinitializer, i32* %2
	%3 = load i64, i64* %1
	%4 = getelementptr inbounds %-string, %-string* %0, i64 0, i32 0
	%5 = load i8*, i8** %4
	%6 = getelementptr i8, i8* %5, i64 %3
	%7 = load i8, i8* %6
	%8 = zext i8 %7 to i32
	store i32 %8, i32* %2
	%9 = load i32, i32* %2
	%10 = call i32 @putchar(i32 %9)
	br label %"for.post - 3"

"for.loop - 2":
	%11 = load i64, i64* %1
	%12 = getelementptr inbounds %-string, %-string* %0, i64 0, i32 1
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

define void @string_byte_reverse(%-string %s) {
"entry - 0":
	%0 = alloca %-string, align 8 ; s
	store %-string zeroinitializer, %-string* %0
	store %-string %s, %-string* %0
	%1 = alloca i64, align 8 ; n
	store i64 zeroinitializer, i64* %1
	%2 = getelementptr inbounds %-string, %-string* %0, i64 0, i32 1
	%3 = load i64, i64* %2
	store i64 %3, i64* %1
	%4 = alloca i64, align 8 ; i
	store i64 zeroinitializer, i64* %4
	store i64 0, i64* %4
	br label %"for.loop - 2"

"for.body - 1":
	%5 = load i64, i64* %4
	%6 = getelementptr inbounds %-string, %-string* %0, i64 0, i32 0
	%7 = load i8*, i8** %6
	%8 = getelementptr i8, i8* %7, i64 %5
	%9 = load i64, i64* %4
	%10 = load i64, i64* %1
	%11 = sub i64 %10, 1
	%12 = sub i64 %11, %9
	%13 = getelementptr inbounds %-string, %-string* %0, i64 0, i32 0
	%14 = load i8*, i8** %13
	%15 = getelementptr i8, i8* %14, i64 %12
	%16 = load i64, i64* %4
	%17 = load i64, i64* %1
	%18 = sub i64 %17, 1
	%19 = sub i64 %18, %16
	%20 = getelementptr inbounds %-string, %-string* %0, i64 0, i32 0
	%21 = load i8*, i8** %20
	%22 = getelementptr i8, i8* %21, i64 %19
	%23 = load i8, i8* %22
	%24 = load i64, i64* %4
	%25 = getelementptr inbounds %-string, %-string* %0, i64 0, i32 0
	%26 = load i8*, i8** %25
	%27 = getelementptr i8, i8* %26, i64 %24
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

define void @print_int(i64 %i, i64 %base) {
"entry - 0":
	%0 = alloca i64, align 8 ; i
	store i64 zeroinitializer, i64* %0
	store i64 %i, i64* %0
	%1 = alloca i64, align 8 ; base
	store i64 zeroinitializer, i64* %1
	store i64 %base, i64* %1
	%2 = alloca %-string, align 8 ; NUM_TO_CHAR_TABLE
	store %-string zeroinitializer, %-string* %2
	%3 = getelementptr inbounds [64 x i8], [64 x i8]* @.str1, i64 0, i64 0
	%4 = alloca %-string, align 8 
	store %-string zeroinitializer, %-string* %4
	%5 = getelementptr inbounds %-string, %-string* %4, i64 0, i32 0
	%6 = getelementptr inbounds %-string, %-string* %4, i64 0, i32 1
	store i8* %3, i8** %5
	store i64 64, i64* %6
	%7 = load %-string, %-string* %4
	store %-string %7, %-string* %2
	%8 = alloca [21 x i8], align 1 ; buf
	store [21 x i8] zeroinitializer, [21 x i8]* %8
	%9 = alloca i64, align 8 ; len
	store i64 zeroinitializer, i64* %9
	store i64 0, i64* %9
	%10 = alloca i1, align 1 ; negative
	store i1 zeroinitializer, i1* %10
	store i1 false, i1* %10
	%11 = load i64, i64* %0
	%12 = icmp slt i64 %11, 0
	br i1 %12, label %"if.then - 1", label %"if.done - 2"

"if.then - 1":
	store i1 true, i1* %10
	%13 = load i64, i64* %0
	%14 = sub i64 0, %13
	store i64 %14, i64* %0
	br label %"if.done - 2"

"if.done - 2":
	%15 = load i64, i64* %0
	%16 = icmp sgt i64 %15, 0
	br i1 %16, label %"if.then - 3", label %"if.else - 4"

"if.then - 3":
	br label %"for.loop - 6"

"if.else - 4":
	%17 = load i64, i64* %9
	%18 = getelementptr inbounds [21 x i8], [21 x i8]* %8, i64 0, i64 0
	%19 = getelementptr i8, i8* %18, i64 %17
	store i8 0, i8* %19
	%20 = load i64, i64* %9
	%21 = add i64 %20, 1
	store i64 %21, i64* %9
	br label %"if.done - 8"

"for.body - 5":
	%22 = alloca i8, align 1 ; c
	store i8 zeroinitializer, i8* %22
	%23 = load i64, i64* %1
	%24 = load i64, i64* %0
	%25 = srem i64 %24, %23
	%26 = getelementptr inbounds %-string, %-string* %2, i64 0, i32 0
	%27 = load i8*, i8** %26
	%28 = getelementptr i8, i8* %27, i64 %25
	%29 = load i8, i8* %28
	store i8 %29, i8* %22
	%30 = load i64, i64* %9
	%31 = getelementptr inbounds [21 x i8], [21 x i8]* %8, i64 0, i64 0
	%32 = getelementptr i8, i8* %31, i64 %30
	%33 = load i8, i8* %22
	store i8 %33, i8* %32
	%34 = load i64, i64* %9
	%35 = add i64 %34, 1
	store i64 %35, i64* %9
	%36 = load i64, i64* %1
	%37 = load i64, i64* %0
	%38 = sdiv i64 %37, %36
	store i64 %38, i64* %0
	br label %"for.loop - 6"

"for.loop - 6":
	%39 = load i64, i64* %0
	%40 = icmp sgt i64 %39, 0
	br i1 %40, label %"for.body - 5", label %"for.done - 7"

"for.done - 7":
	br label %"if.done - 8"

"if.done - 8":
	%41 = load i1, i1* %10
	br i1 %41, label %"if.then - 9", label %"if.done - 10"

"if.then - 9":
	%42 = load i64, i64* %9
	%43 = getelementptr inbounds [21 x i8], [21 x i8]* %8, i64 0, i64 0
	%44 = getelementptr i8, i8* %43, i64 %42
	store i8 0, i8* %44
	%45 = load i64, i64* %9
	%46 = add i64 %45, 1
	store i64 %46, i64* %9
	br label %"if.done - 10"

"if.done - 10":
	%47 = alloca %-string, align 8 ; str
	store %-string zeroinitializer, %-string* %47
	%48 = load i64, i64* %9
	%49 = sub i64 %48, 0
	%50 = sub i64 21, 0
	%51 = getelementptr inbounds [21 x i8], [21 x i8]* %8, i64 0, i64 0
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
	%63 = alloca %-string, align 8 
	store %-string zeroinitializer, %-string* %63
	%64 = getelementptr inbounds %-string, %-string* %63, i64 0, i32 0
	%65 = getelementptr inbounds %-string, %-string* %63, i64 0, i32 1
	store i8* %60, i8** %64
	store i64 %62, i64* %65
	%66 = load %-string, %-string* %63
	store %-string %66, %-string* %47
	%67 = load %-string, %-string* %47
	call void @string_byte_reverse(%-string %67)
	%68 = load %-string, %-string* %47
	call void @print_string(%-string %68)
	ret void
}

@.str0 = global [1 x i8] c"\0A"
@.str1 = global [64 x i8] c"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz\40$"
