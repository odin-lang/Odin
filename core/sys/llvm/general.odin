// General Intrinsics

package sys_llvm

@(default_calling_convention="none")
foreign _ {
	@(link_name="llvm.fake.use")
	fake_use :: proc(#c_vararg arg: ..any) ---
}
