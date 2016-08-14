declare i32 @putchar(i32)

define void @main() {
entry:
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
	%12 = load <8 x i1>, <8 x i1>* %0, align 8
	%13 = load <8 x i1>, <8 x i1>* %0, align 8

	%14 = extractelement <8 x i1> %11, i64 0
	%15 = extractelement <8 x i1> %12, i64 1
	%16 = extractelement <8 x i1> %13, i64 2

	%17 = zext i1 %14 to i32
	%18 = zext i1 %15 to i32
	%19 = zext i1 %16 to i32

	%20 = add i32 %17, 65 ; + 'A'
	%21 = add i32 %18, 65 ; + 'A'
	%22 = add i32 %19, 65 ; + 'A'

	%23 = call i32 @putchar(i32 %20)
	%24 = call i32 @putchar(i32 %21)
	%25 = call i32 @putchar(i32 %22)

	%26 = call i32 @putchar(i32 10) ; \n

	ret void
}
