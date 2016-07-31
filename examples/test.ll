define void @main() {
entry:
	%0 = alloca i64, align 8 ; a
	store i64 zeroinitializer, i64* %0
	ret void
}
