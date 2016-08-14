%.string = type {i8*, i64} ; Basic_string

%.rawptr = type i8* ; Basic_rawptr

declare void @llvm.memmove.p0i8.p0i8.i64(i8*, i8*, i64, i32, i1)

declare void @putchar(i32 %c) ; foreign procedure

define void @main() {
entry.-.0:
	%0 = alloca <8 x i1>, align 8 ; v
	store <8 x i1> zeroinitializer, <8 x i1>* %0
	%1 = alloca <8 x i1>, align 8 
	store <8 x i1> zeroinitializer, <8 x i1>* %1
	%2 = load <8 x i1>, <8 x i1>* %1, align 8
	%3 = insertelement <8 x i1> %2, i1 true, i64 0
	%4 = insertelement <8 x i1> %3, i1 false, i64 1
	%5 = insertelement <8 x i1> %4, i1 true, i64 2
	%6 = insertelement <8 x i1> %5, i1 false, i64 3
	%7 = insertelement <8 x i1> %6, i1 true, i64 4
	%8 = insertelement <8 x i1> %7, i1 false, i64 5
	%9 = insertelement <8 x i1> %8, i1 true, i64 6
	%10 = insertelement <8 x i1> %9, i1 false, i64 7
	store <8 x i1> %10, <8 x i1>* %0
	%11 = load <8 x i1>, <8 x i1>* %0, align 8
	%12 = extractelement <8 x i1> %11, i64 0
	%13 = zext i1 %12 to i32
	%14 = add i32 %13, 65
	call void @putchar(i32 %14)
	%15 = load <8 x i1>, <8 x i1>* %0, align 8
	%16 = extractelement <8 x i1> %15, i64 1
	%17 = zext i1 %16 to i32
	%18 = add i32 %17, 65
	call void @putchar(i32 %18)
	%19 = load <8 x i1>, <8 x i1>* %0, align 8
	%20 = extractelement <8 x i1> %19, i64 2
	%21 = zext i1 %20 to i32
	%22 = add i32 %21, 65
	call void @putchar(i32 %22)
	%23 = load <8 x i1>, <8 x i1>* %0, align 8
	%24 = extractelement <8 x i1> %23, i64 3
	%25 = zext i1 %24 to i32
	%26 = add i32 %25, 65
	call void @putchar(i32 %26)
	call void @putchar(i32 10)
	ret void
}

