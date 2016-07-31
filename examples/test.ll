define void @main() {
entry:
	%0 = alloca i64, align 8 ; a
	store i64 zeroinitializer, i64* %0
	%1 = alloca i64, align 8 ; b
	store i64 zeroinitializer, i64* %1
	store i64 1, i64* %0
	store i64 2, i64* %1
	%2 = load i64, i64* %0
	%3 = add i64 %2, 1
	store i64 %3, i64* %0
	%4 = load i64, i64* %1
	%5 = add i64 %4, 1
	store i64 %5, i64* %1
	%6 = load i64, i64* %1
	%7 = load i64, i64* %0
	%8 = add i64 %7, %6
	store i64 %8, i64* %0
	ret void
}
