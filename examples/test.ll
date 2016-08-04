define void @main() {
"entry - 0":
	%0 = getelementptr inbounds [13 x i8], [13 x i8]* @.str0, i64 0, i64 0
	%1 = alloca {i8*, i64}, align 8 
	store {i8*, i64} zeroinitializer, {i8*, i64}* %1
	%2 = getelementptr inbounds {i8*, i64}, {i8*, i64}* %1, i64 0, i32 0
	%3 = getelementptr inbounds {i8*, i64}, {i8*, i64}* %1, i64 0, i32 1
	store i8* %0, i8** %2
	store i64 13, i64* %3
	%4 = load {i8*, i64}, {i8*, i64}* %1
	call void @print_string({i8*, i64} %4)
	ret void
}

declare i32 @putchar(i32 %c) 
define void @print_string({i8*, i64} %s) {
"entry - 0":
	%0 = alloca {i8*, i64}, align 8 ; s
	store {i8*, i64} zeroinitializer, {i8*, i64}* %0
	store {i8*, i64} %s, {i8*, i64}* %0
	%1 = alloca i64, align 8 ; i
	store i64 zeroinitializer, i64* %1
	store i64 0, i64* %1
	br label %"for.loop - 2"

"for.body - 1":
	%2 = alloca i32, align 4 ; c
	store i32 zeroinitializer, i32* %2
	%3 = load i64, i64* %1
	%4 = getelementptr inbounds {i8*, i64}, {i8*, i64}* %0, i64 0, i32 0
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
	%12 = getelementptr inbounds {i8*, i64}, {i8*, i64}* %0, i64 0, i32 1
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

@.str0 = global [13 x i8] c"Hello\2C\20\E4\B8\96\E7\95\8C"
