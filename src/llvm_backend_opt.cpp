#ifndef LLVM_USE_NO_EXTRA_PASSES
#define LLVM_USE_NO_EXTRA_PASSES 0
#endif

#ifndef LLVM_USE_BASIC_PASSES
#define LLVM_USE_BASIC_PASSES LLVM_USE_NO_EXTRA_PASSES
#endif


void lb_populate_function_pass_manager(LLVMPassManagerRef fpm, bool ignore_memcpy_pass, i32 optimization_level) {
	// NOTE(bill): Treat -opt:3 as if it was -opt:2
	// TODO(bill): Determine which opt definitions should exist in the first place
	optimization_level = gb_clamp(optimization_level, 0, 2);
	if (LLVM_USE_BASIC_PASSES) {
		optimization_level = 0;
	}

	if (!ignore_memcpy_pass) {
		LLVMAddMemCpyOptPass(fpm);
	}
	if (optimization_level == 0) {
		LLVMAddPromoteMemoryToRegisterPass(fpm);
		LLVMAddMergedLoadStoreMotionPass(fpm);
		LLVMAddEarlyCSEPass(fpm);
		// LLVMAddEarlyCSEMemSSAPass(fpm);
		LLVMAddConstantPropagationPass(fpm);
		LLVMAddMergedLoadStoreMotionPass(fpm);
		LLVMAddPromoteMemoryToRegisterPass(fpm);
		LLVMAddCFGSimplificationPass(fpm);

		// LLVMAddSLPVectorizePass(fpm);
		// LLVMAddLoopVectorizePass(fpm);

		// LLVMAddScalarizerPass(fpm);
		// LLVMAddLoopIdiomPass(fpm);
		return;
	}

	LLVMAddSCCPPass(fpm);

	LLVMAddPromoteMemoryToRegisterPass(fpm);
	LLVMAddUnifyFunctionExitNodesPass(fpm);

	LLVMAddCFGSimplificationPass(fpm);
	// LLVMAddScalarReplAggregatesPass(fpm);
	LLVMAddEarlyCSEPass(fpm);
	LLVMAddLowerExpectIntrinsicPass(fpm);
}

void lb_add_function_simplifcation_passes(LLVMPassManagerRef mpm, i32 optimization_level) {
	// LLVMAddScalarReplAggregatesPass(mpm);
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
	LLVMPassManagerBuilderRef pmb = LLVMPassManagerBuilderCreate();

	// NOTE(bill): Treat -opt:3 as if it was -opt:2
	// TODO(bill): Determine which opt definitions should exist in the first place
	optimization_level = gb_clamp(optimization_level, 0, 2);

	LLVMAddAnalysisPasses(target_machine, mpm);
	LLVMPassManagerBuilderPopulateModulePassManager(pmb, mpm);
	LLVMPassManagerBuilderPopulateLTOPassManager(pmb, mpm, false, true);
	LLVMPassManagerBuilderSetOptLevel(pmb, optimization_level);
	LLVMPassManagerBuilderSetSizeLevel(pmb, optimization_level);

	if (LLVM_USE_BASIC_PASSES) {
		optimization_level = 0;
	}
	if (LLVM_USE_NO_EXTRA_PASSES) {
		return;
	}

	LLVMAddAlwaysInlinerPass(mpm);
	LLVMAddStripDeadPrototypesPass(mpm);
	LLVMAddPruneEHPass(mpm);
	if (optimization_level == 0) {
		// LLVMAddMergeFunctionsPass(mpm);
		return;
	}

	LLVMAddGlobalDCEPass(mpm);

	LLVMAddIPSCCPPass(mpm);
	LLVMAddCalledValuePropagationPass(mpm);

	LLVMAddGlobalOptimizerPass(mpm);
	LLVMAddDeadArgEliminationPass(mpm);

	// LLVMAddConstantMergePass(mpm); // ???
	LLVMAddInstructionCombiningPass(mpm);
	LLVMAddCFGSimplificationPass(mpm);

	LLVMAddPruneEHPass(mpm);
	LLVMAddFunctionInliningPass(mpm);

	// if (optimization_level > 2) {
		// LLVMAddArgumentPromotionPass(mpm);
	// }
	lb_add_function_simplifcation_passes(mpm, optimization_level);

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


	#if 0
		LLVMAddAlwaysInlinerPass(mpm);
		LLVMAddStripDeadPrototypesPass(mpm);
		LLVMAddAnalysisPasses(target_machine, mpm);
		if (optimization_level >= 2) {
			LLVMAddArgumentPromotionPass(mpm);
			LLVMAddConstantMergePass(mpm);
			LLVMAddGlobalDCEPass(mpm);
			LLVMAddDeadArgEliminationPass(mpm);
		}
	#endif
}
