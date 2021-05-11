void lb_populate_function_pass_manager(lbModule *m, LLVMPassManagerRef fpm, bool ignore_memcpy_pass, i32 optimization_level);
void lb_add_function_simplifcation_passes(LLVMPassManagerRef mpm, i32 optimization_level);
void lb_populate_module_pass_manager(LLVMTargetMachineRef target_machine, LLVMPassManagerRef mpm, i32 optimization_level);
void lb_populate_function_pass_manager_specific(lbModule *m, LLVMPassManagerRef fpm, i32 optimization_level);

LLVMBool lb_must_preserve_predicate_callback(LLVMValueRef value, void *user_data) {
	lbModule *m = cast(lbModule *)user_data;
	if (m == nullptr) {
		return false;
	}
	if (value == nullptr) {
		return false;
	}
	return LLVMIsAAllocaInst(value) != nullptr;
}

void lb_add_must_preserve_predicate_pass(lbModule *m, LLVMPassManagerRef fpm, i32 optimization_level) {
	if (false && optimization_level == 0 && m->debug_builder) {
		// LLVMAddInternalizePassWithMustPreservePredicate(fpm, m, lb_must_preserve_predicate_callback);
	}
}


void lb_basic_populate_function_pass_manager(LLVMPassManagerRef fpm) {
	LLVMAddPromoteMemoryToRegisterPass(fpm);
	LLVMAddMergedLoadStoreMotionPass(fpm);
	LLVMAddConstantPropagationPass(fpm);
	LLVMAddEarlyCSEPass(fpm);

	LLVMAddConstantPropagationPass(fpm);
	LLVMAddMergedLoadStoreMotionPass(fpm);
	LLVMAddPromoteMemoryToRegisterPass(fpm);
	LLVMAddCFGSimplificationPass(fpm);
}

void lb_populate_function_pass_manager(lbModule *m, LLVMPassManagerRef fpm, bool ignore_memcpy_pass, i32 optimization_level) {
	// NOTE(bill): Treat -opt:3 as if it was -opt:2
	// TODO(bill): Determine which opt definitions should exist in the first place
	optimization_level = gb_clamp(optimization_level, 0, 2);

	lb_add_must_preserve_predicate_pass(m, fpm, optimization_level);

	if (ignore_memcpy_pass) {
		lb_basic_populate_function_pass_manager(fpm);
		return;
	} else if (optimization_level == 0) {
		LLVMAddMemCpyOptPass(fpm);
		lb_basic_populate_function_pass_manager(fpm);
		return;
	}

#if 0
	LLVMPassManagerBuilderRef pmb = LLVMPassManagerBuilderCreate();
	LLVMPassManagerBuilderSetOptLevel(pmb, optimization_level);
	LLVMPassManagerBuilderSetSizeLevel(pmb, optimization_level);
	LLVMPassManagerBuilderPopulateFunctionPassManager(pmb, fpm);
#else
	LLVMAddMemCpyOptPass(fpm);
	LLVMAddPromoteMemoryToRegisterPass(fpm);
	LLVMAddMergedLoadStoreMotionPass(fpm);
	LLVMAddConstantPropagationPass(fpm);
	LLVMAddEarlyCSEPass(fpm);

	LLVMAddConstantPropagationPass(fpm);
	LLVMAddMergedLoadStoreMotionPass(fpm);
	LLVMAddPromoteMemoryToRegisterPass(fpm);
	LLVMAddCFGSimplificationPass(fpm);

	LLVMAddSCCPPass(fpm);

	LLVMAddPromoteMemoryToRegisterPass(fpm);
	LLVMAddUnifyFunctionExitNodesPass(fpm);

	LLVMAddCFGSimplificationPass(fpm);
	LLVMAddEarlyCSEPass(fpm);
	LLVMAddLowerExpectIntrinsicPass(fpm);
#endif
}

void lb_populate_function_pass_manager_specific(lbModule *m, LLVMPassManagerRef fpm, i32 optimization_level) {
	// NOTE(bill): Treat -opt:3 as if it was -opt:2
	// TODO(bill): Determine which opt definitions should exist in the first place
	optimization_level = gb_clamp(optimization_level, 0, 2);

	lb_add_must_preserve_predicate_pass(m, fpm, optimization_level);

	if (optimization_level == 0) {
		LLVMAddMemCpyOptPass(fpm);
		lb_basic_populate_function_pass_manager(fpm);
		return;
	}

#if 1
	LLVMPassManagerBuilderRef pmb = LLVMPassManagerBuilderCreate();
	LLVMPassManagerBuilderSetOptLevel(pmb, optimization_level);
	LLVMPassManagerBuilderSetSizeLevel(pmb, optimization_level);
	LLVMPassManagerBuilderPopulateFunctionPassManager(pmb, fpm);
#else
	LLVMAddMemCpyOptPass(fpm);
	LLVMAddPromoteMemoryToRegisterPass(fpm);
	LLVMAddMergedLoadStoreMotionPass(fpm);
	LLVMAddConstantPropagationPass(fpm);
	LLVMAddEarlyCSEPass(fpm);

	LLVMAddConstantPropagationPass(fpm);
	LLVMAddMergedLoadStoreMotionPass(fpm);
	LLVMAddPromoteMemoryToRegisterPass(fpm);
	LLVMAddCFGSimplificationPass(fpm);

	LLVMAddSCCPPass(fpm);

	LLVMAddPromoteMemoryToRegisterPass(fpm);
	LLVMAddUnifyFunctionExitNodesPass(fpm);

	LLVMAddCFGSimplificationPass(fpm);
	LLVMAddEarlyCSEPass(fpm);
	LLVMAddLowerExpectIntrinsicPass(fpm);
#endif
}

void lb_add_function_simplifcation_passes(LLVMPassManagerRef mpm, i32 optimization_level) {
	LLVMAddEarlyCSEMemSSAPass(mpm);

	LLVMAddGVNPass(mpm);
	LLVMAddCFGSimplificationPass(mpm);

	LLVMAddJumpThreadingPass(mpm);

	// if (optimization_level > 2) {
		// LLVMAddAggressiveInstCombinerPass(mpm);
	// }
	LLVMAddInstructionCombiningPass(mpm);
	LLVMAddSimplifyLibCallsPass(mpm);

	LLVMAddTailCallEliminationPass(mpm);
	LLVMAddCFGSimplificationPass(mpm);
	LLVMAddReassociatePass(mpm);

	LLVMAddLoopRotatePass(mpm);
	LLVMAddLICMPass(mpm);
	LLVMAddLoopUnswitchPass(mpm);

	LLVMAddCFGSimplificationPass(mpm);
	LLVMAddInstructionCombiningPass(mpm);
	LLVMAddIndVarSimplifyPass(mpm);
	LLVMAddLoopIdiomPass(mpm);
	LLVMAddLoopDeletionPass(mpm);

	LLVMAddLoopUnrollPass(mpm);

	LLVMAddMergedLoadStoreMotionPass(mpm);

	LLVMAddGVNPass(mpm);

	LLVMAddMemCpyOptPass(mpm);
	LLVMAddSCCPPass(mpm);

	LLVMAddBitTrackingDCEPass(mpm);

	LLVMAddInstructionCombiningPass(mpm);
	LLVMAddJumpThreadingPass(mpm);
	LLVMAddCorrelatedValuePropagationPass(mpm);
	LLVMAddDeadStoreEliminationPass(mpm);
	LLVMAddLICMPass(mpm);

	LLVMAddLoopRerollPass(mpm);
	LLVMAddAggressiveDCEPass(mpm);
	LLVMAddCFGSimplificationPass(mpm);
	LLVMAddInstructionCombiningPass(mpm);
}


void lb_populate_module_pass_manager(LLVMTargetMachineRef target_machine, LLVMPassManagerRef mpm, i32 optimization_level) {

	// NOTE(bill): Treat -opt:3 as if it was -opt:2
	// TODO(bill): Determine which opt definitions should exist in the first place
	optimization_level = gb_clamp(optimization_level, 0, 2);

	LLVMAddAlwaysInlinerPass(mpm);
	LLVMAddStripDeadPrototypesPass(mpm);
	LLVMAddAnalysisPasses(target_machine, mpm);
	LLVMAddPruneEHPass(mpm);
	if (optimization_level == 0) {
		return;
	}

	LLVMAddGlobalDCEPass(mpm);

	if (optimization_level >= 2) {
		// NOTE(bill, 2021-03-29: use this causes invalid code generation)
		// LLVMPassManagerBuilderRef pmb = LLVMPassManagerBuilderCreate();
		// LLVMPassManagerBuilderSetOptLevel(pmb, optimization_level);
		// LLVMPassManagerBuilderPopulateModulePassManager(pmb, mpm);
		// LLVMPassManagerBuilderPopulateLTOPassManager(pmb, mpm, false, true);
		// return;
	}

	LLVMAddIPSCCPPass(mpm);
	LLVMAddCalledValuePropagationPass(mpm);

	LLVMAddGlobalOptimizerPass(mpm);
	LLVMAddDeadArgEliminationPass(mpm);

	// LLVMAddConstantMergePass(mpm); // ???
	LLVMAddInstructionCombiningPass(mpm);
	LLVMAddCFGSimplificationPass(mpm);

	LLVMAddPruneEHPass(mpm);
	if (optimization_level < 2) {
		return;
	}

	LLVMAddFunctionInliningPass(mpm);
	lb_add_function_simplifcation_passes(mpm, optimization_level);

	LLVMAddGlobalDCEPass(mpm);
	LLVMAddGlobalOptimizerPass(mpm);

	// LLVMAddLowerConstantIntrinsicsPass(mpm);

	LLVMAddLoopRotatePass(mpm);

	LLVMAddLoopVectorizePass(mpm);

	LLVMAddInstructionCombiningPass(mpm);
	if (optimization_level >= 2) {
		LLVMAddEarlyCSEPass(mpm);
		LLVMAddCorrelatedValuePropagationPass(mpm);
		LLVMAddLICMPass(mpm);
		LLVMAddLoopUnswitchPass(mpm);
		LLVMAddCFGSimplificationPass(mpm);
		LLVMAddInstructionCombiningPass(mpm);
	}

	LLVMAddCFGSimplificationPass(mpm);

	LLVMAddSLPVectorizePass(mpm);
	LLVMAddLICMPass(mpm);

	LLVMAddAlignmentFromAssumptionsPass(mpm);

	LLVMAddStripDeadPrototypesPass(mpm);

	if (optimization_level >= 2) {
		LLVMAddGlobalDCEPass(mpm);
		LLVMAddConstantMergePass(mpm);
	}

	LLVMAddCFGSimplificationPass(mpm);
}
