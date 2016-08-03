define void @main() {
"entry - 0":
	%0 = alloca [16 x i64], align 8 ; a
	store [16 x i64] zeroinitializer, [16 x i64]* %0
	%1 = alloca {i64*, i64, i64}, align 8 ; b
	store {i64*, i64, i64} zeroinitializer, {i64*, i64, i64}* %1
	%2 = sub i64 1, 0
	%3 = sub i64 2, 0
	%4 = getelementptr inbounds [16 x i64], [16 x i64]* %0, i64 0, i64 0
	%5 = getelementptr i64, i64* %4, i64 0
	%6 = alloca {i64*, i64, i64}, align 8 
	store {i64*, i64, i64} zeroinitializer, {i64*, i64, i64}* %6
	%7 = getelementptr inbounds {i64*, i64, i64}, {i64*, i64, i64}* %6, i64 0, i32 0
	store i64* %5, i64** %7
	%8 = getelementptr inbounds {i64*, i64, i64}, {i64*, i64, i64}* %6, i64 0, i32 1
	store i64 %2, i64* %8
	%9 = getelementptr inbounds {i64*, i64, i64}, {i64*, i64, i64}* %6, i64 0, i32 2
	store i64 %3, i64* %9
	%10 = load {i64*, i64, i64}, {i64*, i64, i64}* %6
	store {i64*, i64, i64} %10, {i64*, i64, i64}* %1
	ret void
}

