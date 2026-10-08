// The Apple arm64 calling convention, which must match LLVM's (lbAbiArm64 in llvm_abi.cpp)
// because procedures from both backends call each other.

gb_internal bool xb_is_arm64(void) {
	return build_context.metrics.arch == TargetArch_arm64;
}

// arm64 only defines globals and the type info so far, LLVM compiles every procedure
gb_internal bool xb_can_compile_procs(void) {
	return !xb_is_arm64();
}

gb_internal xbAbiFunc *a64_abi_compute(Type *proc_type, char const **reason) {
	*reason = "arm64 calling convention";
	return nullptr;
}
