%-string = type {i8*, i64} ; Basic_string

%-rawptr = type i8* ; Basic_rawptr

define void @main() {
"entry - 0":
	%0 = alloca i64, align 8 ; a
	store i64 zeroinitializer, i64* %0
	%1 = getelementptr inbounds [6 x i8], [6 x i8]* @.str0, i64 0, i64 0
	%2 = getelementptr i8, i8* %1, i64 1
	%3 = load i8, i8* %2
	%4 = zext i8 %3 to i64
	store i64 %4, i64* %0
	%5 = load i64, i64* %0
	call void @print_int(i64 %5, i64 10)
	%6 = getelementptr inbounds [1 x i8], [1 x i8]* @.str1, i64 0, i64 0
	%7 = alloca %-string, align 8 
	store %-string zeroinitializer, %-string* %7
	%8 = getelementptr inbounds %-string, %-string* %7, i64 0, i32 0
	%9 = getelementptr inbounds %-string, %-string* %7, i64 0, i32 1
	store i8* %6, i8** %8
	store i64 1, i64* %9
	%10 = load %-string, %-string* %7
	call void @print_string(%-string %10)
	%11 = getelementptr inbounds [23 x i8], [23 x i8]* @.str2, i64 0, i64 0
	%12 = alloca %-string, align 8 
	store %-string zeroinitializer, %-string* %12
	%13 = getelementptr inbounds %-string, %-string* %12, i64 0, i32 0
	%14 = getelementptr inbounds %-string, %-string* %12, i64 0, i32 1
	store i8* %11, i8** %13
	store i64 23, i64* %14
	%15 = load %-string, %-string* %12
	call void @print_string(%-string %15)
	%16 = getelementptr inbounds [21 x i8], [21 x i8]* @.str3, i64 0, i64 0
	%17 = alloca %-string, align 8 
	store %-string zeroinitializer, %-string* %17
	%18 = getelementptr inbounds %-string, %-string* %17, i64 0, i32 0
	%19 = getelementptr inbounds %-string, %-string* %17, i64 0, i32 1
	store i8* %16, i8** %18
	store i64 21, i64* %19
	%20 = load %-string, %-string* %17
	call void @print_string(%-string %20)
	%21 = getelementptr inbounds [22 x i8], [22 x i8]* @.str4, i64 0, i64 0
	%22 = alloca %-string, align 8 
	store %-string zeroinitializer, %-string* %22
	%23 = getelementptr inbounds %-string, %-string* %22, i64 0, i32 0
	%24 = getelementptr inbounds %-string, %-string* %22, i64 0, i32 1
	store i8* %21, i8** %23
	store i64 22, i64* %24
	%25 = load %-string, %-string* %22
	call void @print_string(%-string %25)
	%26 = getelementptr inbounds [23 x i8], [23 x i8]* @.str5, i64 0, i64 0
	%27 = alloca %-string, align 8 
	store %-string zeroinitializer, %-string* %27
	%28 = getelementptr inbounds %-string, %-string* %27, i64 0, i32 0
	%29 = getelementptr inbounds %-string, %-string* %27, i64 0, i32 1
	store i8* %26, i8** %28
	store i64 23, i64* %29
	%30 = load %-string, %-string* %27
	call void @print_string(%-string %30)
	%31 = getelementptr inbounds [20 x i8], [20 x i8]* @.str6, i64 0, i64 0
	%32 = alloca %-string, align 8 
	store %-string zeroinitializer, %-string* %32
	%33 = getelementptr inbounds %-string, %-string* %32, i64 0, i32 0
	%34 = getelementptr inbounds %-string, %-string* %32, i64 0, i32 1
	store i8* %31, i8** %33
	store i64 20, i64* %34
	%35 = load %-string, %-string* %32
	call void @print_string(%-string %35)
	%36 = getelementptr inbounds [37 x i8], [37 x i8]* @.str7, i64 0, i64 0
	%37 = alloca %-string, align 8 
	store %-string zeroinitializer, %-string* %37
	%38 = getelementptr inbounds %-string, %-string* %37, i64 0, i32 0
	%39 = getelementptr inbounds %-string, %-string* %37, i64 0, i32 1
	store i8* %36, i8** %38
	store i64 37, i64* %39
	%40 = load %-string, %-string* %37
	call void @print_string(%-string %40)
	%41 = getelementptr inbounds [21 x i8], [21 x i8]* @.str8, i64 0, i64 0
	%42 = alloca %-string, align 8 
	store %-string zeroinitializer, %-string* %42
	%43 = getelementptr inbounds %-string, %-string* %42, i64 0, i32 0
	%44 = getelementptr inbounds %-string, %-string* %42, i64 0, i32 1
	store i8* %41, i8** %43
	store i64 21, i64* %44
	%45 = load %-string, %-string* %42
	call void @print_string(%-string %45)
	%46 = getelementptr inbounds [33 x i8], [33 x i8]* @.str9, i64 0, i64 0
	%47 = alloca %-string, align 8 
	store %-string zeroinitializer, %-string* %47
	%48 = getelementptr inbounds %-string, %-string* %47, i64 0, i32 0
	%49 = getelementptr inbounds %-string, %-string* %47, i64 0, i32 1
	store i8* %46, i8** %48
	store i64 33, i64* %49
	%50 = load %-string, %-string* %47
	call void @print_string(%-string %50)
	%51 = getelementptr inbounds [29 x i8], [29 x i8]* @.stra, i64 0, i64 0
	%52 = alloca %-string, align 8 
	store %-string zeroinitializer, %-string* %52
	%53 = getelementptr inbounds %-string, %-string* %52, i64 0, i32 0
	%54 = getelementptr inbounds %-string, %-string* %52, i64 0, i32 1
	store i8* %51, i8** %53
	store i64 29, i64* %54
	%55 = load %-string, %-string* %52
	call void @print_string(%-string %55)
	%56 = getelementptr inbounds [24 x i8], [24 x i8]* @.strb, i64 0, i64 0
	%57 = alloca %-string, align 8 
	store %-string zeroinitializer, %-string* %57
	%58 = getelementptr inbounds %-string, %-string* %57, i64 0, i32 0
	%59 = getelementptr inbounds %-string, %-string* %57, i64 0, i32 1
	store i8* %56, i8** %58
	store i64 24, i64* %59
	%60 = load %-string, %-string* %57
	call void @print_string(%-string %60)
	%61 = getelementptr inbounds [42 x i8], [42 x i8]* @.strc, i64 0, i64 0
	%62 = alloca %-string, align 8 
	store %-string zeroinitializer, %-string* %62
	%63 = getelementptr inbounds %-string, %-string* %62, i64 0, i32 0
	%64 = getelementptr inbounds %-string, %-string* %62, i64 0, i32 1
	store i8* %61, i8** %63
	store i64 42, i64* %64
	%65 = load %-string, %-string* %62
	call void @print_string(%-string %65)
	%66 = getelementptr inbounds [21 x i8], [21 x i8]* @.strd, i64 0, i64 0
	%67 = alloca %-string, align 8 
	store %-string zeroinitializer, %-string* %67
	%68 = getelementptr inbounds %-string, %-string* %67, i64 0, i32 0
	%69 = getelementptr inbounds %-string, %-string* %67, i64 0, i32 1
	store i8* %66, i8** %68
	store i64 21, i64* %69
	%70 = load %-string, %-string* %67
	call void @print_string(%-string %70)
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
	%3 = getelementptr inbounds %-string, %-string* %0, i64 0, i32 0
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
	%5 = getelementptr inbounds %-string, %-string* %0, i64 0, i32 0
	%6 = load i8*, i8** %5
	%7 = load i64, i64* %4
	%8 = getelementptr i8, i8* %6, i64 %7
	%9 = getelementptr inbounds %-string, %-string* %0, i64 0, i32 0
	%10 = load i8*, i8** %9
	%11 = load i64, i64* %4
	%12 = load i64, i64* %1
	%13 = sub i64 %12, 1
	%14 = sub i64 %13, %11
	%15 = getelementptr i8, i8* %10, i64 %14
	%16 = getelementptr inbounds %-string, %-string* %0, i64 0, i32 0
	%17 = load i8*, i8** %16
	%18 = load i64, i64* %4
	%19 = load i64, i64* %1
	%20 = sub i64 %19, 1
	%21 = sub i64 %20, %18
	%22 = getelementptr i8, i8* %17, i64 %21
	%23 = load i8, i8* %22
	%24 = getelementptr inbounds %-string, %-string* %0, i64 0, i32 0
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
	%17 = getelementptr inbounds [64 x i8], [64 x i8]* @.stre, i64 0, i64 0
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
	%40 = alloca %-string, align 8 ; str
	store %-string zeroinitializer, %-string* %40
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
	%56 = alloca %-string, align 8 
	store %-string zeroinitializer, %-string* %56
	%57 = getelementptr inbounds %-string, %-string* %56, i64 0, i32 0
	%58 = getelementptr inbounds %-string, %-string* %56, i64 0, i32 1
	store i8* %53, i8** %57
	store i64 %55, i64* %58
	%59 = load %-string, %-string* %56
	store %-string %59, %-string* %40
	%60 = load %-string, %-string* %40
	call void @string_byte_reverse(%-string %60)
	%61 = load %-string, %-string* %40
	call void @print_string(%-string %61)
	ret void
}

@.str0 = global [6 x i8] c"Hello\0A"
@.str1 = global [1 x i8] c"\0A"
@.str2 = global [23 x i8] c"Chinese\20-\20\E4\BD\A0\E5\A5\BD\E4\B8\96\E7\95\8C\0A"
@.str3 = global [21 x i8] c"Dutch\20-\20Hello\20wereld\0A"
@.str4 = global [22 x i8] c"English\20-\20Hello\20world\0A"
@.str5 = global [23 x i8] c"French\20-\20Bonjour\20monde\0A"
@.str6 = global [20 x i8] c"German\20-\20Hallo\20Welt\0A"
@.str7 = global [37 x i8] c"Greek\20-\20\CE\B3\CE\B5\CE\B9\CE\AC\20\CF\83\CE\BF\CF\85\20\CE\BA\CF\8C\CF\83\CE\BC\CE\BF\CF\82\0A"
@.str8 = global [21 x i8] c"Italian\20-\20Ciao\20mondo\0A"
@.str9 = global [33 x i8] c"Japanese\20-\20\E3\81\93\E3\82\93\E3\81\AB\E3\81\A1\E3\81\AF\E4\B8\96\E7\95\8C\0A"
@.stra = global [29 x i8] c"Korean\20-\20\EC\97\AC\EB\B3\B4\EC\84\B8\EC\9A\94\20\EC\84\B8\EA\B3\84\0A"
@.strb = global [24 x i8] c"Portuguese\20-\20Ol\C3\A1\20mundo\0A"
@.strc = global [42 x i8] c"Russian\20-\20\D0\97\D0\B4\D1\80\D0\B0\D0\B2\D1\81\D1\82\D0\B2\D1\83\D0\BB\D1\82\D0\B5\20\D0\BC\D0\B8\D1\80\0A"
@.strd = global [21 x i8] c"Spanish\20-\20Hola\20mundo\0A"
@.stre = global [64 x i8] c"0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz\40$"
