#include <llvm/MC/MCSubtargetInfo.h>
#include <llvm/MC/TargetRegistry.h>
#include <llvm/Support/raw_ostream.h>
#include <llvm/ADT/ArrayRef.h>
#include <llvm/Support/InitLLVM.h>
#include <llvm/Support/TargetSelect.h>

// Dumps the default set of supported features for the given microarch.
int main(int argc, char **argv) {
	if (argc < 3) {
		llvm::errs() << "Error: first arg should be triple, second should be microarch\n";
		return 1;
	}

	llvm::InitializeAllTargets();
	llvm::InitializeAllTargetMCs();

	std::string error;
	const llvm::Target* target = llvm::TargetRegistry::lookupTarget(argv[1], error);

	if (!target) {
		llvm::errs() << "Error: " << error << "\n";
		return 1;
	}

	auto STI = target->createMCSubtargetInfo(argv[1], argv[2], "");

	std::string plus = "+";
	llvm::ArrayRef<llvm::SubtargetFeatureKV> features = STI->getAllProcessorFeatures();
	for (const auto& feature : features) {
		if (STI->checkFeatures(plus + feature.Key)) {
			llvm::outs() << feature.Key << "\n";
		}
	}

	return 0;
}
