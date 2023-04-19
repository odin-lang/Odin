/**************************************************************************

	IMPORTANT NOTE(bill, 2021-11-06): Regarding Optimization Passes

	A lot of the passes taken here have been modified with what was 
	partially done in LLVM 11. 

	Passes that CANNOT be used by Odin due to C-like optimizations which 
	are not compatible with Odin:
		
		LLVMAddCorrelatedValuePropagationPass 
		LLVMAddAggressiveInstCombinerPass
		LLVMAddInstructionCombiningPass
		LLVMAddIndVarSimplifyPass
		LLVMAddLoopUnrollPass
		LLVMAddEarlyCSEMemSSAPass
		LLVMAddGVNPass
		LLVMAddDeadStoreEliminationPass - Causes too many false positive
		
	Odin does not allow poison-value based optimizations. 
	
	For example, *-flowing integers in C is "undefined behaviour" and thus 
	many optimizers, including LLVM, take advantage of this for a certain 
	class of optimizations. Odin on the other hand defines *-flowing 
	behaviour to obey the rules of 2's complement, meaning wrapping is a 
	expected. This means any outputted IR containing the following flags 
	may cause incorrect behaviour:
	
		nsw (no signed wrap)
		nuw (no unsigned wrap)
		poison (poison value)
**************************************************************************/


gb_internal void lb_populate_function_pass_manager(lbModule *m, LLVMPassManagerRef fpm, bool ignore_memcpy_pass, i32 optimization_level);
gb_internal void lb_add_function_simplifcation_passes(LLVMPassManagerRef mpm, i32 optimization_level);
gb_internal void lb_populate_module_pass_manager(LLVMTargetMachineRef target_machine, LLVMPassManagerRef mpm, i32 optimization_level);
gb_internal void lb_populate_function_pass_manager_specific(lbModule *m, LLVMPassManagerRef fpm, i32 optimization_level);

// gb_internal LLVMBool lb_must_preserve_predicate_callback(LLVMValueRef value, void *user_data) {
// 	lbModule *m = cast(lbModule *)user_data;
// 	if (m == nullptr) {
// 		return false;
// 	}
// 	if (value == nullptr) {
// 		return false;
// 	}
// 	return LLVMIsAAllocaInst(value) != nullptr;
// }


#if LLVM_VERSION_MAJOR < 12
#define LLVM_ADD_CONSTANT_VALUE_PASS(fpm) LLVMAddConstantPropagationPass(fpm)
#else
#define LLVM_ADD_CONSTANT_VALUE_PASS(fpm) 
#endif

gb_internal bool lb_opt_ignore(i32 optimization_level) {
	optimization_level = gb_clamp(optimization_level, -1, 2);
	return optimization_level == -1;
}

gb_internal void lb_basic_populate_function_pass_manager(LLVMPassManagerRef fpm, i32 optimization_level) {
	if (lb_opt_ignore(optimization_level)) {
		return;
	}

	if (false && optimization_level <= 0 && build_context.ODIN_DEBUG) {
		LLVMAddMergedLoadStoreMotionPass(fpm);
	} else {
		LLVMAddPromoteMemoryToRegisterPass(fpm);
		LLVMAddMergedLoadStoreMotionPass(fpm);
		LLVM_ADD_CONSTANT_VALUE_PASS(fpm);
		if (!build_context.ODIN_DEBUG) {
			LLVMAddEarlyCSEPass(fpm);
		}
	}
}

gb_internal void lb_populate_function_pass_manager(lbModule *m, LLVMPassManagerRef fpm, bool ignore_memcpy_pass, i32 optimization_level) {
	if (lb_opt_ignore(optimization_level)) {
		return;
	}

	if (ignore_memcpy_pass) {
		lb_basic_populate_function_pass_manager(fpm, optimization_level);
		return;
	} else if (optimization_level <= 0) {
		LLVMAddMemCpyOptPass(fpm);
		lb_basic_populate_function_pass_manager(fpm, optimization_level);
		return;
	}

#if 0
	LLVMPassManagerBuilderRef pmb = LLVMPassManagerBuilderCreate();
	LLVMPassManagerBuilderSetOptLevel(pmb, optimization_level);
	LLVMPassManagerBuilderSetSizeLevel(pmb, optimization_level);
	LLVMPassManagerBuilderPopulateFunctionPassManager(pmb, fpm);
#else
	LLVMAddMemCpyOptPass(fpm);
	lb_basic_populate_function_pass_manager(fpm, optimization_level);

	LLVMAddSCCPPass(fpm);

	LLVMAddPromoteMemoryToRegisterPass(fpm);
	LLVMAddUnifyFunctionExitNodesPass(fpm);

	LLVMAddCFGSimplificationPass(fpm);
	LLVMAddEarlyCSEPass(fpm);
	LLVMAddLowerExpectIntrinsicPass(fpm);
#endif
}

gb_internal void lb_populate_function_pass_manager_specific(lbModule *m, LLVMPassManagerRef fpm, i32 optimization_level) {
	if (lb_opt_ignore(optimization_level)) {
		return;
	}

	if (optimization_level <= 0) {
		LLVMAddMemCpyOptPass(fpm);
		lb_basic_populate_function_pass_manager(fpm, optimization_level);
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
	LLVM_ADD_CONSTANT_VALUE_PASS(fpm);
	LLVMAddEarlyCSEPass(fpm);

	LLVM_ADD_CONSTANT_VALUE_PASS(fpm);
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

gb_internal void lb_add_function_simplifcation_passes(LLVMPassManagerRef mpm, i32 optimization_level) {
	LLVMAddCFGSimplificationPass(mpm);

	LLVMAddJumpThreadingPass(mpm);

	LLVMAddSimplifyLibCallsPass(mpm);

	LLVMAddTailCallEliminationPass(mpm);
	LLVMAddCFGSimplificationPass(mpm);
	LLVMAddReassociatePass(mpm);

	LLVMAddLoopRotatePass(mpm);
	LLVMAddLICMPass(mpm);
	LLVMAddLoopUnswitchPass(mpm);

	LLVMAddCFGSimplificationPass(mpm);
	LLVMAddLoopIdiomPass(mpm);
	LLVMAddLoopDeletionPass(mpm);

	LLVMAddMergedLoadStoreMotionPass(mpm);

	LLVMAddMemCpyOptPass(mpm);
	LLVMAddSCCPPass(mpm);

	LLVMAddBitTrackingDCEPass(mpm);

	LLVMAddJumpThreadingPass(mpm);
	LLVM_ADD_CONSTANT_VALUE_PASS(mpm);
	LLVMAddLICMPass(mpm);

	LLVMAddLoopRerollPass(mpm);
	LLVMAddAggressiveDCEPass(mpm);
	LLVMAddCFGSimplificationPass(mpm);
}


gb_internal void lb_populate_module_pass_manager(LLVMTargetMachineRef target_machine, LLVMPassManagerRef mpm, i32 optimization_level) {

	// NOTE(bill): Treat -opt:3 as if it was -opt:2
	// TODO(bill): Determine which opt definitions should exist in the first place
	if (optimization_level <= 0 && build_context.ODIN_DEBUG) {
		return;
	}

	LLVMAddAlwaysInlinerPass(mpm);
	LLVMAddStripDeadPrototypesPass(mpm);
	LLVMAddAnalysisPasses(target_machine, mpm);
	LLVMAddPruneEHPass(mpm);
	if (optimization_level <= 0) {
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

	LLVMAddCFGSimplificationPass(mpm);

	LLVMAddPruneEHPass(mpm);
	if (optimization_level < 2) {
		return;
	}

	LLVMAddFunctionInliningPass(mpm);
	
	
	lb_add_function_simplifcation_passes(mpm, optimization_level);
		
	LLVMAddGlobalDCEPass(mpm);
	LLVMAddGlobalOptimizerPass(mpm);
	

	LLVMAddLoopRotatePass(mpm);

	LLVMAddLoopVectorizePass(mpm);
	
	if (optimization_level >= 2) {
		LLVMAddEarlyCSEPass(mpm);
		LLVM_ADD_CONSTANT_VALUE_PASS(mpm);
		LLVMAddLICMPass(mpm);
		LLVMAddLoopUnswitchPass(mpm);
		LLVMAddCFGSimplificationPass(mpm);
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



/**************************************************************************
	IMPORTANT NOTE(bill, 2021-11-06): Custom Passes
	
	The procedures below are custom written passes to aid in the 
	optimization of Odin programs	
**************************************************************************/

gb_internal void lb_run_remove_dead_instruction_pass(lbProcedure *p) {
	unsigned debug_declare_id = LLVMLookupIntrinsicID("llvm.dbg.declare", 16);
	GB_ASSERT(debug_declare_id != 0);

	isize removal_count = 0;
	isize pass_count = 0;
	isize const max_pass_count = 10;
	isize original_instruction_count = 0;
	// Custom remove dead instruction pass
	for (; pass_count < max_pass_count; pass_count++) {
		bool was_dead_instructions = false;

		// NOTE(bill): Iterate backwards
		// reduces the number of passes as things later on will depend on things previously
		for (LLVMBasicBlockRef block = LLVMGetLastBasicBlock(p->value);
		     block != nullptr;
		     block = LLVMGetPreviousBasicBlock(block)) {
			// NOTE(bill): Iterate backwards
			// reduces the number of passes as things later on will depend on things previously
			for (LLVMValueRef instr = LLVMGetLastInstruction(block);
			     instr != nullptr;
			     /**/)  {
			     	if (pass_count == 0) {
			     		original_instruction_count += 1;
			     	}

				LLVMValueRef curr_instr = instr;
				instr = LLVMGetPreviousInstruction(instr);

				LLVMUseRef first_use = LLVMGetFirstUse(curr_instr);
				if (first_use != nullptr)  {
					continue;
				}
				if (LLVMTypeOf(curr_instr) == nullptr) {
					continue;
				}

				// NOTE(bill): Explicit instructions are set here because some instructions could have side effects
				switch (LLVMGetInstructionOpcode(curr_instr)) {
				// case LLVMAlloca:

				case LLVMFNeg:
				case LLVMAdd:
				case LLVMFAdd:
				case LLVMSub:
				case LLVMFSub:
				case LLVMMul:
				case LLVMFMul:
				case LLVMUDiv:
				case LLVMSDiv:
				case LLVMFDiv:
				case LLVMURem:
				case LLVMSRem:
				case LLVMFRem:
				case LLVMShl:
				case LLVMLShr:
				case LLVMAShr:
				case LLVMAnd:
				case LLVMOr:
				case LLVMXor:
				case LLVMLoad:
				case LLVMGetElementPtr:
				case LLVMTrunc:
				case LLVMZExt:
				case LLVMSExt:
				case LLVMFPToUI:
				case LLVMFPToSI:
				case LLVMUIToFP:
				case LLVMSIToFP:
				case LLVMFPTrunc:
				case LLVMFPExt:
				case LLVMPtrToInt:
				case LLVMIntToPtr:
				case LLVMBitCast:
				case LLVMAddrSpaceCast:
				case LLVMICmp:
				case LLVMFCmp:
				case LLVMSelect:
				case LLVMExtractElement:
				case LLVMShuffleVector:
				case LLVMExtractValue:
					removal_count += 1;
					LLVMInstructionEraseFromParent(curr_instr);
					was_dead_instructions = true;
					break;
				}
			}
		}

		if (!was_dead_instructions) {
			break;
		}
	}
}


gb_internal void lb_run_function_pass_manager(LLVMPassManagerRef fpm, lbProcedure *p) {
	if (p == nullptr) {
		return;
	}
	LLVMRunFunctionPassManager(fpm, p->value);
	// NOTE(bill): LLVMAddDCEPass doesn't seem to be exported in the official DLL's for LLVM
	// which means we cannot rely upon it
	// This is also useful for read the .ll for debug purposes because a lot of instructions
	// are not removed
	lb_run_remove_dead_instruction_pass(p);
}

gb_internal void llvm_delete_function(LLVMValueRef func) {
	// for (LLVMBasicBlockRef block = LLVMGetFirstBasicBlock(func); block != nullptr; /**/) {
	// 	LLVMBasicBlockRef curr_block = block;
	// 	block = LLVMGetNextBasicBlock(block);
	// 	for (LLVMValueRef instr = LLVMGetFirstInstruction(curr_block); instr != nullptr; /**/) {
	// 		LLVMValueRef curr_instr = instr;
	// 		instr = LLVMGetNextInstruction(instr);
			
	// 		LLVMInstructionEraseFromParent(curr_instr);
	// 	}
	// 	LLVMRemoveBasicBlockFromParent(curr_block);
	// }
	LLVMDeleteFunction(func);
}

gb_internal void lb_append_to_compiler_used(lbModule *m, LLVMValueRef func) {
	LLVMValueRef global = LLVMGetNamedGlobal(m->mod, "llvm.compiler.used");

	LLVMValueRef *constants;
	int operands = 1;

	if (global != NULL) {
		GB_ASSERT(LLVMIsAGlobalVariable(global));
		LLVMValueRef initializer = LLVMGetInitializer(global);

		GB_ASSERT(LLVMIsAConstantArray(initializer));
		operands = LLVMGetNumOperands(initializer) + 1;
		constants = gb_alloc_array(temporary_allocator(), LLVMValueRef, operands);

		for (int i = 0; i < operands - 1; i++) {
			LLVMValueRef operand = LLVMGetOperand(initializer, i);
			GB_ASSERT(LLVMIsAConstant(operand));
			constants[i] = operand;
		}

		LLVMDeleteGlobal(global);
	} else {
		constants = gb_alloc_array(temporary_allocator(), LLVMValueRef, 1);
	}

	LLVMTypeRef Int8PtrTy = LLVMPointerType(LLVMInt8TypeInContext(m->ctx), 0);
	LLVMTypeRef ATy = LLVMArrayType(Int8PtrTy, operands);

	constants[operands - 1] = LLVMConstBitCast(func, Int8PtrTy);
	LLVMValueRef initializer = LLVMConstArray(Int8PtrTy, constants, operands);

	global = LLVMAddGlobal(m->mod, ATy, "llvm.compiler.used");
	LLVMSetLinkage(global, LLVMAppendingLinkage);
	LLVMSetSection(global, "llvm.metadata");
	LLVMSetInitializer(global, initializer);
}

gb_internal void lb_run_remove_unused_function_pass(lbModule *m) {
	isize removal_count = 0;
	isize pass_count = 0;
	isize const max_pass_count = 10;
	// Custom remove dead function pass
	for (; pass_count < max_pass_count; pass_count++) {
		bool was_dead = false;	
		for (LLVMValueRef func = LLVMGetFirstFunction(m->mod);
		     func != nullptr;
		     /**/
		     ) {
		     	LLVMValueRef curr_func = func;
		     	func = LLVMGetNextFunction(func);
		     	
			LLVMUseRef first_use = LLVMGetFirstUse(curr_func);
			if (first_use != nullptr)  {
				continue;
			}
			String name = {};
			name.text = cast(u8 *)LLVMGetValueName2(curr_func, cast(size_t *)&name.len);
						
			if (LLVMIsDeclaration(curr_func)) {
				// Ignore for the time being
				continue;
			}
			LLVMLinkage linkage = LLVMGetLinkage(curr_func);
			if (linkage != LLVMInternalLinkage) {
				continue;
			}
			
			Entity **found = map_get(&m->procedure_values, curr_func);
			if (found && *found) {
				Entity *e = *found;
				bool is_required = (e->flags & EntityFlag_Require) == EntityFlag_Require;
				if (is_required) {
					lb_append_to_compiler_used(m, curr_func);
					continue;
				}
			}
			
			llvm_delete_function(curr_func);
			was_dead = true;
			removal_count += 1;
		}
		if (!was_dead) {
			break;
		}
	}
}


gb_internal void lb_run_remove_unused_globals_pass(lbModule *m) {
	isize removal_count = 0;
	isize pass_count = 0;
	isize const max_pass_count = 10;
	// Custom remove dead function pass
	for (; pass_count < max_pass_count; pass_count++) {
		bool was_dead = false;	
		for (LLVMValueRef global = LLVMGetFirstGlobal(m->mod);
		     global != nullptr;
		     /**/
		     ) {
		     	LLVMValueRef curr_global = global;
		     	global = LLVMGetNextGlobal(global);
		     	
			LLVMUseRef first_use = LLVMGetFirstUse(curr_global);
			if (first_use != nullptr)  {
				continue;
			}
			String name = {};
			name.text = cast(u8 *)LLVMGetValueName2(curr_global, cast(size_t *)&name.len);
						
			LLVMLinkage linkage = LLVMGetLinkage(curr_global);
			if (linkage != LLVMInternalLinkage) {
				continue;
			}
			
			Entity **found = map_get(&m->procedure_values, curr_global);
			if (found && *found) {
				Entity *e = *found;
				bool is_required = (e->flags & EntityFlag_Require) == EntityFlag_Require;
				if (is_required) {
					continue;
				}
			}

			LLVMDeleteGlobal(curr_global);
			was_dead = true;
			removal_count += 1;
		}
		if (!was_dead) {
			break;
		}
	}
}
