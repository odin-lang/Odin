# Featuregen

This directory contains a python and CPP script that generates the needed information
for features regarding microarchitecture and target features of the compiler.

It is not pretty! But LLVM has no way to query this information with their C API.

It generates these globals (intended for `src/build_settings_microarch.cpp`:

- `target_microarch_list`: an array of strings indexed by the architecture, each string is a comma-seperated list of microarchitectures available on that architecture
- `target_features_list`: an array of strings indexed by the architecture, each string is a comma-seperated list of target features available on that architecture
- `target_microarch_counts`: an array of ints indexed by the architecture, each int represents the amount of microarchitectures available on that target, intended for easier iteration of the next global
- `microarch_features_list`: an array of a tuple like struct where the first string is a microarchitecture and the second is a comma-seperated list of all features that are enabled by default for it

In order to get the default features for a microarchitecture there is a small CPP program that takes
a target triple and microarchitecture and spits out the default features, this is then parsed by the python script.

This should be ran each time we update LLVM to stay in sync.

If there are minor differences (like the Odin user using LLVM 14 and this table being generated on LLVM 17) it
does not impact much at all, the only thing it will do is make LLVM print a message that the feature is ignored (if it was added between 14 and 17 in this case).

## Usage

1. Make sure the table of architectures at the top of the python script is up-to-date (the triple can be any valid triple for the architecture)
1. `./build_featuregen.sh`
1. `python3 featuregen.py`
1. Copy the output into `src/build_settings.cpp`
