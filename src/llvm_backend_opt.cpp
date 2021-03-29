#ifndef LLVM_USE_BASIC_PASSES
#define LLVM_USE_BASIC_PASSES 0
#endif

void lb_populate_function_pass_manager(LLVMPassManagerRef fpm, bool ignore_memcpy_pass) {
	if (!ignore_memcpy_pass) {
		LLVMAddMemCpyOptPass(fpm);
	}
	if (LLVM_USE_BASIC_PASSES || build_context.optimization_level == 0) {
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

void lb_add_function_simplifcation_passes(LLVMPassManagerRef mpm) {
	// LLVMAddScalarReplAggregatesPass(mpm);
	LLVMAddEarlyCSEMemSSAPass(mpm);

	LLVMAddGVNPass(mpm);
	LLVMAddCFGSimplificationPass(mpm);

	LLVMAddJumpThreadingPass(mpm);

	if (build_context.optimization_level > 2) {
		LLVMAddAggressiveInstCombinerPass(mpm);
	}
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


void lb_populate_module_pass_manager(LLVMTargetMachineRef target_machine, LLVMPassManagerRef mpm) {
	LLVMPassManagerBuilderRef pmb = LLVMPassManagerBuilderCreate();
	LLVMPassManagerBuilderSetOptLevel(pmb, build_context.optimization_level);
	LLVMPassManagerBuilderSetSizeLevel(pmb, build_context.optimization_level);

	LLVMPassManagerBuilderPopulateLTOPassManager(pmb, mpm, false, true);

	LLVMAddAlwaysInlinerPass(mpm);
	LLVMAddStripDeadPrototypesPass(mpm);
	LLVMAddAnalysisPasses(target_machine, mpm);
	LLVMAddPruneEHPass(mpm);
	if (LLVM_USE_BASIC_PASSES || build_context.optimization_level == 0) {
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

	if (build_context.optimization_level > 2) {
		LLVMAddArgumentPromotionPass(mpm);
	}
	lb_add_function_simplifcation_passes(mpm);

	LLVMAddGlobalOptimizerPass(mpm);

	// LLVMAddLowerConstantIntrinsicsPass(mpm);

	LLVMAddLoopRotatePass(mpm);

	LLVMAddLoopVectorizePass(mpm);

	LLVMAddInstructionCombiningPass(mpm);
	if (build_context.optimization_level >= 2) {
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

	if (build_context.optimization_level >= 2) {
		LLVMAddGlobalDCEPass(mpm);
		LLVMAddConstantMergePass(mpm);
	}

	LLVMAddCFGSimplificationPass(mpm);


	#if 0
		LLVMAddAlwaysInlinerPass(mpm);
		LLVMAddStripDeadPrototypesPass(mpm);
		LLVMAddAnalysisPasses(target_machine, mpm);
		if (build_context.optimization_level >= 2) {
			LLVMAddArgumentPromotionPass(mpm);
			LLVMAddConstantMergePass(mpm);
			LLVMAddGlobalDCEPass(mpm);
			LLVMAddDeadArgEliminationPass(mpm);
		}
	#endif
}
