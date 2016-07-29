define void @main() {
entry:
	%0 = alloca i64, align 8
	store i64 zeroinitializer, i64* %0
	store i64 137, i64* %0
	%1 = load i64, i64* %0
	add i64 1, %1
	store i64 %2, i64* %0
	%3 = alloca float, align 4
	store float zeroinitializer, float* %3
	store float 0x3f8147ae00000000, float* %3
	%4 = load float, float* %3
	fadd float %4, 0x3f7d70a400000000
	store float %5, float* %3
	ret void
}
