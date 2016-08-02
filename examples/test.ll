define void @main() {
entry:
	%0 = alloca i64, align 8 ; x
	store i64 zeroinitializer, i64* %0
	store i64 15, i64* %0
	%1 = load i64, i64* %0
	%2 = icmp sgt i64 %1, 0
	br i1 %2, label %if-then, label %if-else
if-then:
	store i64 123, i64* %0
	br label %if-end
if-else:
	store i64 321, i64* %0
	br label %if-end
if-end:
	ret void
}
